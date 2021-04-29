import manual_control_pygame as drone
import DSI_to_Python as dsi
import threading, queue
import numpy as np
import Show_Flashes


if __name__ == "__main__":

    tcp = dsi.TCPParser('localhost', 8844)
    # drone1 = drone.FrontEnd()

    table = queue.Queue(0)
    tDsi = threading.Thread(target=tcp.example_plot, args=(table,))
    tDrone = threading.Thread(target=drone.main ,args=(table,))
    tFlicker = threading.Thread(target=Show_Flashes.main)

    #tcp.example_plot()
    tDsi.start()
    while table.get != 999:
        pass
    tDrone.start()
    tFlicker.start()
