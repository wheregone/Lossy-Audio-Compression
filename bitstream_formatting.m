function params = bitstream_formatting(filename, params, allocation, scalefactor, sample)
% Form a MPEG-1 Layer 1 bitstream and append it to output file.

N_SUBBANDS = 32;
FRAMES_PER_BLOCK = 12;

buffer = BitStream((params.nslots + params.padbit) * 4);

buffer = buffer.insert(params.header, 32);
params = params.updateheader();

for sb = 1:N_SUBBANDS
    for ch = 1:params.nch
        buffer = buffer.insert(max(allocation(ch,sb)-1, 0), 4);
    end
end

for sb = 1:N_SUBBANDS
    for ch = 1:params.nch
        if allocation(ch,sb) ~= 0
            buffer = buffer.insert(scalefactor(ch,sb),6);
        end
    end
end

for s = 1:FRAMES_PER_BLOCK
    for sb = 1:N_SUBBANDS
        for ch = 1:params.nch
            if allocation(ch,sb) ~= 0
                buffer = buffer.insert(sample(ch,sb,s), allocation(ch,sb), true);
            end
        end
    end
end

fp = fopen(filename, 'ab+');
fwrite(fp,buffer.data);
fclose(fp);
% disp(numel(buffer.data));
end
