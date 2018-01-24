function X = scaled_fft_db(x)

filter=sqrt(2.667)*hann(512);
y=x.*filter;
yfft=abs(fft(y));
yfft_norm=yfft/512;
yfft_dis=yfft_norm(1:257);
yfft_dis(yfft_dis==0)=10^-5;
yfft_db=20*log10(yfft_dis);
yfft_sc=96-max(yfft_db);
yfft_scaled=yfft_sc+yfft_db;
X=yfft_scaled;
end