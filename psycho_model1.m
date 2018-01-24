function subband_bit_allocation = psycho_model1(samples, params, sfindices)
% Psychoacoustic model as described in ISO/IEC 11172-3, Annex D.1.

FFT_SIZE   = 512;
N_SUBBANDS = 32;
SUB_SIZE = FFT_SIZE/2/N_SUBBANDS;

DBMIN = -200;

UNSET  = 0;
TONE   = 1;
NOISE  = 2;
IGNORE = 3;

table = params.table;

X = scaled_fft_db(samples);

scf = table.scalefactor(sfindices+1);   scf = reshape(scf,size(sfindices));
subband_spl = zeros(N_SUBBANDS,1);
for sb = 0:N_SUBBANDS-1
    subband_spl(sb+1) = max( X(2+sb*SUB_SIZE : 1+sb*SUB_SIZE+SUB_SIZE) );
    subband_spl(sb+1) = max(subband_spl(sb+1), 20*log10(scf(1,sb+1)*32768)-10);
end
% OBSERVE:
% x = repmat(subband_spl.',SUB_SIZE,1); figure; plot(X(2:end)); hold on; plot(x(:));

peaks = [];
for i = 3:FFT_SIZE/2 - 7
    if X(i+1) >= X(i+2) && X(i+1)>X(i)
        peaks(end+1) = i; %#ok<AGROW>
    end
end
% OBSERVE:
% figure; plot(X); hold on; plot(peaks+1,X(peaks+1),'.','MarkerSize',15);

% determining tonal and non-tonal components
tonal = TonalComponents(X);
tonal.flag(1:3) = IGNORE;

for k = peaks
    is_tonal = true;
    if k > 2 && k < 63
        testj = [-2,2];
    elseif k >= 63 && k < 127
        testj = [-3,-2,2,3];
    else
        testj = [-6,-5,-4,-3,-2,2,3,4,5,6];
    end
    for j = testj
        if tonal.spl(k+1) - tonal.spl(k+j+1) < 7
            is_tonal = false;
            break;
        end
    end
    if is_tonal
        tonal.spl(k+1) = add_db(tonal.spl(k:k+2));
        tonal.flag(k+1+(testj(1):testj(end))) = IGNORE;
        tonal.flag(k+1) = TONE;
        tonal.tonecomps(end+1) = k;
    end
end
% OBSERVE:
% figure; plot(X,'r'); hold on; plot(tonal.spl,'b'); plot(tonal.tonecomps+1,tonal.spl(tonal.tonecomps+1),'r.','MarkerSize',15);


% non-tonal components for each critical band
for i = 1:table.cbnum-1
    weight = 0;
    msum = DBMIN;
    for j = 1+table.cbound(i):table.cbound(i+1)
        if tonal.flag(j) == UNSET   %In the original python code, this was i instead of j! However, I could not distinct two resulting files by listening.
            msum = add_db([tonal.spl(j),msum]);
            weight = weight + 10^(tonal.spl(j)/10)*(table.bark(1+table.map(j))-i+1);
        end
    end
    if msum > DBMIN
        index  = weight/10^(msum/10);
        center = table.cbound(i) + floor(index*(table.cbound(i+1) - table.cbound(i)));
        if tonal.flag(center+1) == TONE
            center = center + 1;
        end
        tonal.flag(center+1) = NOISE;
        tonal.spl(center+1) = msum;
        tonal.noisecomps(end+1) = center;
    end
end
% OBSERVE:
% figure; plot(X,'r'); hold on; plot(tonal.tonecomps+1,tonal.spl(tonal.tonecomps+1),'r.','MarkerSize',15); plot(tonal.noisecomps+1,tonal.spl(tonal.noisecomps+1),'k.','MarkerSize',15);

% decimation of tonal and non-tonal components
% under the threshold in quiet
for i = 0:numel(tonal.tonecomps)-1
    if i >= numel(tonal.tonecomps)
        break;
    end
    k = tonal.tonecomps(i+1);
    if tonal.spl(k+1) < table.hear(table.map(k+1)+1)
        tonal.tonecomps(i+1) = [];
        tonal.flag(k+1) = IGNORE;
        i = i - 1; %#ok<FXSET>
    end
end

for i = 0:numel(tonal.noisecomps)-1
    if i >= numel(tonal.noisecomps)
        break;
    end
    k = tonal.noisecomps(i+1);
    if tonal.spl(k+1) < table.hear(table.map(k+1)+1)
        tonal.noisecomps(i+1) = [];
        tonal.flag(k+1) = IGNORE;
        i = i - 1; %#ok<FXSET>
    end
end


% decimation of tonal components closer than 0.5 Bark
for i = 0:numel(tonal.tonecomps)-2
    if i >= numel(tonal.tonecomps)-1
        break;
    end
    this = tonal.tonecomps(i+1);
    next = tonal.tonecomps(i+2);
    if table.bark(table.map(this+1)+1) - table.bark(table.map(next+1)+1) < 0.5
        if tonal.spl(this+1)>tonal.spl(next+1)
            tonal.flag(next+1) = IGNORE;
            tonal.tonecomps(tonal.tonecomps==next) = [];
        else
            tonal.flag(this+1) = IGNORE;
            tonal.tonecomps(tonal.tonecomps==this) = [];
        end
    end
end



% individual masking thresholds
masking_tonal = {};
masking_noise = {};

for i = 0:table.subsize-1
    masking_tonal = [masking_tonal {[]}]; %#ok<AGROW>
    zi = table.bark(i+1);
    for j = tonal.tonecomps
        zj = table.bark(table.map(j+1)+1);
        dz = zi - zj;
        if dz >= -3 && dz <= 8
            avtm = -1.525 - 0.275 * zj - 4.5;
            if dz >= -3 && dz < -1
                vf = 17 * (dz + 1) - (0.4 * X(j+1) + 6);
            elseif dz >= -1 && dz < 0
                vf = dz * (0.4 * X(j+1) + 6);
            elseif dz >= 0 && dz < 1
                vf = -17 * dz;
            else
                vf = -(dz - 1) * (17 - 0.15 * X(j+1)) - 17;
            end
            masking_tonal{i+1} = [masking_tonal{i+1}, X(j+1)+vf+avtm];
        end
    end
end

for i = 0:table.subsize-1
    masking_noise = [masking_noise {[]}]; %#ok<AGROW>
    zi = table.bark(i+1);
    for j = tonal.noisecomps
        zj = table.bark(table.map(j+1)+1);
        dz = zi - zj;
        if dz >= -3 && dz <= 8
            avnm = -1.525 - 0.175 * zj - 0.5;
            if dz >= -3 && dz < -1
                vf = 17 * (dz + 1) - (0.4 * X(j+1) + 6);
            elseif dz >= -1 && dz < 0
                vf = dz * (0.4 * X(j+1) + 6);
            elseif dz >= 0 && dz < 1
                vf = -17 * dz;
            else
                vf = -(dz - 1) * (17 - 0.15 * X(j+1)) - 17;
            end
            masking_noise{i+1} = [masking_noise{i+1}, X(j+1)+vf+avnm];
        end
    end
end


% global masking thresholds
masking_global = [];
for i = 1:table.subsize
    maskers = [table.hear(i), masking_tonal{i}, masking_noise{i}];
    masking_global = [masking_global, add_db(maskers)]; %#ok<AGROW>
end
% figure; plot(0:numel(X)-1,X); hold on; plot(table.line+1,masking_global);
% figure; plot(0:numel(tonal.spl)-1,tonal.spl); hold on; plot(table.line+1,masking_global);


% minimum masking thresholds
mask = zeros(N_SUBBANDS,1);
for sb = 0:N_SUBBANDS-1
    first = table.map(sb*SUB_SIZE+1);
    after_last = table.map((sb+1)*SUB_SIZE) + 1;
    mask(sb+1) = min(masking_global(first+1:after_last));
end


% signal-to-mask ratio for each subband
smr = subband_spl - mask;


subband_bit_allocation = smr_bit_allocation(params, smr);
end




function x = add_db(values)
% Add power magnitude values.
EPS = 1e-6;
powers = 10.^(values/10);
x = 10*log10(sum(powers)+EPS);
end



function bit_allocation = smr_bit_allocation(params,smr)
% Calculate bit allocation in subbands from signal-to-mask ratio.
N_SUBBANDS =  32;
SLOT_SIZE  =  32;
FRAMES_PER_BLOCK = 12;
INF = 123456;

bit_allocation = zeros(N_SUBBANDS,1);
bits_header = 32;
bits_alloc  = 4 * N_SUBBANDS * params.nch;
bits_available = (params.nslots + params.padbit) * SLOT_SIZE - (bits_header + bits_alloc);
bits_available = bits_available / params.nch;

if bits_available <= 2 * FRAMES_PER_BLOCK + 6
    error('Insufficient bits for encoding.');
end

snr = params.table.snr;
mnr = snr(bit_allocation(:)+1) - smr;

while bits_available >= FRAMES_PER_BLOCK
    [~,subband] = min(mnr);
    
    if bit_allocation(subband) == 15
        mnr(subband) = INF;
        continue;
    end
    
    if bit_allocation(subband) == 0
        bits_needed = 2 * FRAMES_PER_BLOCK + 6;
    else
        bits_needed = FRAMES_PER_BLOCK;
    end
    
    if bits_needed > bits_available
        mnr(subband) = INF;
        continue;
    end
    
    if bit_allocation(subband) == 0
        bit_allocation(subband) = 2;
    else
        bit_allocation(subband) = bit_allocation(subband) + 1;
    end
    
    bits_available = bits_available - bits_needed;
    mnr(subband) = snr(bit_allocation(subband)) - smr(subband);
end
end