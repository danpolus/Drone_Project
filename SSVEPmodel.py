#train, predict SSVEP model

import mne
from scipy import signal
from lightgbm import LGBMClassifier
import pyttsx3
import numpy as np
import pandas as pd
import time
from projectParams import getParams, DroneCommands
from sklearn.model_selection import train_test_split
from sklearn import metrics
import matplotlib.pyplot as plt
import matplotlib as mpl
import pickle

def signalProc(signalArray, eeg, projParams):
    """
    "Signal processing function" that responsible for cleaning,  channel selection,  feature extraction
      input:data chunk nparray(n_channels , n_samples), eeg
      output:  features vector
    """

    # Get electrode indeces from the montage
    elec = []
    for el in projParams['SsvepParams']['electrodes']:
        elec.append(eeg.chan_names.index(el))

    # Filter the data
    Filtered = mne.filter.filter_data(signalArray[elec,:], sfreq=eeg.sfreq, l_freq=projParams['SsvepParams']['l_freq'], h_freq=projParams['SsvepParams']['h_freq'], verbose=0)
    # PSD
    _, Pxx_den = signal.welch(Filtered, fs=eeg.sfreq, nperseg=500, noverlap=450, scaling='spectrum', axis=1)

    # use the whole PSD as features
    featuresDF = pd.DataFrame(Pxx_den.flatten())

    return featuresDF

def predictModel(signalArray, model, eeg):
    """
    model prediction
    input: signalArray, model, eeg
    output: prediction, accuracy
    """

    projParams = getParams()

    # Process the data
    curTrialData = signalProc(signalArray, eeg, projParams)
    # Predict
    pred  = model.predict(curTrialData.transpose())
    pred_prob  = model.predict_proba(curTrialData.transpose())
    return DroneCommands(pred), pred_prob.max()

def trainModel(eeg):
    """
    Calibration and creation of new model by offline training of SSVEP Paradigm
    input: eeg
    output: trained model - output is written into the queue
    """

    projParams = getParams()

    if projParams['RuntimeParams']['playback_OfflineExpSSVEP_flg']:
        with open(projParams['FilesParams']['SSVEPtraindataFn'], 'rb') as file:
            recordedSignal = pickle.load(file)
            labels = pickle.load(file)

        #preprocessing and features
        featuresDF = pd.DataFrame()
        for iTrial in range(len(labels)):
            signalArray = recordedSignal[iTrial, :, :]
            curTrialData = signalProc(signalArray, eeg, projParams)
            featuresDF = pd.concat([featuresDF, curTrialData], axis=1)

    else:
        # Parameters
        # target_frq = [6, 7.5, 11] # Used frequencies
        action = [DroneCommands.idle, DroneCommands.up, DroneCommands.down, DroneCommands.flip]
        nLabels = len(action)

        # Text to speech engine
        engine = pyttsx3.init()
        triggerText = ['Do not focus on the blinks', 'Focus on the upper blink',
                       'focus on the bottom blink', 'Close your eyes']

        # Allocation
        labels = np.empty(shape=[0])
        featuresDF = pd.DataFrame()
        recordedSignal  = np.empty(shape=[0, 25, 600]) #save training data

        eeg.on()
        # Collecting labeled data
        for iLabel in range(nLabels):
            # Say the current stimuli to focus on
            engine.say(triggerText[iLabel])
            engine.runAndWait()
            labels = np.append(labels, np.ones(projParams['SsvepParams']['nTrainCondTrials'])*action[iLabel].value)
            iTrial = 0
            while iTrial<projParams['SsvepParams']['nTrainCondTrials']:
                time.sleep(projParams['EegParams']['epoch_len_sec']/2)  # Wait 1 second
                signalArray = eeg.get_board_data()
                if signalArray is None: #epoch samples are not ready yet
                    continue

                # Save training data
                recordedSignal = np.append(recordedSignal, np.expand_dims(signalArray, axis=0), axis=0)
                # Process the data
                curTrialData = signalProc(signalArray, eeg, projParams)
                # Append to the data frame
                featuresDF = pd.concat([featuresDF, curTrialData], axis=1)

                print('Collecting SSVEP training data:  ' + str(action[iLabel]) + ' trial #' + str(iTrial))

                iTrial += 1

        eeg.off()

        # Say training session is over
        engine.say('Open your eyes')
        engine.runAndWait()

        #save training data
        with open(projParams['FilesParams']['SSVEPtraindataFn'], 'wb') as file:
            pickle.dump(recordedSignal, file)
            pickle.dump(labels, file)


    # Train classifier
    model = LGBMClassifier(reg_lambda=0.05)
    model_validation(model, featuresDF, labels, projParams) #check model accuracy
    model.fit(featuresDF.transpose(), labels)

    return model

def model_validation(model, featuresDF, labels, projParams):
    mpl.use('TkAgg')

    X_train, X_test, y_train, y_test = train_test_split(featuresDF.transpose(), labels, test_size=projParams['SsvepParams']['testPercent']) # random_state=0
    model.fit(X_train, y_train)
    #
    # print('Training accuracy {:.4f}'.format(model.score(featuresDF.transpose(), labels)))
    pred_train = model.predict(X_train)
    pred_test = model.predict(X_test)
    print('train accuracy score: {0:0.4f}'.format(metrics.accuracy_score(y_train, pred_train)))
    print('test accuracy score: {0:0.4f}'.format(metrics.accuracy_score(y_test, pred_test)))
    cm_train = metrics.confusion_matrix(y_train,pred_train)
    cm_test = metrics.confusion_matrix(y_test, pred_test)
    disp = metrics.ConfusionMatrixDisplay(confusion_matrix=cm_train, display_labels = ['idle','up','down','flip'])
    disp.plot()
    plt.show(block=False)
    disp = metrics.ConfusionMatrixDisplay(confusion_matrix=cm_test, display_labels = ['idle','up','down','flip'])
    disp.plot()
    plt.show(block=False)
    # print('Confusion matrix\n\n', cm)
