function x = quantization(sample, sf, ba, QCa, QCb)

x= floor((QCa*sample/sf+QCb)*2^(ba-1));