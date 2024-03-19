%doc nft analysis parameters
function project_params = augmentation_params()

project_params.isMEG_flg = false; %different setup, no volume conduction

project_params.code_fp = '..\..\..';
project_params.data_fp = 'C:\My Files\Work\BGU\Datasets\drone BCI';

% project_params.electrodes_fn = [project_params.data_fp '\electrodes\Standard-10-20-Cap19.ced'];
% project_params.NON_EEG_ELECTRODES = {'A1','A2','X1','X2','X3','TRG','Pz_CM'};
% project_params.fs = 300;
% project_params.trial_len_sec = 2.5;
project_params.electrodes_fn = [project_params.data_fp '\External state-of-the-art\BCI IV left right leg tongue 9subj\Standard-10-20-Cap22.locs'];
project_params.NON_EEG_ELECTRODES = {'EOG-left', 'EOG-central', 'EOG-right'};
project_params.fs = 250;
project_params.trial_len_sec = 2.5;
project_params.sourceFreqBandHz = [8 30];

project_params.head_radius = 1; %used to get rid of out-of-scalp channels
project_params.minSectLenSec = 10; 

%%%%%publishing graphics
project_params.grapics.fontName = 'Arial';
project_params.grapics.sgtitleFntSz = 48;
project_params.grapics.titleFntSz = 44;
project_params.grapics.axisLabelFntSz = 40;
project_params.grapics.axisTickFntSz = 34;
project_params.grapics.textFntSz = 30;
project_params.grapics.linewidth = 4;
project_params.grapics.markerSz = 90;
project_params.grapics.GridColor = [0.5 0.5 0.5];
project_params.grapics.GridAlpha = 0.9;

%%%%eeglab pipelineParams
%filtering parameters:
pipelineParams.passBandHz = [{1}, {45}];
pipelineParams.notchHz = [];
pipelineParams.resampleFsHz = [];
%bad channels and bad epochs parameters:
pipelineParams.badchan_time_percent = 0.3;
pipelineParams.badchan_window_step_length_sec = 5;
pipelineParams.chan_z_score_thresh = 7;
pipelineParams.epoch_max_std_thresh = 2.5;
pipelineParams.epoch_min_std_thresh = 0.1;
pipelineParams.bad_chan_in_epoch_percent = 0.15;
%bad sections parameters:
pipelineParams.badsect_z_score_thresh = [];
pipelineParams.badsect_window_length_sec = 1;
pipelineParams.badsect_reject_score_thresh = 1;
%clean_artifacts parameters:
pipelineParams.max_badchannel_percent = pipelineParams.bad_chan_in_epoch_percent;
pipelineParams.minimal_interchannel_correlation = 0.6;
pipelineParams.channel_max_bad_time = pipelineParams.badchan_time_percent;
pipelineParams.asr_birst = 'off';
pipelineParams.window_criterion = max(1,pipelineParams.badsect_reject_score_thresh);
if isnumeric(pipelineParams.asr_birst)
    pipelineParams.badsect_z_score_thresh = pipelineParams.asr_birst+1;
end
%ica paremeters:
pipelineParams.ica_flg = false;
pipelineParams.minimal_nonbrain_class_prob = 0.5;
pipelineParams.tweaks_ics2rjct_fun = [];
%various paremeters:
pipelineParams.elecInterpolateFn = [];
pipelineParams.ref_electrodes = [];
project_params.pipelineParams = pipelineParams;

%%%PSD
project_params.psd.window_sec = project_params.trial_len_sec;
project_params.psd.overlap_percent = 0;

%%%NFT fit
% project_params.nftfit.params2fit = {'Gee','Gei','Ges','Gse','Gsr','Gre','Grs','Alpha','Beta','t0', 'EMGa'};
project_params.nftfit.params2fit = {}; %use typical
project_params.nftfit.spatial_fit_flg = false;
project_params.nftfit.psdMethod = 'fft';
project_params.nftfit.freqBandHz = [pipelineParams.passBandHz{1} pipelineParams.passBandHz{2}];
project_params.nftfit.weigths1f_flg = false;
project_params.nftfit.npoints = 2e3;
project_params.nftfit.chisqThrsh = 7; %for spatial fit warning

%%%%NFT simulation
project_params.nftsim.grid_edge = 12; % pi/4*(grid_edge/2)^2 >= number of experimental electrode inside head radius
% delta_t = 2^(-ceil(log2(project_params.fs))); 
% project_params.nftsim.fs = 1/delta_t; %512
% project_params.nftsim.out_dt = delta_t;
project_params.nftsim.fs = project_params.fs*2;
project_params.nftsim.out_dt = 1/project_params.fs;

%%%%Augmentation
project_params.augmentation.augment_correct_trial_only_flg = true;
project_params.augmentation.factor = 2;
project_params.augmentation.just_guasian_noise_flg = false;
% project_params.augmentation.params2vary = {'alpha',[10 150],14; 'gammae',[40 280],25; 't0',[0.04 0.24],0.003}; %param name, limits, standard deviation
project_params.augmentation.params2vary = {'alpha',[10 150],14};
project_params.augmentation.n_variations = 1; %set to 1 to avoid random variations
% project_params.augmentation.n_variations = size(project_params.augmentation.params2vary,1)*project_params.augmentation.factor*10;
project_params.augmentation.variation_factor = 0.5;

%%%%NFT stim
project_params.stim.area = 'None'; % 'Cortical' 'Reticular' 'S_Relay' 'None'
project_params.stim.dendrites = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%setups:
project_params.in_fn_prefix = 'Small33cls2CSPBandPower_';
varfac = [num2str(floor(project_params.augmentation.variation_factor)) num2str(100*rem(project_params.augmentation.variation_factor,1))];
project_params.out_fn_prefix = ['x' num2str(project_params.augmentation.factor)];
if project_params.augmentation.just_guasian_noise_flg
    project_params.out_fn_prefix = [project_params.out_fn_prefix 'WhiteNoise' varfac];
else
    if isempty(project_params.nftfit.params2fit)
        project_params.out_fn_prefix = [project_params.out_fn_prefix 'TypFit'];
    else
        project_params.out_fn_prefix = [project_params.out_fn_prefix 'FullFit'];
    end
    if project_params.augmentation.n_variations>1
        for iParam = 1:size(project_params.augmentation.params2vary,1)
            project_params.out_fn_prefix = [project_params.out_fn_prefix project_params.augmentation.params2vary{iParam,1} varfac];
        end
    end
end
project_params.out_fn_prefix = [project_params.out_fn_prefix '_'];

%
%rsults:
% Full100cls2CSPBandPower_ train 0.670+-0.185, validation 0.498+-0.289
% Small33cls2CSPBandPower_ train 0.763+-0.133, validation 0.452+-0.287
% Noise33cls2CSPBandPower_ train 0.623+-0.138, validation 0.434+-0.287
% x1TypFit_Small33cls2CSPBandPower_ train 0.838+-0.094, validation 0.469+-0.296
% x2TypFit_Small33cls2CSPBandPower_ train 0.868+-0.078, validation 0.463+-0.302
% x2FullFit_Small33cls2CSPBandPower_ train 0.818+-0.080, validation 0.427+-0.294
% x2WhiteNoise050_Small33cls2CSPBandPower_ train 0.896+-0.061, validation 0.453+-0.290
% x2TypFitalpha050_Small33cls2CSPBandPower_ train 0.870+-0.053, validation 0.424+-0.279
% x2TypFitalpha050gammae050t0050_Small33cls2CSPBandPower_ train 0.383+-0.131, validation 0.062+-0.103
% x5TypFit_Small33cls2CSPBandPower_ train 0.919+-0.051, validation 0.460+-0.297

% Full100cls2CSPHiguchi_ train 0.581+-0.255, validation 0.456+-0.341
% Small33cls2CSPHiguchi_ train 0.641+-0.232, validation 0.428+-0.336

% Full100cls2ICARMS_ train 0.511+-0.305, validation 0.405+-0.364
% Small33cls2ICARMS_ train 0.581+-0.266, validation 0.374+-0.348
% x2TypFit_Small33cls2ICARMS_ train 0.823+-0.115, validation 0.366+-0.348
% x2FullFit_Small33cls2ICARMS_ train 0.801+-0.111, validation 0.325+-0.319
% AVERAGE ACCURACY:   train 0.452+-0.274, validation 0.374+-0.310, test -1.000+-0.000
% AVERAGE ACCURACY 16%:   train 0.565+-0.242, validation 0.294+-0.288, test -1.000+-0.000
% AVERAGE ACCURACY 16+84%: train 0.889+-0.052, validation 0.285+-0.294, test -1.000+-0.000

% Full100cls2ICAEntropy_ train 0.589+-0.257, validation 0.430+-0.328
% Small33cls2ICAEntropy_ train 0.702+-0.221, validation 0.368+-0.309
% x2TypFit_Small33cls2ICAEntropy_ train 0.859+-0.098, validation 0.353+-0.299
% AVERAGE ACCURACY:   train 0.495+-0.262, validation 0.365+-0.335, test -1.000+-0.000
% AVERAGE ACCURACY 16%:   train 0.754+-0.164, validation 0.249+-0.257, test -1.000+-0.000
% AVERAGE ACCURACY 16+84%: train 0.911+-0.048, validation 0.248+-0.279, test -1.000+-0.000
%
