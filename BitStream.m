classdef BitStream
    % Form an array of bytes and fill it as a bitstream.
    
    properties
        size
        pos
        data
    end
    
    methods
        function self = BitStream(size)
            self.size = size;
            self.pos  = 0;
            self.data = zeros([size 1],'uint8');
        end
        
        function self = insert(self, data, nbits, invmsb)
            % Insert lowest nbits of data in OutputBuffer.
            if nargin < 4,   invmsb = false;   end
            
            if invmsb
                data = self.invertmsb(data,nbits);
            end
            datainbytes = self.splitinbytes(data, nbits, bitand(self.pos,7));
            ind = floor(self.pos/8);
            for byte = datainbytes
                if ind >= self.size
                    break;
                end
                self.data(ind+1) = bitor(self.data(ind+1),byte);
                ind = ind + 1;
            end
            self.pos = self.pos + nbits;
        end
    
        function x = maskupperbits(~,data,nbits)
            % Set all bits higher than nbits to zero.
            mask = double(bitand(bitshift(uint64(4294967295),nbits),4294967295));
            mask = -mask - 1;   %for integers, ~x is equivalent to (-x) - 1
            mask = mask + intmax('uint32') + 1;
            x = bitand(data,mask);
        end
  
  
        function x = invertmsb(~, data, nbits)
            % Invert MSB of data, data being only lowest nbits.
            mask = 1*2^(nbits-1);
            x = bitxor(data,mask);
        end


        function datainbytes = splitinbytes(self,data,nbits,pos)
            % Split input data in bytes to allow insertion in buffer by OR operation.
            data = self.maskupperbits(data, nbits);
            shift = 8 - bitand(nbits,7) + 8 - pos;
            shift = bitand(shift,7);
            data  = bitshift(data,shift);
            nbits = nbits + shift;
            datainbytes = [];
            loopcount = 1 + floor((nbits-1)/8);
            for i = 1:loopcount
                datainbytes = [bitand(data,255) datainbytes]; %#ok<AGROW>
                data = bitshift(data,-8);
            end
            datainbytes = uint8(datainbytes);
        end
    end
end
