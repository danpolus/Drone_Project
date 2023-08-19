
from enum import Enum
import numpy as np

class SessionType(Enum):
    Online = 0
    OnlineExpMI = 1
    OfflineExpSSVEP = 2
    OfflineExpMI = 3
    OfflineTrainCspMI = 4
    OfflineTrainLdaMI = 5
    TestAccuracy = 6

class DroneCommands(Enum):
    idle = 0
    up = 1
    down = 2
    forward = 3
    back = 4
    left = 5
    right = 6
    flip = 69
    stop = -1
    error = -2

def getParams():

        projParams = {'EegParams':{}, 'MiParams':{}, 'SsvepParams':{}, 'DroneParams':{}, 'RuntimeParams':{}, 'FilesParams':{}}

        # #WS
        # projParams['EegParams']['epoch_len_sec'] = 2.5
        # projParams['EegParams']['sfreq'] = 300
        # projParams['EegParams']['chan_names'] = ['P3','C3', 'F3', 'Fz', 'F4', 'C4', 'P4', 'Cz','CM', 'A1', 'Fp1', 'Fp2' , 'T3', 'T5', 'O1', 'O2', 'X3' , 'X2', 'F7', 'F8', 'X1', 'A2', 'T6', 'T4', 'TRG']
        # projParams['EegParams']['nonEEGchannels'] = ['X1','X2','X3','TRG','CM','A1','A2']
        # projParams['MiParams']['label_keys'] = (0, 1, 2) #MI labels for training: {0: 'right', 1: 'left', 2: 'idle', 3: 'tongue', 4: 'legs'}
        #2a
        projParams['EegParams']['epoch_len_sec'] = 2.5
        projParams['EegParams']['sfreq'] = 250
        projParams['EegParams']['chan_names'] = ['Fz','FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'C5', 'C3', 'C1', 'Cz', 'C2', 'C4', 'C6', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4', 'P1', 'Pz', 'P2', 'POz', 'EOG-left', 'EOG-central', 'EOG-right']
        projParams['EegParams']['nonEEGchannels'] = ['EOG-left', 'EOG-central', 'EOG-right']
        projParams['MiParams']['label_keys'] = (1, 2, 3, 4) #MI labels of BCI IV dataset: {1: 'left', 2: 'right', 3: 'foot', 4: 'tongue'}

        projParams['MiParams']['full_screen'] = False
        projParams['MiParams']['audio'] = False
        projParams['MiParams']['decomposition'] = 'CSP'# 'CSP' 'ICA' None
        #projParams['MiParams']['classifier'] = 'LDA'
        projParams['MiParams']['l_freq'] = 8#6
        projParams['MiParams']['h_freq'] = 30#40
        projParams['MiParams']['clean_epochs_ar_flg'] = False # clean_epochs_ar_flg = False  <->  augment_correct_trial_only_flg = true
        projParams['MiParams']['max_bad_chan_in_epoch'] = 1
        projParams['MiParams']['n_csp_comp'] = int(np.ceil(len(projParams['MiParams']['label_keys'])/2 + 1)*2)
        projParams['MiParams']['power_bands'] = [projParams['MiParams']['l_freq'], projParams['MiParams']['h_freq']] #[8,12,16,20,25,30]  [6,12,18,24,30]  [projParams['MiParams']['l_freq'], projParams['MiParams']['h_freq']]
        projParams['MiParams']['feature'] = 'BandPower' #'mixed' 'BandPower' 'Entropy' 'RMS' 'Spectral' 'Higuchi' 'AR' 'MVAR'
        #projParams['MiParams']['nCV'] = 20
        projParams['MiParams']['nFold'] = 3 # if len(projParams['MiParams']['label_keys']) == 4 else   6
        projParams['MiParams']['inverseCV'] = True
        projParams['MiParams']['feature_noise_aug_factor'] = 0 # projParams['MiParams']['nFold']-1  0: no augmentation
        projParams['MiParams']['feature_noise_variation_factor'] = 0.5

        projParams['SsvepParams']['electrodes'] = ["O1", "O2"] #electrodes of interest
        projParams['SsvepParams']['l_freq'] = 4
        projParams['SsvepParams']['h_freq'] = 40
        projParams['SsvepParams']['nTrainCondTrials'] = 20
        projParams['SsvepParams']['testPercent'] = 0.3

        projParams['DroneParams']['speed'] = 10
        projParams['DroneParams']['move_distance'] = 30
        projParams['DroneParams']['idle_sleep'] = 2 #sec
        projParams['DroneParams']['FPS'] = 120

        projParams['RuntimeParams']['acc_thresh'] = 0.5 #accuracy threshold
        projParams['RuntimeParams']['localhost'] = 8844
        projParams['RuntimeParams']['playback_Online_flg'] = False
        projParams['RuntimeParams']['playback_OfflineExpSSVEP_flg'] = False

        projParams['FilesParams']['datasetsFp'] = "C:\My Files\Work\BGU\Datasets\drone BCI"
        projParams['FilesParams']['cspFittedModelName'] = "model.pkl" # None -> "model_30trials.pkl"
        projParams['FilesParams']['modelMIfn'] = "TrainedMImodel.pkl"
        projParams['FilesParams']['modelSSVEPfn'] = "TrainedSSVEPmodel.pkl"
        projParams['FilesParams']['OnlineDataFn'] = "OnlineData.pkl"
        projParams['FilesParams']['SSVEPtraindataFn'] = "SSVEPtraindata.pkl"
        projParams['FilesParams']['trainDataFn'] = "train_data.mat"
        projParams['FilesParams']['sourceDataFn'] = "source_data.mat" # None
        projParams['FilesParams']['augSourceDataFn'] = "augmented_source_data.mat"
        projParams['FilesParams']['testDataFn'] = "test_data.mat" # "not_exist.file"
        projParams['FilesParams']['onlineTestDataFn'] = "test_data.mat"
        projParams['FilesParams']['classResults'] = "classResults.csv"

        ########################
        #setups
        projParams['MiParams']['label_keys'] = (1, 2)
        projParams['MiParams']['decomposition'] = 'CSP'
        projParams['MiParams']['feature'] = 'BandPower'
        projParams['MiParams']['input_prefix'] = '' #set only when testing augmentation!!!!  x1TypFitCorrectTrl_
        mode = 'Small' #Full Small Noise

        projParams['MiParams']['n_csp_comp'] = int(np.ceil(len(projParams['MiParams']['label_keys'])/2 + 1)*2)
        set_percent = str(int(100/projParams['MiParams']['nFold']))
        if mode == 'Full':
            projParams['MiParams']['inverseCV'] = False
            projParams['MiParams']['nFold'] = 7
            set_percent = '100'
        elif mode == 'Noise':
            projParams['MiParams']['feature_noise_aug_factor'] = projParams['MiParams']['nFold']-1

        output_prefix = mode+set_percent + 'cls'+str(len(projParams['MiParams']['label_keys'])) + projParams['MiParams']['decomposition'] + projParams['MiParams']['feature'] + '_'
        print(projParams['MiParams']['input_prefix']+output_prefix)
        projParams['FilesParams']['cspFittedModelName'] = output_prefix + projParams['FilesParams']['cspFittedModelName']
        projParams['FilesParams']['sourceDataFn'] = output_prefix + projParams['FilesParams']['sourceDataFn']
        projParams['FilesParams']['augSourceDataFn'] = projParams['MiParams']['input_prefix'] + output_prefix + projParams['FilesParams']['augSourceDataFn']
        projParams['FilesParams']['classResults'] = projParams['MiParams']['input_prefix'] + output_prefix + projParams['FilesParams']['classResults']

        return projParams
