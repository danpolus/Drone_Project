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
    in_fn = 'source_data.mat';
    out_fn = 'augmented_source_data.mat';
else
    orig_grid_edge = project_params.nftsim.grid_edge;
    in_fn = 'train_data.mat';
    out_fn = 'augmented_train_data.mat';
end
project_params.nftsim.grid_edge = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% [in_fn, in_fp] = uigetfile([project_params.data_fp '\*.mat'], 'select trainig data');
in_fp = [];
in_dir = uigetdir(project_params.data_fp, 'select trainig data folder');
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

    train_data = load([in_fp{iFolder} in_fn]);
    train_data_trials = train_data.trials;
    train_data_labels = train_data.labels;
    augmented_data_trials = [];
    augmented_data_labels = [];

    if project_params.augmentation.augment_correct_trial_only_flg && isfield(train_data, 'pred_labels')
        train_data.trials = train_data.trials(train_data.labels == train_data.pred_labels,:,:);
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
            EEGaug.data = EEGaug.data(:,:,randperm(EEGaug.trials));
            EEGaug.data = repmat(EEGaug.data, [1, 1, ceil(n_aug_trials/EEG.trials)]);
            EEGaug.data = EEGaug.data(:,:,1:n_aug_trials); EEGaug.trials = n_aug_trials;
            EEGaug = eeg_checkset(eeg2epoch(EEGaug));
            EEGaug.data = double(EEGaug.data + randn(size(EEGaug.data)).*std(EEGaug.data,0,2)*project_params.augmentation.variation_factor);

        else
            EEGaug = [];
            for iChan=1:EEG.nbchan %augment each channel separately
                %fit
                [NFTparams, Spectra] = fit_nft(eeg2epoch(EEG), project_params, iChan, 0);

                %simulate
                if iChan == 1
                    if augment_csp_source_data
                        EEGaug.data = [];
                        EEGaug.chanlocs = EEG.chanlocs;
                    else
                        project_params.nftsim.grid_edge = orig_grid_edge;
                        [EEGaug, ~, ~, ~] = simulate_nft(NFTparams, Spectra, project_params, iChan, 0);
                        EEGaug.data = EEGaug.data*0;
                        EEGaug.bad_channels = [];
                        project_params.nftsim.grid_edge = 1;
                    end
                end

                %augment
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
                    figure; semilogy(Spectra.f,Spectra.P, Spectra.f_fit,abs(Spectra.P_fit), f,P);
                    xlabel('Hz');legend('experimental','fitted','simulated');
                end
            end
        end

        %interpolate bad channels
        if ~augment_csp_source_data
            EEGaug = pop_select(EEGaug, 'nochannel',EEGaug.bad_channels);
            EEGaug = eeg_interp(EEGaug, readlocs(project_params.electrodes_fn));
        end

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
        augData = permute(augData, [3,2,1]);
        augLabels = uniqueLabels(iLabel)*int32(ones(1,n_aug_trials));
        augmented_data_trials = cat(1,augmented_data_trials, augData);
        augmented_data_labels = cat(2,augmented_data_labels, augLabels);

    end

    save([in_fp{iFolder} project_params.out_fn_prefix out_fn],'train_data_trials','train_data_labels','augmented_data_trials','augmented_data_labels');

end

datetime(now,'ConvertFrom','datenum');
% delete(poolobj);
