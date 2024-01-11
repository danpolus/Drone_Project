%
clear all; close all;

addpath('..\..\..\DOC');
addpath(genpath('..\..\..\nft'));

project_params = augmentation_params();

augment_csp_source_data = true;
band_power_normalization_flg = true; %good for band without low frequencies
eeg_clean_flg = false;
plot_flg = false;

if augment_csp_source_data
    project_params.nftfit.freqBandHz = project_params.sourceFreqBandHz;
    in_fn = [project_params.in_fn_prefix 'source_data.mat'];
    out_fn = [project_params.out_fn_prefix project_params.in_fn_prefix 'augmented_source_data.mat'];
else
    orig_grid_edge = project_params.nftsim.grid_edge;
    in_fn = [project_params.in_fn_prefix 'train_data.mat'];
    out_fn = [project_params.out_fn_prefix project_params.in_fn_prefix 'augmented_train_data.mat'];
end
project_params.nftsim.grid_edge = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% [in_fn, in_fp] = uigetfile([project_params.data_fp '\*.mat'], 'select trainig data');
in_fp = [];
in_dir = uigetdir(project_params.data_fp, 'select trainig data folder');
% in_dir = 'C:\My Files\Work\BGU\Datasets\drone BCI\2a';
fp = [in_dir '\'];
if isfile([fp in_fn])
    in_fp = {fp};
else
    in_dir_t = dir(in_dir);
    for iDir = 3:length(in_dir_t)
        fp = [in_dir_t(iDir).folder '\' in_dir_t(iDir).name '\'];
        if in_dir_t(iDir).isdir && isfile([fp in_fn])
            in_fp = [in_fp {fp}];
        end
    end
end

% poolobj = gcp; %parpool
datetime(now,'ConvertFrom','datenum');

for iFolder = 1:length(in_fp)

    load([in_fp{iFolder} in_fn]);
    if augment_csp_source_data
        Trials_t = Sources_t;
        clear("Sources_t");
    elseif isstruct(Trials_t)
        Trials_t = {Trials_t, Trials_t};
    else
        Trials_t = [Trials_t, Trials_t];
    end
    for iFold = 1:length(Trials_t)-1 %last fold is the full set

        if augment_csp_source_data
            train_data.trials = permute(Trials_t{iFold}.train_source_data, [2,3,1]);
        else
            train_data.trials = permute(Trials_t{iFold}.train_trials, [3,2,1]);
        end
        train_data.labels = Trials_t{iFold}.train_labels;
        train_data.pred_labels = Trials_t{iFold}.train_pred_labels;
        train_data.augmented_trials = [];
        train_data.augmented_labels = [];

        if project_params.augmentation.augment_correct_trial_only_flg && ~isempty(train_data.pred_labels)
            train_data.trials = train_data.trials(:,:,train_data.labels == train_data.pred_labels);
            train_data.labels = train_data.labels(train_data.labels == train_data.pred_labels);
        end

        uniqueLabels = unique(train_data.labels);
        [labelCounts,~] = histcounts(train_data.labels,[uniqueLabels-0.5 uniqueLabels(end)+0.5]);
        for iLabel = 1:length(uniqueLabels) %group data by labels

            EEG = EEGLABformat(train_data, in_fn, in_fp{iFolder}, uniqueLabels(iLabel), project_params, eeg_clean_flg, plot_flg);

            %for normalization
            chanAVs = mean(EEG.data,[2 3]);
            if band_power_normalization_flg
                chanPower = bandpower(eeg2epoch(EEG).data' ,EEG.srate, project_params.nftfit.freqBandHz)';
            else
                EEG_filtered = pop_eegfiltnew(EEG, project_params.pipelineParams.passBandHz{1}, project_params.pipelineParams.passBandHz{2});
                chanSTDs = std(EEG_filtered.data,0,[2 3]);
            end

            trial_len_sec = EEG.pnts/EEG.srate;
            project_params.psd.window_sec = trial_len_sec;
            n_aug_trials = round(project_params.augmentation.factor*max(labelCounts) + max(labelCounts)-labelCounts(iLabel));

            if project_params.augmentation.just_guasian_noise_flg
                EEGaug = EEG;
                EEGaug.data = repmat(EEGaug.data, [1, 1, ceil(n_aug_trials/EEG.trials)]);
                EEGaug.data = EEGaug.data(:,:,1:n_aug_trials); 
                EEGaug.trials = n_aug_trials;
                EEGaug.data = EEGaug.data(:,:,randperm(EEGaug.trials));
                EEGaug = eeg_checkset(eeg2epoch(EEGaug));
                white_noise = randn(size(EEGaug.data)).*std(EEGaug.data,0,2)*project_params.augmentation.variation_factor;
%                 white_noise = (white_noise' * chol(cov(EEGaug.data'), 'lower')')'; % add correlated noise: Cholesky decomposition of the covariance matrix
                EEGaug.data = double(EEGaug.data + white_noise);

            else
                EEGaug = [];
                for iChan=1:EEG.nbchan %augment each channel separately
                    %fit
                    [NFTparams, Spectra] = fit_nft(eeg2epoch(EEG), project_params, iChan, 0);
%                     inspect_trials_fit(EEG, project_params, iLabel, iChan); %debug

                    %simulate
                    if iChan == 1
                        if augment_csp_source_data
                            EEGaug.data = [];
                            EEGaug.chanlocs = EEG.chanlocs;
                        else
                            project_params.nftsim.grid_edge = orig_grid_edge;
                            [EEGaug, ~, ~, ~] = simulate_nft(NFTparams, Spectra, project_params, iChan, 0);
                            EEGaug.xmax = n_aug_trials*trial_len_sec;
                            EEGaug.pnts = EEGaug.xmax*project_params.fs;
                            EEGaug.times = (EEGaug.xmin:EEGaug.xmin:EEGaug.xmax)*1000;
                            EEGaug.data = zeros(EEGaug.nbchan, EEGaug.pnts);
                            EEGaug.bad_channels = [];
                            project_params.nftsim.grid_edge = 1;
                        end
                    end

                    %augment
%                     NFTparams.t0(:) = 0.079; %for plotting
                    [central_chan_data, isSimSuccess] = variate_augmentation(NFTparams, Spectra, project_params, iChan, n_aug_trials, trial_len_sec);
                    %normalize
                    if band_power_normalization_flg
                        central_chan_data = (central_chan_data - mean(central_chan_data)) * ...
                            sqrt(chanPower(iChan) / bandpower(central_chan_data, project_params.fs, project_params.nftfit.freqBandHz))...
                            + chanAVs(iChan);
                    else
                        central_chan_data = zscore(central_chan_data) * chanSTDs(iChan) + chanAVs(iChan);
                    end
                    %place in EEGaug
                    if isSimSuccess
                        EEGaug.data(strcmp({EEGaug.chanlocs.labels},EEG.chanlocs(iChan).labels), :) = central_chan_data;
                    else
                        if augment_csp_source_data
                            error('Augmentation Failure!');
                        end
                        EEGaug.bad_channels = [EEGaug.bad_channels {EEG.chanlocs(iChan).labels}];
                    end

                    if plot_flg
                        [P, f] = compute_psd(project_params.nftfit.psdMethod, central_chan_data, EEG.srate, project_params.psd.window_sec, ...
                            project_params.psd.overlap_percent, project_params.nftfit.freqBandHz, false);

                        figure; 
                        P_fit = Spectra.P_fit(Spectra.f_fit>=Spectra.f(1)-3 & Spectra.f_fit<=Spectra.f(end)+3);
                        f_fit = Spectra.f_fit(Spectra.f_fit>=Spectra.f(1)-3 & Spectra.f_fit<=Spectra.f(end)+3);
                        semilogy(Spectra.f,Spectra.P, f_fit,abs(P_fit),'--', f,P, 'linewidth',project_params.grapics.linewidth);
%                         hold on
%                         semilogy(f,P, '-.', 'linewidth',project_params.grapics.linewidth-0.5);
%                         hold off

                        ax = gca;
                        ax.XGrid = "on"; ax.YGrid = "on"; ax.GridColor = project_params.grapics.GridColor; ax.GridAlpha = project_params.grapics.GridAlpha;
                        ax.XMinorGrid = "on"; ax.YMinorGrid = "on"; ax.MinorGridColor = project_params.grapics.GridColor; ax.MinorGridAlpha = project_params.grapics.GridAlpha;
                        ax.Box = "off";
                        ax.ColorOrder = linspecer(5);
                        ax.FontSize = project_params.grapics.axisLabelFntSz;
                        xlabel('Hz', 'FontSize',project_params.grapics.axisLabelFntSz); ylabel('V^2', 'FontSize',project_params.grapics.axisLabelFntSz); 
                        % title('t_0 Parameter Variation Spectra', 'FontSize',project_params.grapics.titleFntSz);
%                         legend({' experimental',' fitted',' simulated'}, 'FontSize',project_params.grapics.axisLabelFntSz);
                        legend({' experimental',' fitted',' simulated t_0=0.085',' simulated t_0=0.079',' simulated t_0=0.095'}, 'FontSize',project_params.grapics.axisLabelFntSz);
%                         legend({' experimental',' fitted',' simulated \gamma=116',' simulated \gamma=70',' simulated \gamma=150'}, 'FontSize',project_params.grapics.axisLabelFntSz);
%                         legend({' experimental',' fitted',' simulated \alpha=83',' simulated \alpha=60',' simulated \alpha=120'}, 'FontSize',project_params.grapics.axisLabelFntSz);
                    end
                end
            end

            %interpolate bad channels
            if ~augment_csp_source_data
                EEGaug = pop_select(EEGaug, 'nochannel',EEGaug.bad_channels);
                EEGaug = eeg_interp(EEGaug, readlocs(project_params.electrodes_fn));
            end
            
%             % if we apply laplacian on the original data, perhaps apply laplacian on the simulated data. 
%             % anyhow, play with fit/simulate spatial filtering
%             if project_params.isMEG_flg
%                 [G,H] = GetGH(ExtractMontage({EEGaug.chanlocs.labels}',[EEGaug.chanlocs.sph_theta]',[EEGaug.chanlocs.sph_phi]',{EEGaug.chanlocs.labels}'));
%                 EEGaug.data = CSD(single(EEGaug.data),G,H);
%             end

            %plot augmented data
            if plot_flg
                if augment_csp_source_data
                    EEGplot = EEG;  EEGplot.data = EEGaug.data;  EEGplot = eeg_checkset(EEGplot);
                    pop_eegplot(EEGplot, 1, 0, 0, [], 'srate',EEGplot.srate, 'winlength',6, 'eloc_file',[]);
                else
                    EEGplot = pop_select(EEGaug, 'nochannel', project_params.NON_EEG_ELECTRODES);
                    pop_eegplot(pop_eegfiltnew(EEGplot, 0.1, []), 1, 0, 0, [], 'srate',EEGaug.srate, 'winlength',6, 'eloc_file',[]);
                end
                figure; pop_spectopo(EEGplot, 1, [], 'EEG', 'freqrange',[0 EEGplot.srate/2], 'percent',100, 'electrodes','off');
                channel_map_topoplot(eeg2epoch(EEGplot), [], false);
            end

            %concatenate augmented data
            augData = reshape(EEGaug.data,[size(EEGaug.data,1),EEG.pnts,n_aug_trials]);
            augLabels = uniqueLabels(iLabel)*int32(ones(1,n_aug_trials));
            train_data.augmented_trials = cat(3,train_data.augmented_trials, augData);
            train_data.augmented_labels = cat(2,train_data.augmented_labels, augLabels);

        end

        if augment_csp_source_data
            Trials_t{iFold}.aug_source_data = permute(train_data.augmented_trials, [3,1,2]);
        else
            Trials_t{iFold}.aug_trials = permute(train_data.augmented_trials, [3,2,1]);
        end
        Trials_t{iFold}.aug_labels = train_data.augmented_labels;

    end

    if augment_csp_source_data
        Sources_t = Trials_t;
        save([in_fp{iFolder} out_fn],'Sources_t');
    else
        save([in_fp{iFolder} out_fn],'Trials_t');
    end

end

disp(project_params.out_fn_prefix);
datetime(now,'ConvertFrom','datenum');
% delete(poolobj);
