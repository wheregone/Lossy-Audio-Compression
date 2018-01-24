classdef WavRead
    properties
        filename
        fs
        nch
        nbits
        nsamples
        nprocessed_samples
        audio
        data
        pos
    end
    
    methods
        function self = WavRead(filename)
            FRAME_SIZE = 512;
            info = audioinfo(filename);
            self.filename = info.Filename;
            self.fs = info.SampleRate;
            self.nch = info.NumChannels;
            self.nbits = info.BitsPerSample;
            self.nsamples = info.TotalSamples;
            self.nprocessed_samples = 0;
            self.audio = cell(1,self.nch);
            for ch = 1:self.nch
                self.audio{ch} = CircBuffer(FRAME_SIZE);
            end
            assert(self.nch==1,'Not sure yet how to set multichannel case');
            self.data = audioread(filename);
            self.pos = 0;
        end
        
        function [self,s] = read_samples(self,nsamples)
            p = self.nprocessed_samples;
            if p + nsamples <= size(self.data,1)
                frame = self.data(p+(1:nsamples),:);
            else
                frame = self.data(p+1:end,:);
            end
            for ch = 1:self.nch
                self.audio{ch} = self.audio{ch}.insert(frame(:,ch));
            end
            self.nprocessed_samples = self.nprocessed_samples + size(frame,1);
            s = size(frame,1);
        end
    end
end

