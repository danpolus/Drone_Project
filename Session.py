# decode paradigms from EEG

import pickle
import time
import datetime
import SSVEPmodel
from projectParams import SessionType, DroneCommands

import sys
sys.path.append('../bci4als/')
from scripts.offline_training import offline_experiment
from scripts.online_testing import online_experiment
import src.bci4als.eeg as eeg

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
            self.eeg.on()
            self.modelSSVEP = SSVEPmodel.trainModel(self.DSIparser)
            self.eeg.off()
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
        self.eeg.on()

        if self.projParams['RuntimeParams']['playback_flg']:
            with open(self.projParams['FilesParams']['SSVEPtraindataFn'], 'rb') as file:
                recordedSignal = pickle.load(file)
                featuresDF = pickle.load(file)
                labels = pickle.load(file)
            cnt = 0

        while self.DSIparser.runOnline:  # To exit loop press ctrl+C
            # TODO:  ctrl+C kills the main thread. need to find better solution. (daemon thread?)

            time.sleep(self.projParams['EegParams']['epoch_len_sec']/2)  # Wait 1 second

            if self.projParams['RuntimeParams']['playback_flg']:
                signalArray = recordedSignal[cnt, :, :]
                print('  played label is: ' + DroneCommands(labels[cnt]).name.upper())
                cnt += 1
                if cnt >= len(labels):
                    break
            else:
                signalArray = self.eeg.get_board_data()
                if signalArray is None: #epoch samples are not ready yet
                    continue

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

        self.eeg.off()
