import numpy as np
import matplotlib.pyplot as plt
from scipy.fftpack import fft

OFFSET = 1 #matlab implementation
# OFFSET = 3 #custom implementation
N_SAMPLES = 64
OSR = 160
N_SAMPLES_MOD2 = N_SAMPLES*OSR
FUNDAM_INDEX = 9

# Evaluate linearity/noise of CIC input (output of MOD2)
folder = "../src/tb/"
csv_file = "mod2_out.txt"

data = np.genfromtxt(folder+csv_file)

totransform = data[OFFSET:N_SAMPLES_MOD2+OFFSET]            #compute DFT
plt.plot(totransform, "-o")
transform = fft(totransform)
fft_lin = 2.0/N_SAMPLES_MOD2 * np.abs(transform[:N_SAMPLES_MOD2])

fft_db = 20*np.log10(fft_lin)
fig, ax = plt.subplots()
plt.xscale("log")
ax.plot(fft_db)

totsquared = sum(fft_lin[1:FUNDAM_INDEX//2]**2) + sum(fft_lin[FUNDAM_INDEX+1:N_SAMPLES_MOD2//2]**2)
sndr_lin = (fft_lin[FUNDAM_INDEX]**2)/totsquared
sndr = 10*np.log10(sndr_lin)   
print(f"SNDR MOD2 = {sndr}")


# Evaluate performance of CIC filter
folder = "../src/tb/"
csv_file = "cic_filter_out.txt"

data = np.genfromtxt(folder+csv_file)

totransform = data[OFFSET:N_SAMPLES+OFFSET]            #compute DFT
plt.plot(totransform, "-o")
transform = fft(totransform)
fft_lin = 2.0/N_SAMPLES * np.abs(transform[:N_SAMPLES])


fft_db = 20*np.log10(fft_lin)
fig, ax = plt.subplots()
ax.stem(fft_db)

totsquared = sum(fft_lin[1:FUNDAM_INDEX//2]**2) + sum(fft_lin[FUNDAM_INDEX+1:N_SAMPLES//2]**2)
sndr_lin = (fft_lin[FUNDAM_INDEX]**2)/totsquared
sndr = 10*np.log10(sndr_lin)   
print(f"SNDR CIC = {sndr}")

plt.show()