
from enum import Enum

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

        # projParams['EegParams']['epoch_len_sec'] = 2 # 2,3,4
        # projParams['EegParams']['sfreq'] = 300
        # projParams['EegParams']['chan_names'] = ['P3','C3', 'F3', 'Fz', 'F4', 'C4', 'P4', 'Cz','CM', 'A1', 'Fp1', 'Fp2' , 'T3', 'T5', 'O1', 'O2', 'X3' , 'X2', 'F7', 'F8', 'X1', 'A2', 'T6', 'T4', 'TRG']
        # projParams['EegParams']['nonEEGchannels'] = ['X1','X2','X3','TRG','CM','A1','A2']
        # projParams['MiParams']['label_keys'] = (0, 1, 2) #MI labels for training: {0: 'right', 1: 'left', 2: 'idle', 3: 'tongue', 4: 'legs'}
        projParams['EegParams']['epoch_len_sec'] = 2 # 2,3
        projParams['EegParams']['sfreq'] = 250
        projParams['EegParams']['chan_names'] = ['Fz','FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'C5', 'C3', 'C1', 'Cz', 'C2', 'C4', 'C6', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4', 'P1', 'Pz', 'P2', 'POz', 'EOG-left', 'EOG-central', 'EOG-right']
        projParams['EegParams']['nonEEGchannels'] = ['EOG-left', 'EOG-central', 'EOG-right']
        projParams['MiParams']['label_keys'] = (1, 2, 3, 4) #MI labels of BCI IV dataset: {1: 'left', 2: 'right', 3: 'foot', 4: 'tongue'}

        projParams['MiParams']['full_screen'] = False
        projParams['MiParams']['audio'] = False
        projParams['MiParams']['model_type'] = 'csp_lda'
        projParams['MiParams']['l_freq'] = 7
        projParams['MiParams']['h_freq'] = 30
        projParams['MiParams']['max_bad_chan_in_epoch'] = 1
        projParams['MiParams']['n_csp_comp'] = 6
        projParams['MiParams']['nCV'] = 20 #10
        projParams['MiParams']['nFold'] = 5 #10

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
        projParams['RuntimeParams']['playback_flg'] = False

        projParams['FilesParams']['datasetsFp'] = "C:\My Files\Work\BGU\Datasets\drone BCI"
        projParams['FilesParams']['cspFittedModelName'] = "model.pkl" # None model_30trials.pkl
        projParams['FilesParams']['modelMIfn'] = "TrainedMImodel.pkl"
        projParams['FilesParams']['modelSSVEPfn'] = "TrainedSSVEPmodel.pkl"
        projParams['FilesParams']['SSVEPtraindataFn'] = "SSVEPtraindata.pkl"
        projParams['FilesParams']['trainDataFn'] = "train_data.mat"
        projParams['FilesParams']['sourceDataFn'] = "source_data.mat" #None
        projParams['FilesParams']['augSourceDataFn'] = "augmented_source_data.mat" # aug15_augmented_source_data.mat  alpha_beta_aug15_augmented_source_data.mat
        projParams['FilesParams']['testDataFn'] = "test_data.mat" #"not_exist.file"
        projParams['FilesParams']['onlineTestDataFn'] = "online_test_data.mat"

        return projParams
