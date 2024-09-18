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


def cic_filter_time(input):
    return comb(
        comb(
            comb(
                integrator(
                    integrator(
                        integrator(input)
                    )
                ), OSR          
            ), OSR  
        ), OSR
    ) # Apply the integrator, then the comb with delay 160.



# ---------------- Evaluate properties of CIC input -----------------------
folder = "../src/tb/"
in_csv_file = "mod2_out_long.txt"

input_waveform = np.genfromtxt(folder+in_csv_file)

# Plot spectrum of CIC input (output of MOD2)
totransform = input_waveform[OFFSET:N_SAMPLES_MOD2+OFFSET]            #compute DFT
# plt.plot(totransform, "-o")
transform = fft(totransform)
in_fft_lin = 2.0/N_SAMPLES_MOD2 * np.abs(transform[:N_SAMPLES_MOD2])

fft_db = 20*np.log10(in_fft_lin)
fig_in, ax_in = plt.subplots()
plt.xscale("log")
ax_in.plot(fft_db)
ax_in.set_title("CIC input spectrum")
plt.show()
plt.xscale("linear")

# Compute theoretical response of 3rd order CIC with 160 decimation ratio
ideal_output_wf = np.array(cic_filter_time(input_waveform))

# Plot spectrum of theoretical CIC output
totransform = ideal_output_wf[N_SAMPLES_MOD2//2:N_SAMPLES_MOD2+N_SAMPLES_MOD2//2]            #compute DFT
fig_ideal_out, ax_ideal_out = plt.subplots()
ax_ideal_out.plot(totransform)
ax_ideal_out.set_title("Theoretical CIC output")
plt.show()
transform = fft(totransform)
theor_out_fft_lin = 2.0/N_SAMPLES_MOD2 * np.abs(transform[:N_SAMPLES_MOD2])

fft_db = 20*np.log10(theor_out_fft_lin)
fig_outt, ax_outt = plt.subplots()
ax_outt.stem(fft_db)
ax_outt.set_title("Theoretical CIC output spectrum")
plt.show()

totsquared = sum(theor_out_fft_lin[1:FUNDAM_INDEX//2]**2) + sum(theor_out_fft_lin[FUNDAM_INDEX+1:N_SAMPLES_MOD2//2]**2)
sndr_lin = (theor_out_fft_lin[FUNDAM_INDEX]**2)/totsquared
sndr = 10*np.log10(sndr_lin)   
print(f"Output SNDR of theoretical CIC = {sndr}")



# ---------------- Evaluate impulse response of CIC ---------------------
folder = "../src/tb/"
out_csv_file = "cic_filter_out_impulseresp.txt"

output_waveform = np.genfromtxt(folder+out_csv_file)

# Evaluate output spectrum of CIC filter
totransform = output_waveform#[OFFSET:N_SAMPLES+OFFSET]            #compute DFT
# plt.plot(totransform, "-o")
transform = fft(totransform)
out_fft_lin = 2.0/N_SAMPLES * np.abs(transform[:N_SAMPLES])

fft_db = 20*np.log10(out_fft_lin)
fig_out, ax_out = plt.subplots()
ax_out.stem(fft_db)
ax_out.set_title("CIC transfer function from VHDL TB")
plt.show()


# ---------- Evaluate properties of CIC response to MOD2 ------------------
folder = "../src/tb/"
out_csv_file = "cicv3_filter_out.txt"

output_waveform = np.genfromtxt(folder+out_csv_file)

# Evaluate output spectrum of CIC filter
totransform = output_waveform[OFFSET:N_SAMPLES+OFFSET]            #compute DFT
# plt.plot(totransform, "-o")
transform = fft(totransform)
out_fft_lin = 2.0/N_SAMPLES * np.abs(transform[:N_SAMPLES])

fft_db = 20*np.log10(out_fft_lin)
fig_out, ax_out = plt.subplots()
ax_out.stem(fft_db)
ax_out.set_title("Actual CIC output spectrum")
plt.show()

# Evaluate output SNDR of CIC filter
totsquared = sum(out_fft_lin[1:FUNDAM_INDEX//2]**2) + sum(out_fft_lin[FUNDAM_INDEX+1:N_SAMPLES//2]**2)
sndr_lin = (out_fft_lin[FUNDAM_INDEX]**2)/totsquared
sndr = 10*np.log10(sndr_lin)   
print(f"SNDR CIC = {sndr}")
