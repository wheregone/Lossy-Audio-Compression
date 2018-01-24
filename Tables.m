classdef Tables
    properties
        cbnum
        cbound
        subsize
        line
        bark
        hear
        map
        snr
        hann
        scalefactor
        qca
        qcb
    end
    
    methods
        function self = Tables(fs,bitrate)
            FFT_SIZE = 512;
            FOLDER = './tables';
            if fs == 44100
                thrtable = 'D1b';
                crbtable = 'D2b';
            elseif fs == 32000
                thrtable = 'D1a';
                crbtable = 'D2a';
            elseif fs == 48000
                thrtable = 'D1c';
                crbtable = 'D2c';
            end
            
            % Read ISO psychoacoustic model 1 tables containing critical band rates,
            % absolute thresholds and critical band boundaries
            freqband = load(fullfile(FOLDER,thrtable));
            critband = load(fullfile(FOLDER,crbtable));
            
            self.cbnum  = critband(end,1) + 1;
            self.cbound = critband(:,2);
            
            self.subsize = size(freqband,1);
            self.line    = uint16(freqband(:,2));
            self.bark    = freqband(:,3);
            self.hear    = freqband(:,4);
            if bitrate >= 96
                self.hear = self.hear - 12;
            end
            
            self.map = zeros(FFT_SIZE/2+1,1,'uint16');
            for i = 0:self.subsize-2
                for j = self.line(i+1):self.line(i+2)-1
                    self.map(j+1) = i;
                end
            end
            for j = self.line(self.subsize):FFT_SIZE/2
                self.map(j+1) = self.subsize - 1;
            end
            % OBSERVE:
            % figure; plot(0:105,self.line,'Linewidth',2); hold on; plot(self.map,0:256)
            
            % Signal-to-noise ratio table, needed for bit allocation in the ISO psychoacoustic model 1.
            self.snr = [0.00, 7.00,16.00,25.28,31.59,37.75,43.84,49.89,...
                55.93,61.96,67.98,74.01,80.03,86.05,92.01].';
            
            % Hann window.
            self.hann = hann(FFT_SIZE) * sqrt(8/3);
            
            % MPEG-1 Layer 1 scalefactor table.
            self.scalefactor = load(fullfile(FOLDER,'layer1scalefactors'));
            
            % MPEG-1 Layer 1 quantization coefficients.
            self.qca = [0.750000000,  0.875000000,  0.937500000, ...
                0.968750000,  0.984375000,  0.992187500,  0.996093750,  0.998046875, ...
                0.999023438,  0.999511719,  0.999755859,  0.999877930,  0.999938965, ...
                0.999969482,  0.999984741].';
            self.qcb = [-0.250000000, -0.125000000, -0.062500000, ...
                -0.031250000, -0.015625000, -0.007812500, -0.003906250, -0.001953125, ...
                -0.000976563, -0.000488281, -0.000244141, -0.000122070, -0.000061035, ...
                -0.000030518, -0.000015259].';
        end
    end
end

