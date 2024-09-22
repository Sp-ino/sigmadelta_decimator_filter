from math import log
import numpy as np
import matplotlib.pyplot as plt
np.seterr(divide='ignore', invalid='ignore')

OSR = 160
FFT_RESOLUTION = 1024
LEN = OSR*FFT_RESOLUTION

def comb(in_data, D):
    out_data = []
    delay = [0] * D
    for sample in in_data:
        out_data.append(sample - delay[-1])
        delay = [sample] + delay
        delay.pop()
    return out_data


def integrator(in_data):
    delay = 0
    out_data = []
    for sample in in_data:
        y = delay + sample    
        out_data.append(y)
        delay = y
    return out_data


def cic_filter_time(input):
    return np.array(comb(
        comb(
            comb(
                integrator(
                    integrator(
                        integrator(input)
                    )
                ), OSR          
            ), OSR  
        ), OSR
    )) # Apply the integrator, then the comb with delay 160.


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


impulse = np.array([1]+[0]*(LEN))

# Impulse resp of nonrecursive implementation
impulse_resp = cic_filter_nonrec_time(impulse)

# Impulse resp of reference implementation
impulse_resp_ref = cic_filter_time(impulse)
impulse_resp_ref = impulse_resp_ref[0:LEN:OSR]
print(len(impulse_resp))
print(len(impulse_resp_ref))

# Plot result
plt.figure
plt.plot(impulse_resp)
plt.plot(impulse_resp_ref)

# Only plot the positive frequencies (-ive freqs are just an image of +ive)
xaxis = np.arange(FFT_RESOLUTION/2) * 0.5/(FFT_RESOLUTION/2)
plt.figure(figsize=(12,4))
plt.plot(xaxis,(20*np.log10(np.abs(np.fft.fft(impulse_resp))))[0:int(FFT_RESOLUTION/2)],'--', label="nonrecursive")
plt.plot(xaxis,(20*np.log10(np.abs(np.fft.fft(impulse_resp_ref))))[0:int(FFT_RESOLUTION/2)],'--', label="reference")
axes = plt.gca() 
# axes.set_xlim([0,0.5])
# axes.set_ylim([-25,20])
plt.grid()
plt.legend()
plt.title(f'CIC Frequency Response (Order = 3, OSR = {OSR})')
plt.xlabel('Normalised freq (2$\pi$ radians/sample)')
plt.ylabel('Filter Magnitude Response (dB)')
plt.show()