# send control commands to the drone
# present drone live video stream
# to avoid IMU error, Fly in good lights and above floor with patterns

from djitellopy import Tello
import cv2
import pygame
import numpy as np
import time
import os
import threading
from projectParams import getParams, DroneCommands

is_active = True

def drone_video(tello, projParams):

    global is_active

    os.environ['SDL_VIDEO_WINDOW_POS'] = "%d,%d" % (10, 60)
    pygame.init()
    pygame.display.set_caption("Tello video stream")
    screen = pygame.display.set_mode([960, 720])  # , pygame.FULLSCREEN)

    # In case streaming is on. This happens when we quit this program without the escape key.
    tello.streamoff()
    tello.streamon()

    frame_read = tello.get_frame_read()

    while is_active:
        # if not frame_read.stopped:
        #     print('Video Failure!')
        #     break
        screen.fill([0, 0, 0])
        frame = frame_read.frame
        text = "Battery: {}%".format(tello.get_battery())
        cv2.putText(frame, text, (5, 720 - 5),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        frame = np.rot90(frame)
        frame = np.flipud(frame)
        frame = pygame.surfarray.make_surface(frame)
        screen.blit(frame, (0, 0))
        pygame.display.update()
        time.sleep(1 / projParams['DroneParams']['FPS'])


def run(CommandsQueue):

    projParams = getParams()

    video_ready_sleep = 7#sec
    is_airborn = False
    global is_active

    tello = Tello()
    tello.connect()
    tello.set_speed(projParams['DroneParams']['speed'])

    droneVid = threading.Thread(target=drone_video, args=(tello,projParams,))
    droneVid.start()
    time.sleep(video_ready_sleep)

    while is_active:

        #execute next command from the que
        if not CommandsQueue.empty():
            command = CommandsQueue.get()
            # timeStamp = str(datetime.datetime.now())
            print('Command for Drone: ' + str(command[0]) + ' at time ' + command[1])

            if command[0] == DroneCommands.up:
                if is_airborn:
                    tello.move_up(projParams['DroneParams']['move_distance'])
                else:
                    tello.takeoff()
                    is_airborn = True
            # elif command[0] == DroneCommands.idle:
            #     time.sleep(projParams['DroneParams']['idle_sleep'])
            elif command[0] == DroneCommands.up and is_airborn == True:
                tello.move_up(projParams['DroneParams']['move_distance'])
            elif command[0] == DroneCommands.down and is_airborn == True:
                tello.move_down(projParams['DroneParams']['move_distance'])
            elif command[0] == DroneCommands.forward and is_airborn == True:
                tello.move_forward(projParams['DroneParams']['move_distance'])
            elif command[0] == DroneCommands.back and is_airborn == True:
                tello.move_back(projParams['DroneParams']['move_distance'])
            elif command[0] == DroneCommands.left and is_airborn == True:
                tello.move_left(projParams['DroneParams']['move_distance'])
            elif command[0] == DroneCommands.right and is_airborn == True:
                tello.move_right(projParams['DroneParams']['move_distance'])
            elif command[0] == DroneCommands.flip and is_airborn == True:
                tello.flip_back()
            elif command[0] == DroneCommands.stop:
                is_active = False
                break
        # else:
        #     time.sleep(projParams['DroneParams']['idle_sleep'])

    tello.land()
    is_airborn = False
    droneVid.join()
    tello.end()
