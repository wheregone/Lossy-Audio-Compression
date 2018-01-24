classdef CircBuffer    
    properties
        size
        pos
        samples
    end
    
    methods
        function self = CircBuffer(N)
            self.size = N;
            self.pos = 0;
            self.samples = zeros(N,1);
        end
        
        function self = insert(self,frame)
            length = numel(frame);
            if self.pos + length <= self.size
                self.samples(self.pos+(1:length)) = frame;
            else
                overhead = length - (self.size - self.pos);
                self.samples(1+self.pos:self.size) = frame(1:end-overhead);
                self.samples(1:overhead) = frame(end-overhead+1:end);
            end
            self.pos = self.pos + length;
            self.pos = mod(self.pos,self.size);
        end
        
        function x = ordered(self)
            x = [self.samples(self.pos+1:end); self.samples(1:self.pos)];
        end
        
        function x = reversed(self)
            x = [self.samples(self.pos:-1:1); self.samples(end:-1:self.pos+1)];
        end
    end
end

