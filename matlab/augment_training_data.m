%
clear all; close all;

addpath('..\..\..\DOC');
addpath(genpath('..\..\..\nft'));

project_params = augmentation_params();

augment_csp_source_data = true;
eeg_clean_flg = false;
plot_flg = false;

if augment_csp_source_data
    project_params.nftfit.freqBandHz = [8 29];
    out_fn = 'augmented_source_data.mat';
else
    orig_grid_edge = project_params.nftsim.grid_edge;
    out_fn = 'augmented_train_data.mat';
end
project_params.nftsim.grid_edge = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[fn, in_fp] = uigetfile([project_params.data_fp '\*.mat'], 'select trainig data');
train_data = load([in_fp fn]);
train_data_trials = train_data.trials;
train_data_labels = train_data.labels;
augmented_data_trials = [];
augmented_data_labels = [];

% poolobj = gcp; %parpool
datetime(now,'ConvertFrom','datenum');

if project_params.augmentation.augment_correct_trial_only_flg && isfield(train_data, 'pred_labels')
    train_data.trials = train_data.trials(train_data.labels == train_data.pred_labels,:,:);
    train_data.labels = train_data.labels(train_data.labels == train_data.pred_labels);
end

uniqueLabels = unique(train_data.labels);
[labelCounts,~] = histcounts(train_data.labels,[uniqueLabels-0.5 uniqueLabels(end)+0.5]);
for iLabel = 1:length(uniqueLabels) %group data by labels

    EEG = EEGLABformat(train_data, fn, in_fp, uniqueLabels(iLabel), project_params, eeg_clean_flg, plot_flg);

    %for normalization
%     chanPower = bandpower(eeg2epoch(EEG).data' ,EEG.srate, project_params.nftfit.freqBandHz);
    chanAVs = mean(EEG.data,[2 3]);
    EEG_filtered = pop_eegfiltnew(EEG, project_params.pipelineParams.passBandHz{1}, project_params.pipelineParams.passBandHz{2});
    chanSTDs = std(EEG_filtered.data,0,[2 3]);

    trial_len_sec = EEG.pnts/EEG.srate;
    project_params.psd.window_sec = trial_len_sec;
    n_aug_trials = (project_params.augmentation.factor*max(labelCounts) + max(labelCounts)-labelCounts(iLabel));

    EEGaug = [];
    for iChan=1:EEG.nbchan %augment each channel separately
        %fit
        try
            [NFTparams, Spectra] = fit_nft(eeg2epoch(EEG), project_params, iChan, 0);
        catch
            error([fn ':  fit_nft error']);
        end
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
        central_chan_data = zscore(central_chan_data) * chanSTDs(iChan) + chanAVs(iChan);
%         central_chan_data = (central_chan_data - mean(central_chan_data)) * ...
%             sqrt(chanPower(iChan) / bandpower(central_chan_data, project_params.fs, project_params.nftfit.freqBandHz))...
%             + chanAVs(iChan);
        %place in EEGaug
        if isSimSuccess
            EEGaug.data(strcmp({EEGaug.chanlocs.labels},EEG.chanlocs(iChan).labels), :) = central_chan_data;
        else
            if augment_csp_source_data
                error('Augmentation Failure!');
            end
            EEGaug.bad_channels = [EEGaug.bad_channels {EEG.chanlocs(iChan).labels}];
        end        
    end
    
    %interpolate bad channels
    if ~augment_csp_source_data
        EEGaug = pop_select(EEGaug, 'nochannel',EEGaug.bad_channels);
        EEGaug = eeg_interp(EEGaug, readlocs(project_params.electrodes_fn));
    end
       
    %plot augmented data
    if plot_flg && ~augment_csp_source_data
        EEGplot = pop_select(EEGaug, 'nochannel', project_params.NON_EEG_ELECTRODES);
        EEGplot = pop_eegfiltnew(EEGplot, 0.1, []);
        pop_eegplot(EEGplot, 1, 0, 0, [], 'srate',EEGaug.srate, 'winlength',6, 'eloc_file',[]);
        figure; pop_spectopo(EEGaug, 1, [], 'EEG', 'freqrange',[0 EEGaug.srate/2], 'percent',10, 'electrodes','off');
        channel_map_topoplot(EEGaug, [], false);
    end

    %concatenate augmented data
    augData = reshape(EEGaug.data,[size(EEGaug.data,1),EEG.pnts,n_aug_trials]);
    augData = permute(augData, [3,2,1]);
    augLabels = uniqueLabels(iLabel)*int32(ones(1,n_aug_trials));
    augmented_data_trials = cat(1,augmented_data_trials, augData);
    augmented_data_labels = cat(2,augmented_data_labels, augLabels);

end
datetime(now,'ConvertFrom','datenum');
% delete(poolobj);

save([in_fp out_fn],'train_data_trials','train_data_labels','augmented_data_trials','augmented_data_labels');
