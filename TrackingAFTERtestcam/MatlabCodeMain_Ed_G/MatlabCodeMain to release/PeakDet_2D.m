% This function removes "blobs" and leaves peaks

function [A_peaks, There_Are_Peaks] = PeakDet_2D(A, Peak_Detection_Sensitivity,...
                                                FFT_Vert_Size, FFT_Horz_Size)

%--------------------------------------------------------------------------
% Convertir matriz --> Vector
x_hor = reshape(A.', 1, FFT_Vert_Size * FFT_Horz_Size);  %Correcto
Salida_Hor = 0*x_hor; % Vector vacio

% Correr algoritmo en sentido horizontal
[Stored_Maximums, maximums_count] = peakdet(x_hor, Peak_Detection_Sensitivity);
if( ~isempty(Stored_Maximums) )
        There_Are_Peaks_H = 1;
        Salida_Hor( Stored_Maximums(:,1) ) = Stored_Maximums(:,2); %Copiar solo los puntos maximos Hor.
        % Convertir de nuevo a matriz
        Salida_Hor = reshape(Salida_Hor, FFT_Horz_Size, FFT_Vert_Size).' ; %Correcto
else
        There_Are_Peaks_H = 0;    
        Salida_Hor = reshape(Salida_Hor, FFT_Horz_Size, FFT_Vert_Size).' ; %Vacio
end

%--------------------------------------------------------------------------
% Convertir matriz --> Vector
x_ver = reshape(A, 1, FFT_Vert_Size * FFT_Horz_Size);  %Correcto
Salida_Ver = 0*x_ver; % Vector vacio

% Correr algoritmo en sentido vertical
%[Stored_Maximums, Stored_Minimums] = peakdet(x_ver, Peak_Detection_Sensitivity);
[Stored_Maximums, maximums_count] = peakdet(x_ver, Peak_Detection_Sensitivity);

if( ~isempty(Stored_Maximums) )
        There_Are_Peaks_V = 1;    
        Salida_Ver( Stored_Maximums(:,1) ) = Stored_Maximums(:,2); %Copiar solo los puntos maximos Hor.
        % Convertir de nuevo a matriz
        Salida_Ver = reshape(Salida_Ver, FFT_Vert_Size, FFT_Horz_Size) ; %Correcto
else
        There_Are_Peaks_V = 0;    
        Salida_Ver = reshape(Salida_Ver, FFT_Vert_Size, FFT_Horz_Size) ; %Vacio
end


if ( There_Are_Peaks_H | There_Are_Peaks_H )
    There_Are_Peaks = 1;        
    A_peaks = [sqrt(Salida_Hor .* Salida_Ver)];    
else
    There_Are_Peaks = 0;    
    A_peaks = 0 * A; 
end


return




