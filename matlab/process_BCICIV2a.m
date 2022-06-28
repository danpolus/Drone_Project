%
clear all; close all;

fp = 'C:\My Files\Work\BGU\Datasets\drone BCI\External state-of-the-art\BCI IV left right leg tongue 9subj\';
out_train_fn = 'train_data.mat';
out_test_fn = 'test_data.mat';

testset_percent = 0.3;

cue_events = {769, 770, 771, 772, 783};
artifact_event = 1023;

project_params = augmentation_params();

plot_flg = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[files, in_fp] = uigetfile([fp '*.gdf'], 'Select data files', 'MultiSelect','on');
if ~iscell(files) %in case only 1 file selected
    files = {files};
end
nFiles = length(files);

chanlocs = readlocs([fp 'Standard-10-20-Cap22.locs']);

for iFile = 1:nFiles

    EEG = pop_biosig([in_fp files{iFile}]);
    EEG.setname = files{iFile}(1:end-4);
    EEG.chanlocs = chanlocs;
    EEG = eeg_checkset(EEG);
    load([in_fp EEG.setname '.mat']); %true classlabel
    classlabel = classlabel';
    if plot_flg
        figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
        pop_eegplot(EEG, 1, 0, 0, [], 'srate',EEG.srate, 'winlength',60, 'eloc_file',[]);
    end

    %extract MI trials
    [EEG.event.type] = EEG.event.edftype;
    all_events = [EEG.event.type];
    EEG = pop_epoch(EEG, cue_events, [4-project_params.trial_len_sec  4], 'epochinfo','yes', 'newname',EEG.setname, 'verbose', 'no');
    label_events = [EEG.event.type];
%     if length(unique(label_events)) > 1 && ... %check if identical to classlabel
%         sum(classlabel ~= label_events - cue_events{1} + 1) > 1
%         error('true labels does not match!');
%     end
    if plot_flg
        pop_eegplot(EEG, 1, 0, 0, [], 'srate',EEG.srate, 'winlength',60, 'eloc_file',[]);
        figure; pop_spectopo(EEG, 1, [], 'EEG', 'freqrange',[0 EEG.srate/2], 'percent',10, 'electrodes','off');
    end    

    %reject artifacts
%     if any(all_events == 1072)
%         error('1072');
%     end
    cue_idx = find(ismember(all_events, cell2mat(cue_events)));
    artifact_idx = find(all_events == artifact_event);
    rej_trials = ismember(cue_idx,artifact_idx+1);
%     if length(artifact_idx) ~= sum(rej_trials)
%         error('1023');
%     end
    EEG = pop_rejepoch(EEG, rej_trials ,0);
    classlabel(rej_trials) = [];

    %split into train and test
    trials = []; test_trials = [];
    labels = []; test_labels = [];
    for Label = unique(classlabel)
        label_inx = find(classlabel == Label);
        nTrials = length(label_inx);
        label_inx = label_inx(randperm(nTrials));
        split_ind = round(nTrials*testset_percent);
        trials = cat(3,trials,EEG.data(:,:,label_inx(split_ind+1:end)));
        labels = cat(2,labels,ones(1,nTrials-split_ind)*Label);
        test_trials = cat(3,test_trials,EEG.data(:,:,label_inx(1:split_ind)));
        test_labels = cat(2,test_labels,ones(1,split_ind)*Label);
    end

    %save
    mkdir([in_fp EEG.setname]);
    trials = permute(trials, [3,2,1]);
    test_trials = permute(test_trials, [3,2,1]);
    save([in_fp EEG.setname '\' out_train_fn], 'trials','labels');
    save([in_fp EEG.setname '\' out_test_fn], 'test_trials','test_labels');

end
