from math import log
import numpy as np
import matplotlib.pyplot as plt
np.seterr(divide='ignore', invalid='ignore');

OSR = 64
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


impulse = np.array([1]+[0]*(LEN))
# impulseResponse = integrator(comb(impulse, 160)) # Apply the comb with delay 160, then the integrator.
impulse_resp_dec =  cic_filter_time(impulse)# Apply the integrator, then the comb with delay 160.
impulse_resp_dec = impulse_resp_dec[0:LEN:OSR]
print(impulse_resp_dec.shape)

# Plot result
plt.figure
plt.plot(impulse_resp_dec)

# Only plot the positive frequencies (-ive freqs are just an image of +ive)
xaxis = np.arange(FFT_RESOLUTION/2) * 0.5/(FFT_RESOLUTION/2)
plt.figure(figsize=(12,4))
plt.plot(xaxis,(20*np.log10(np.abs(np.fft.fft(impulse_resp_dec))))[0:int(FFT_RESOLUTION/2)],'--')
axes = plt.gca() 
# axes.set_xlim([0,0.5])
# axes.set_ylim([-25,20])
plt.grid()
plt.legend()
plt.title(f'CIC Frequency Response (Order = 3, OSR = {OSR})')
plt.xlabel('Normalised freq (2$\pi$ radians/sample)')
plt.ylabel('Filter Magnitude Response (dB)')
plt.show()