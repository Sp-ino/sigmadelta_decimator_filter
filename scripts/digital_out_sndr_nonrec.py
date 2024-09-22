import numpy as np
import matplotlib.pyplot as plt
from scipy.fftpack import fft

OFFSET = 32 #matlab implementation
# OFFSET = 3 #custom implementation
N_SAMPLES = 64
OSR = 160
N_SAMPLES_MOD2 = N_SAMPLES*OSR
FUNDAM_INDEX = 9

INPUT_SPECTRUM = False
PYTHON_CIC_DEC = True
VHDL_CIC_IMPULSE_RESP = False
VHDL_CIC_SPECTRUM = True


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



# ---------------- Evaluate properties of CIC input -----------------------
folder = "../src/tb/"
in_csv_file = "mod2_out_long.txt"
input_waveform = np.genfromtxt(folder+in_csv_file)

if INPUT_SPECTRUM:
    # Plot spectrum of CIC input (output of MOD2)
    totransform = input_waveform[OFFSET:N_SAMPLES_MOD2+OFFSET]            #compute DFT
    # plt.plot(totransform, "-o")
    transform = fft(totransform)
    in_fft_lin = 2.0/N_SAMPLES_MOD2 * np.abs(transform[:N_SAMPLES_MOD2//2])

    fft_db = 20*np.log10(in_fft_lin)
    fig_in, ax_in = plt.subplots()
    plt.xscale("log")
    freq = np.linspace(0, 0.5, len(in_fft_lin))
    ax_in.plot(freq, fft_db)
    ax_in.set_title("CIC input spectrum")
    ax_in.set_xlabel("Normalized frequency")
    ax_in.set_ylabel("Amplitude [dB20]")
    plt.show()

# Compute theoretical response of 3rd order CIC with 160 decimation ratio
ideal_output_wf = np.array(cic_filter_nonrec_time(input_waveform))

theor_out_fft_db = None


if PYTHON_CIC_DEC:
    # Plot time domain wf and spectrum of theoretical CIC output with downsampling
    totransform = ideal_output_wf[OFFSET:N_SAMPLES+OFFSET]            #compute DFT
    fig_ideal_out, ax_ideal_out = plt.subplots()
    plt.xscale("linear")
    ax_ideal_out.plot(totransform)
    ax_ideal_out.set_title("CIC output (Python)")
    ax_ideal_out.set_xlabel("Sample")
    ax_ideal_out.set_ylabel("Amplitude")
    plt.show()

    transform = fft(totransform)
    theor_out_fft_lin = 2.0/N_SAMPLES_MOD2 * np.abs(transform[:N_SAMPLES//2])
    theor_out_fft_db = 20*np.log10(theor_out_fft_lin)
    # normalize carrier to 0 dB
    theor_out_fft_db = theor_out_fft_db - np.max(theor_out_fft_db)

    fig_outt, ax_outt = plt.subplots()
    freq = np.linspace(0, 0.5, len(theor_out_fft_db))
    ax_outt.stem(freq, theor_out_fft_db, bottom=-140)
    ax_outt.set_title("CIC output spectrum (Python)")
    ax_outt.set_xlabel("Normalized frequency")
    ax_outt.set_ylabel("Amplitude [dB20]")
    plt.show()

    totsquared = sum(theor_out_fft_lin[1:FUNDAM_INDEX//2]**2) + sum(theor_out_fft_lin[FUNDAM_INDEX+1:N_SAMPLES//2]**2)
    sndr_lin = (theor_out_fft_lin[FUNDAM_INDEX]**2)/totsquared
    sndr = 10*np.log10(sndr_lin)   
    print(f"Output SNDR of theoretical CIC = {sndr}")
