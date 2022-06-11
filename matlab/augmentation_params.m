%doc nft analysis parameters
function project_params = augmentation_params()

project_params.code_fp = '..\..\..';
project_params.data_fp = 'C:\My Files\Work\BGU\Datasets\drone BCI';
project_params.electrodes_fn = [project_params.data_fp '\electrodes\Standard-10-20-Cap19.ced'];
project_params.NON_EEG_ELECTRODES = {'A1','A2','X1','X2','X3','TRG','Pz_CM'};
project_params.head_radius = 1; %used to get rid of out-of-scalp channels
project_params.fs = 300;
project_params.minSectLenSec = 10; 

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
project_params.psd.window_sec = 2;
project_params.psd.overlap_percent = 0;

%%%NFT fit
% project_params.nftfit.params2fit = {'Gee','Gei','Ges','Gse','Gsr','Gre','Grs','Alpha','Beta','t0', 'EMGa'};
project_params.nftfit.params2fit = {}; %use typical
project_params.nftfit.spatial_fit_flg = false;
project_params.nftfit.psdMethod = 'fft';
project_params.nftfit.freqBandHz = [2 40]; %maybe narrow, to avoid poor fitting 
project_params.nftfit.npoints = 2e4;
project_params.nftfit.chisqThrsh = 7; %for spatial fit warning

%%%%NFT simulation
project_params.nftsim.grid_edge = 12; % pi/4*(grid_edge/2)^2 >= number of experimental electrode inside head radius
% delta_t = 2^(-ceil(log2(project_params.fs))); 
% project_params.nftsim.fs = 1/delta_t; %512
% project_params.nftsim.out_dt = delta_t;
project_params.nftsim.fs = project_params.fs*2;
project_params.nftsim.out_dt = 1/project_params.fs;

%%%%Augmentation
project_params.augmentation.augment_correct_trial_only_flg = false;
project_params.augmentation.factor = 15;
% project_params.augmentation.n_variations = 1; %set to 1 to avoid random variations
project_params.augmentation.n_variations = 1*project_params.augmentation.factor;
% project_params.augmentation.params2vary = {'alpha',[10 150];  'beta',[200 800];  't0',[0.075 0.24];  'phin',[0.5e-5 1.5e-5]}; %param name and limits. varying nus&phia - may cause biforcations
project_params.augmentation.params2vary = {'alpha',[10 150];  'beta',[200 800]};
project_params.augmentation.variation_factor = 0.1;
