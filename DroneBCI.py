#main script of droneBCI project

import threading
import queue
from multiprocessing import Process
import signal as sig

from projectParams import getParams, SessionType, DroneCommands
import Session as sess
import droneCtrl as drone
import DSI_to_Python as dsi
import Show_Flashes

if __name__ == "__main__":

    projParams = getParams()

    train_trials_percent = 100
    sessType = SessionType.OfflineTrainLdaMI
    ans = input('Select Session Type:     0:Online   1:MI testing online   2:SSVEP training   3:MI training   4:Train MI Csp from file   5:Train MI Lda from file   6:Calculate test accuracy from file')
    sessType = SessionType(int(ans))
    if sessType == SessionType.OfflineExpMI or sessType == SessionType.OfflineTrainCspMI:
        train_trials_percent = int(input('percent of trials for training: '))

    if sessType == SessionType.OfflineTrainCspMI or sessType == SessionType.OfflineTrainLdaMI or sessType == SessionType.TestAccuracy:
        eegSession = sess.Session(DSIparser=None, projParams=projParams)
        eegSession.train_model(sessType, train_trials_percent)

    else:

        #connect to DSI headset to read epochs
        DSIparser = dsi.TCPParser('localhost', projParams['RuntimeParams']['localhost']) #make sure that DSI streamer client port 8844 is active
        sig.signal(sig.SIGINT, DSIparser.onlineHandler) # Catch ctrl+C error
        # DSIparser = None

        #init eeg decoding session
        eegSession = sess.Session(DSIparser, projParams=projParams)

        if sessType == SessionType.OfflineExpMI:
            eegSession.train_model(sessType,train_trials_percent)

        elif sessType == SessionType.OnlineExpMI:
            eegSession.run_online_experiment_mi()

        else:

            #start the SSVEP stimuli
            pFlicker = Process(target=Show_Flashes.main)
            pFlicker.start()

            if sessType == SessionType.OfflineExpSSVEP:
                eegSession.train_model(sessType)

            else: #Online

                #commands queue
                CommandsQueue = queue.Queue(0)
                CommandsQueue.put([DroneCommands.up, 'AUTO TAKE OFF']) #auto takeoff

                #start the online session
                tOnline = threading.Thread(target=eegSession.run_online, args=(CommandsQueue,))
                tOnline.start()

                #connect drone (drone video should apear together with the flickers while training)
                tDrone = threading.Thread(target=drone.run, args=(CommandsQueue,))
                tDrone.start()

                #stops with ctrl+C
                pFlicker.join() #kill
                tOnline.join()
                tDrone.join()

        # sys.exit()
