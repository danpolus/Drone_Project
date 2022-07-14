# decode paradigms from EEG

import pickle
import time
import datetime
import numpy as np
import sys
sys.path.append('../bci4als/')
from scripts.offline_training import offline_experiment
from scripts.online_testing import online_experiment
import src.bci4als.eeg as eeg
import SSVEPmodel
from projectParams import SessionType, DroneCommands

class Session:
    """
    A class of training and online sessions

    """

    def __init__(self, DSIparser, projParams):

        #memebers
        self.modelMI = None
        self.modelSSVEP = None
        self.DSIparser = DSIparser
        self.projParams = projParams

        self.acc_thresh = 0.5 #accuracy threshold

        self.eeg = eeg.EEG(DSIparser, projParams)

    def train_model(self, sessType: SessionType, train_trials_percent=100):
        if sessType == SessionType.Online or sessType == SessionType.OnlineExpMI:
            raise Exception("This is OFFLINE!")
        elif sessType == SessionType.OfflineExpSSVEP:
            self.modelSSVEP = SSVEPmodel.trainModel(self.eeg)
            if self.modelSSVEP != None:
                with open(self.projParams['FilesParams']['modelSSVEPfn'], 'wb') as file:  # save SSVEP model
                    pickle.dump(self.modelSSVEP, file)
        else:
            self.modelMI = offline_experiment(self.eeg, sessType, train_trials_percent)
            if self.modelMI != None:
                with open(self.projParams['FilesParams']['modelMIfn'], 'wb') as file: #save MI model
                    pickle.dump(self.modelMI, file)

    def run_online_experiment_mi(self):
        online_experiment(self.eeg)

    def run_online(self, CommandsQueue):

        self.modelMI = pickle.load(open(self.projParams['FilesParams']['modelMIfn'], 'rb'))
        self.modelSSVEP = pickle.load(open(self.projParams['FilesParams']['modelSSVEPfn'], 'rb'))
        if not self.modelMI or not self.modelSSVEP:
            raise Exception("*****Something went wrong: MI/SSVEP model not found*****")

        self.DSIparser.runOnline = True

        if self.projParams['RuntimeParams']['playback_Online_flg']:
            recordedSignal = pickle.load(open(self.projParams['FilesParams']['OnlineDataFn'], 'rb'))
            if not recordedSignal:
                raise Exception("*****Something went wrong: playback recordings not found*****")
            cnt = 0
        else:
            self.eeg.on()
            recordedSignal  = np.empty(shape=[0, len(self.eeg.chan_names), self.eeg.epoch_len_sec*self.eeg.sfreq])

        while self.DSIparser.runOnline:  # To exit loop press ctrl+C
            # TODO:  ctrl+C kills the main thread. need to find better solution. (daemon thread?)

            time.sleep(self.projParams['EegParams']['epoch_len_sec']/2)  # Wait 1 second

            if self.projParams['RuntimeParams']['playback_Online_flg']:
                if cnt >= recordedSignal.shape[0]:
                    break
                signalArray = recordedSignal[cnt, :, :]
                cnt += 1
            else:
                signalArray = self.eeg.get_board_data()
                if signalArray is None: #epoch samples are not ready yet
                    continue
                recordedSignal = np.append(recordedSignal, np.expand_dims(signalArray, axis=0), axis=0)

            # Choose the best prediction
            command_pred = DroneCommands.idle
            mi_pred, mi_acc = self.modelMI.online_predict(signalArray, self.eeg)
            if mi_acc >= self.projParams['RuntimeParams']['acc_thresh']:
                command_pred = mi_pred
            ssvep_pred, ssvep_acc = SSVEPmodel.predictModel(signalArray, self.modelSSVEP, self.DSIparser)
            if ssvep_acc > mi_acc and ssvep_acc > self.projParams['RuntimeParams']['acc_thresh']:
                command_pred = ssvep_pred

            # Send prediction
            timeStamp = str(datetime.datetime.now())
            CommandsQueue.put([command_pred, timeStamp])
            print('Classifier output is:  ' + command_pred.name.upper() + '  at time ' + timeStamp)

        if not self.projParams['RuntimeParams']['playback_Online_flg']:
            self.eeg.off()
            with open(self.projParams['FilesParams']['OnlineDataFn'], 'wb') as file:
                pickle.dump(recordedSignal, file)

