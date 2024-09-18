import numpy as np
import matplotlib.pyplot as plt
from scipy.fftpack import fft

OFFSET = 32 #matlab implementation
# OFFSET = 3 #custom implementation
N_SAMPLES = 64
OSR = 160
N_SAMPLES_MOD2 = N_SAMPLES*OSR
FUNDAM_INDEX = 9


# ---------------------------- Definitions -------------------------------
def mov_avg_2(in_data: np.ndarray):
    out_data = []
    for n, x_n in enumerate(in_data):
        if n == 0:
            y_n = x_n
        else:
            y_n = in_data[n] + in_data[n-1]
        
        out_data.append(y_n)

    return np.array(out_data)


def mov_avg_5(in_data: np.ndarray):
    out_data = []
    for n, x_n in enumerate(in_data):
        if n == 0:
            y_n = x_n
        elif n == 1:
            y_n = in_data[n] + in_data[n-1]
        elif n == 2:
            y_n = in_data[n] + in_data[n-1] + in_data[n-2]
        elif n == 3:
            y_n = in_data[n] + in_data[n-1] + in_data[n-2] + in_data[n-3]
        elif n >= 4:
            y_n = in_data[n] + in_data[n-1] + in_data[n-2] + in_data[n-3] + in_data[n-4]
        # elif 0 < n < 5:
        #     last_5_samples = in_data[0:n]
        #     y_n = np.sum(last_5_samples)
        # else:
        #     last_5_samples = in_data[n-5:n]
        #     y_n = np.sum(last_5_samples)
        
        out_data.append(y_n)
    
    return np.array(out_data)


def stage_2(input: np.ndarray):
    out_nondec = mov_avg_2(mov_avg_2(mov_avg_2(input)))
    return out_nondec[0:len(out_nondec):2]


def stage_5(input: np.ndarray):
    out_nondec = mov_avg_5(mov_avg_5(mov_avg_5(input)))
    return out_nondec[0:len(out_nondec):5]


def cic_filter_nonrec_time(input: np.ndarray):
    out_interm = stage_2(stage_2(stage_2(stage_2(stage_2(input)))))
    return stage_5(out_interm)
