function [Stored_Maximums, maximums_count] = peakdet(v, Peak_Detection_Sensitivity)
%PEAKDET Detect peaks in a vector
%        [MAXTAB, MINTAB] = PEAKDET(V, DELTA) finds the local
%        maxima and minima ("peaks") in the vector V.
%        A point is considered a maximum peak if it has the maximal
%        value, and was preceded (to the left) by a value lower by
%        DELTA. MAXTAB and MINTAB consists of two columns. Column 1
%        contains indices in V, and column 2 the found values.

Stored_Maximums = [];

% Initialise
Minimum = Inf; 
Maximum = -Inf;
Min_index = NaN; 
Max_index = NaN;

lookformax = 1;

maximums_count = 0;

for i = 1:length(v) %Scan the vector
      sample = v(i); % Grab sample
      % Check if sample sample is a minimum or a maximum. Store its index
      if (sample > Maximum) 
          Maximum = sample; 
          Max_index = i; 
      end
      if (sample < Minimum)
          Minimum = sample; 
          Min_index = i; 
      end
      % This portion wil be alternating (the flag is alternating)
      if lookformax
            if (sample < (Peak_Detection_Sensitivity)*Maximum) % Is sample sample < than factor * maximum?
              Stored_Maximums = [Stored_Maximums ; Max_index Maximum]; % Store the index and value of the maximum
              Minimum = sample; % Now, sample sample will become the new minimum
              Min_index = i;  % As well as its index  
              lookformax = 0; % Turn off flag
              maximums_count = maximums_count + 1;
            end  
      else
            if (sample > (1/Peak_Detection_Sensitivity) * Minimum) % Is sample sample > than factor * maximum?
              %Stored_Minimums = [Stored_Minimums ; Min_index Minimum]; % Store the index and value of the minimum
              Maximum = sample; Max_index = i; % Now, sample sample will become the new maximum
              lookformax = 1; % Turn on flag
            end
      end
end


