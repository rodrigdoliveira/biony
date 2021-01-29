#!/usr/bin/env python
# -*- coding: utf-8 -*-
import biosppy
from biosppy import storage
from biosppy.signals import ecg
from biosppy.signals import bvp
from biosppy.signals import eda
from biosppy.signals import eeg
from biosppy.signals import emg
from biosppy.signals import resp
import json
import numpy as np
import time
import datetime
import sys

class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return json.JSONEncoder.default(self, obj)

def main():
    
    signalType = input()

    receivedString = input()

    s_rate = float(input())

    # load raw ECG signal
    signal, mdata = storage.load_txt(receivedString)

    t0 = time.time()
    out = None

    if(signalType == "bvp"):
        out = bvp.bvp(signal=signal, sampling_rate=s_rate, show=False)
    elif(signalType == "ecg"):
        out = ecg.ecg(signal=signal, sampling_rate=s_rate, show=False)
    elif(signalType == "eda"):
        out = eda.eda(signal=signal, sampling_rate=s_rate, show=False)
    elif(signalType == "eeg"):
        out = eeg.eeg(signal=signal, sampling_rate=s_rate, show=False)
    elif(signalType == "emg"):
        out = emg.emg(signal=signal, sampling_rate=s_rate, show=False)
    elif(signalType == "resp"):
        out = resp.resp(signal=signal, sampling_rate=s_rate, show=False)


    #t1 = time.time()
    #print(t1-t0)

    new_out = out.as_dict()

    newJson = {}
    for result in new_out:
        newJson[result] = json.dumps(new_out[result], cls=NumpyEncoder)

    #newJson["normalTime"] = t1 - t0
    #t2 = time.time()

    #newJson["overTime"] = t2 - t0
    storage.dumpJSON(newJson, receivedString)
    return 1

json.dump(main(), sys.stdout)

