# Lossy-Audio-Compression

The implementation of MPEG Audio Compression.

Encoder_main_script.m simply takes an input of .wav file and quantizes the frequency domain coefficients. 
The algorithm is based on the psychoacoustic model of human hearing system. 

- In phase 1, many signals are generated, and STFT and spectrogram of a taken signal is created in MATLAB environment.

- In the phase 2, a decimator, a quantizer, transform coding with DFT and DCT is created and some of the missing parts of a MPEG/Audio encoder to do audio compression via MATLAB.
