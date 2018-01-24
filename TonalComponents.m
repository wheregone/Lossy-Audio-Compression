classdef TonalComponents
    % Marking of tonal and non-tonal components in the psychoacoustic model.
    
    properties
        spl
        flag
        tonecomps
        noisecomps
    end
    
    methods
        function self = TonalComponents(X)
            self.spl = X;
            self.flag = zeros(size(X));
            self.tonecomps  = [];
            self.noisecomps = [];
        end
    end
end

