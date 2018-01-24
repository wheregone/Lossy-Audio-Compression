clc
clear all

%DECIMATION (PART 2)
[a,fs]=audioread('Damn Son Whered You Find This - MLG Sound Effect (HD).mp3');
a=a(:,1);
inter=1;
deci=8;

% figure
% spectrogram(a)
% 
% f=interp(a,inter);
% b=decimate(f,deci);
% figure
% spectrogram(b)
% % sound(a,fs)
% sound(b,fs/deci*inter)
% audiowrite('decimator.wav',b,fs/deci*inter)


%QUANTIZER (PART3)
% n=2;%bit number
% y = udecode(uencode(a,n),n);
% 
% figure
% plot(y)
% figure
% plot(a)
% c=a-y;
% figure
% plot(c)
% 
% power= mean(y.^2)
% power1= mean(a.^2)
% power_error=mean(c.^2)
% 
% sound(a,fs)
% sound(y,fs)
% audiowrite('quantizer.wav',y,fs)

%TRANSFORM CODING (PART 4)
m=1; %1 if DCT, 0 if DFT
winlen=44100; %block size

if m==0           
          filter=rectwin(winlen);
          row = ceil((winlen));       
          column =1+fix((length(a)-winlen)/winlen);      
          stft = zeros(row, column); % form the stft matrix
          i=0;
          stft=zeros(row,column);
          for c=1:column
              filter2=zeros(1,length(a));
              filter2(i+1:i+winlen)=filter;
              xw = a(i+1:i+winlen).*transpose(filter2(i+1:i+winlen));
              dft_a=fft(xw);
                threshold=max(abs(dft_a))/10;
                dft_a(threshold>abs(dft_a))=0;
                a_new=ifft(dft_a);
              stft(:,c)=dft_a;
              istft(:,c)=a_new;
              i=i+winlen;
          end
          istfta=istft(:,1);
          for c=2:column
              istfta=[istfta ; istft(:,c)];
          end
    error=a(1:length(istfta))-istfta;
    
    figure
    plot(istfta);
    figure
    plot(a);
    figure
    plot(a)
    figure
    plot(error)
    p_ori=mean(a.^2)
    p_sig=mean(istfta.^2)
    p_error=mean(error.^2)
    
%     sound(a,fs)
    sound(istfta,fs)
    
elseif m==1
    filter=rectwin(winlen);
          row = ceil((winlen));       
          column =1+fix((length(a)-winlen)/winlen);      
          stft = zeros(row, column); % form the stft matrix
          i=0;
          stft=zeros(row,column);
          for c=1:column
              filter2=zeros(1,length(a));
              filter2(i+1:i+winlen)=filter;
              xw = a(i+1:i+winlen).*transpose(filter2(i+1:i+winlen));
              dct_a=dct(xw);
                threshold=max(abs(dct_a))/10;
                dct_a(threshold>abs(dct_a))=0;
                a_new=idct(dct_a);
              stdct(:,c)=dct_a;
              istdct(:,c)=a_new;
              i=i+winlen;
          end
          istdcta=istdct(:,1);
          for c=2:column
              istdcta=[istdcta ; istdct(:,c)];
          end
          error=a(1:length(istdcta))-istdcta;
    figure
    plot(istdcta);
    figure
    plot(a)
    figure
    plot(error)
%     sound(a,fs)
    sound(istdcta,fs)
    p_ori=mean(a.^2)
    p_sig=mean(istdcta.^2)
    p_error=mean(error.^2)
end



