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
PYTHON_CIC_NONDEC = False
PYTHON_CIC_DEC = True
VHDL_CIC_IMPULSE_RESP = False
VHDL_CIC_SPECTRUM = True

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
ideal_output_wf = np.array(cic_filter_time(input_waveform))

theor_out_fft_db = None

if PYTHON_CIC_NONDEC:
    # Plot time domain wf and spectrum of theoretical CIC output without downsampling
    totransform = ideal_output_wf[OFFSET*OSR:N_SAMPLES_MOD2+OFFSET*OSR]            #compute DFT
    fig_ideal_out, ax_ideal_out = plt.subplots()
    plt.xscale("linear")
    ax_ideal_out.plot(totransform)
    ax_ideal_out.set_title("CIC output without downsampling (Python)")
    ax_ideal_out.set_xlabel("Sample")
    ax_ideal_out.set_ylabel("Amplitude")
    plt.show()

    transform = fft(totransform)
    theor_out_fft_lin_nondec = 2.0/N_SAMPLES_MOD2 * np.abs(transform[:N_SAMPLES_MOD2//2])
    theor_out_fft_db_nondec = 20*np.log10(theor_out_fft_lin_nondec)

    fig_outt, ax_outt = plt.subplots()
    freq = np.linspace(0, 0.5, len(theor_out_fft_db_nondec))
    ax_outt.plot(freq, theor_out_fft_db_nondec)
    ax_outt.set_title("CIC output spectrum without downsampling (Python)")
    ax_outt.set_xlabel("Normalized frequency")
    ax_outt.set_ylabel("Amplitude [dB20]")
    plt.show()

if PYTHON_CIC_DEC:
    # Plot time domain wf and spectrum of theoretical CIC output with downsampling
    totransform = ideal_output_wf[OFFSET*OSR:N_SAMPLES_MOD2+OFFSET*OSR:OSR]            #compute DFT
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


# ---------------- Evaluate impulse response of CIC ---------------------
if VHDL_CIC_IMPULSE_RESP:
    folder = "../src/tb/"
    out_csv_file = "cic_filter_out_impulseresp.txt"

    output_waveform = np.genfromtxt(folder+out_csv_file)

    # Evaluate output spectrum of CIC filter
    totransform = output_waveform#[OFFSET:N_SAMPLES+OFFSET]            #compute DFT
    # plt.plot(totransform, "-o")
    transform = fft(totransform)
    out_fft_lin = 2.0/N_SAMPLES * np.abs(transform[:N_SAMPLES//2])
    out_fft_db = 20*np.log10(out_fft_lin)

    fig_out, ax_out = plt.subplots()
    freq = np.linspace(0, 0.5, len(out_fft_db))
    ax_out.plot(freq, out_fft_db)
    ax_out.set_title("CIC transfer function from VHDL TB")
    ax_out.set_xlabel("Normalized frequency")
    ax_out.set_ylabel("Amplitude [dB20]")
    plt.show()


# ---------- Evaluate properties of CIC response to MOD2 ------------------
if VHDL_CIC_SPECTRUM:
    folder = "../src/tb/"
    out_csv_file = "cicv3_filter_out.txt"

    output_waveform = np.genfromtxt(folder+out_csv_file)

    # Evaluate output spectrum of CIC filter
    totransform = output_waveform[OFFSET:N_SAMPLES+OFFSET]            #compute DFT
    # plt.plot(totransform, "-o")
    transform = fft(totransform)
    out_fft_lin = 2.0/N_SAMPLES * np.abs(transform[:N_SAMPLES//2])
    out_fft_db = 20*np.log10(out_fft_lin)
    out_fft_db = out_fft_db - np.max(out_fft_db)

    fig_out, ax_out = plt.subplots()
    freq = np.linspace(0, 0.5, len(out_fft_db))
    if theor_out_fft_db is not None:
        ax_out.stem(freq, theor_out_fft_db, label="Python (floating point)", bottom=-140, linefmt='C1-')
    ax_out.stem(freq, out_fft_db, label="VHDL", bottom=-140, linefmt='C0-')
    ax_out.set_title("CIC output spectrum (VHDL vs. Python)")
    ax_out.set_xlabel("Normalized frequency")
    ax_out.set_ylabel("Amplitude [dB20]")
    ax_out.legend()
    plt.show()

    # Evaluate output SNDR of CIC filter
    totsquared = sum(out_fft_lin[1:FUNDAM_INDEX//2]**2) + sum(out_fft_lin[FUNDAM_INDEX+1:N_SAMPLES//2]**2)
    sndr_lin = (out_fft_lin[FUNDAM_INDEX]**2)/totsquared
    sndr = 10*np.log10(sndr_lin)   
    print(f"SNDR CIC = {sndr}")
