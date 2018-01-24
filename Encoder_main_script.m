function Encoder_main_script()
inwavfile = 'singing_44100.wav';
outmp3file = 'singing_44100.mp3';
bitrate = 96;

N_SUBBANDS = 32;
FRAMES_PER_BLOCK = 12;
SHIFT_SIZE = 32;

assert(~exist(outmp3file,'file'),'The file "%s" exists.',outmp3file);

input_buffer = WavRead(inwavfile);
params = EncoderParameters(input_buffer.fs, input_buffer.nch, bitrate);

baseband_filter = prototype_filter();
subband_samples = zeros(params.nch, N_SUBBANDS, FRAMES_PER_BLOCK);

while input_buffer.nprocessed_samples < input_buffer.nsamples
    disp(input_buffer.nprocessed_samples); %%%%%%%%
    for frm = 1:FRAMES_PER_BLOCK
        [input_buffer,samples_read] = input_buffer.read_samples(SHIFT_SIZE);
        if samples_read < SHIFT_SIZE
            for ch = 1:params.nch
                input_buffer.audio{ch} = input_buffer.audio{ch}.insert(zeros(SHIFT_SIZE-samples_read,1));
            end
        end
        
        for ch = 1:params.nch
            subband_samples(ch,:,frm) = subband_filtering(input_buffer.audio{ch}.reversed(), baseband_filter);
        end
    end
    
    % Declaring arrays for keeping table indices of calculated scalefactors and bits allocated in subbands.
    % Number of bits allocated in subband is either 0 or in range [2,15].
    scfindices = zeros(params.nch, N_SUBBANDS);
    subband_bit_allocation = zeros(params.nch, N_SUBBANDS);
    
    % Finding scale factors, psychoacoustic model and bit allocation calculation for subbands. Although 
    % scaling is done later, its result is necessary for the psychoacoustic model and calculation of 
    % sound pressure levels.
    for ch = 1:params.nch
        scfindices(ch,:) = get_scalefactors(subband_samples(ch,:,:), params.table.scalefactor);
        subband_bit_allocation(ch,:) = psycho_model1(input_buffer.audio{ch}.ordered(), params, scfindices);
    end
    
    subband_samples_quantized = zeros(size(subband_samples));
    for ch = 1:params.nch
        for sb = 1:N_SUBBANDS
            if subband_bit_allocation(ch,sb) >= 2
                QCa = params.table.qca(subband_bit_allocation(ch,sb)-1);
                QCb = params.table.qcb(subband_bit_allocation(ch,sb)-1);
            else   %THIS SHOULD NOT BE THE CASE ?? If this else does not exist, then an exception occurs.
                % Is this a bug??
                QCa = params.table.qca(end+subband_bit_allocation(ch,sb)-1);   %!!!!!!!!!!!!!!???
                QCb = params.table.qcb(end+subband_bit_allocation(ch,sb)-1);   %!!!!!!!!!!!!!!???
            end
            scf = params.table.scalefactor(scfindices(ch,sb)+1);
            ba = subband_bit_allocation(ch,sb);
            for ind = 1:FRAMES_PER_BLOCK
                subband_samples_quantized(ch,sb,ind) = quantization(subband_samples(ch,sb,ind), scf, ba, QCa, QCb);
            end
        end
    end
    i = subband_samples_quantized < 0;
    subband_samples_quantized(i) = subband_samples_quantized(i) + 2^32;
    
    % Forming output bitsream and appending it to the output file.
    params = bitstream_formatting(outmp3file,params,subband_bit_allocation,scfindices,subband_samples_quantized);
end
end



function sfactorindices = get_scalefactors(sbsamples,sftable)
N_SUBBANDS = 32;
% Calculate scale factors for subbands. Scale factor is equal to the smallest number in the table
% greater than all the subband samples in a particular subband. Scalefactor table indices are returned.
sbsamples_shape = size(sbsamples);   sbsamples_shape = sbsamples_shape(1:end-1);
sfactorindices = zeros(sbsamples_shape);
sbmaxvalues = max(abs(sbsamples), [], 3);   %Absolute maximum of the 12 samples in each subband
for sb = 1:N_SUBBANDS
    i = 0;
    while sftable(i+2) > sbmaxvalues(sb)
        i = i + 1;
    end
    sfactorindices(sb) = i;
end
% OBSERVE:
% x = squeeze(sbsamples(1,:,:)); figure; plot(abs(x)); hold on; plot(sbmaxvalues,'Linewidth',3); plot(plot(sftable(sfactorindices+1)))
end