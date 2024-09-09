from math import log
import numpy as np
import matplotlib.pyplot as plt
np.seterr(divide='ignore', invalid='ignore');

FFT_RESOLUTION = 1024
OSR = 160

def comb(inData, D):
    outData = []
    delay = [0] * D
    for sample in inData:
        outData.append(sample - delay[-1])
        delay = [sample] + delay
        delay.pop()
    return outData

def integrator(inData):
    delay = 0
    outData = []
    for sample in inData:
        y = delay + sample    
        outData.append(y)
        delay = y
    return outData

impulse = [1]+[0]*(FFT_RESOLUTION)
# impulseResponse = integrator(comb(impulse, 160)) # Apply the comb with delay 160, then the integrator.
impulseResponse2 = comb(
    comb(
        comb(
            integrator(
                integrator(
                    integrator(impulse)
                )
            )
        ,OSR
        ),
    OSR
    ),
OSR) # Apply the integrator, then the comb with delay 160.
# Plot result

plt.figure
plt.plot(impulseResponse2)

# Only plot the positive frequencies (-ive freqs are just an image of +ive)
xaxis = np.arange(FFT_RESOLUTION/2) * 0.5/(FFT_RESOLUTION/2)
plt.figure(figsize=(12,4))
# plt.plot(xaxis,(20*np.log10(np.abs(np.fft.fft(impulseResponse))))[0:int(FFT_RESOLUTION/2)], label="Comb then Integrator")
plt.plot(xaxis,(20*np.log10(np.abs(np.fft.fft(impulseResponse2))))[0:int(FFT_RESOLUTION/2)],'--', label="Integrator then Comb")
axes = plt.gca() 
# axes.set_xlim([0,0.5])
# axes.set_ylim([-25,20])
plt.grid()
plt.legend()
plt.title(f'CIC Frequency Response (Order = 3, OSR = {OSR})')
plt.xlabel('Normalised freq (2$\pi$ radians/sample)')
plt.ylabel('Filter Magnitude Response (dB)')
plt.show()