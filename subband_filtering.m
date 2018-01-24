function s = subband_filtering(x,h)

d=x.*h;
c=zeros(1,64);
for q=1:64;
    for p=1:8
        c(q)=c(q)+(-1)^(p-1)*d((64*(p-1)+q-1)+1);
    end
end

s=zeros(1,32);
for k=1:32
    for q=1:64
    s(k)=s(k)+cos(pi/64*(2*k-1)*(q-17))*c(q);
    end
end