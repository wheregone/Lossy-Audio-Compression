classdef EncoderParameters
    properties
        bitrate
        nch
        fs
        fscode
        nslots
        copyright
        original
        chmode
        modext
        syncword
        mpegversion
        layer
        crc
        emphasis
        padbit
        rest
        header
        table
    end
    
    methods
        function self = EncoderParameters(fs,nch,bitrate)
            assert(bitrate~=32||nch~=2,'Bitrate of 32 kbits/s is insufficient for encoding of stereo audio.');
            self.bitrate = uint32(bitrate);
            self.nch     = nch;
            self.fs      = fs;
            switch fs
                case 44100
                    self.fscode = uint32(0);
                case 48000
                    self.fscode = uint32(1);
                case 32000
                    self.fscode = uint32(2);
                otherwise
                    error('Unsupported sampling frequency.');
            end
            
            self.nslots = floor(12*bitrate*1000/fs);
            
            self.copyright = uint32(0);
            self.original  = uint32(0);
            
            if self.nch == 1
                self.chmode = uint32(3);
            else
                self.chmode = uint32(2);
            end
            
            self.modext =  uint32(2);
            
            self.syncword    = uint32(2047);
            self.mpegversion = uint32(3);
            self.layer       = uint32(3);
            self.crc         = uint32(1);
            self.emphasis    = uint32(0);
            
            self.padbit = uint32(0);
            self.rest = 0;
            
            self.header = uint32(0);
            self.header = bitor(self.header,bitshift(self.syncword,   21));
            self.header = bitor(self.header,bitshift(self.mpegversion,19));
            self.header = bitor(self.header,bitshift(self.layer,      17));
            self.header = bitor(self.header,bitshift(self.crc,        16));
            self.header = bitor(self.header,bitshift(self.bitrate,     7));
            self.header = bitor(self.header,bitshift(self.fscode,     10));
            self.header = bitor(self.header,bitshift(self.padbit,      9));
            self.header = bitor(self.header,bitshift(self.chmode,      6));
            self.header = bitor(self.header,bitshift(self.modext,      4));
            self.header = bitor(self.header,bitshift(self.copyright,   3));
            self.header = bitor(self.header,bitshift(self.original,    2));
            self.header = bitor(self.header,bitshift(self.emphasis,    0));
            
            self.table = Tables(self.fs,bitrate);
        end
        
        function self = updateheader(self)
            % Update padbit in header for current frame.
            self = self.needpadding();
            if self.padbit
                self.header = bitor(self.header,uint32(512));
            else
                self.header = bitand(self.header,uint32(4294966783));
            end
        end
        
        function self = needpadding(self)
            % To ensure the constant bitrate, for fs=44100 padding is sometimes needed.
            dif = rem(double(self.bitrate)*1000*12,self.fs);
            self.rest = self.rest - dif;
            if self.rest < 0
                self.rest = self.rest + self.fs;
                self.padbit = uint32(1);
            else
                self.padbit = uint32(0);
            end
        end
    end
end

