% [deviation, frex, real_amp] = ARSurrSpectByPs(data, srate, n_surrogates, pad)
% 
%   Inputs:
%       data         = the behavioural timecourses. Time x participants (required)
%       srate        = the sample rate of the data (required)
%       n_surrogates = the number of surrogate spectra to use to estimate the 
%                      aperiodic component of the data [default: 1000]
%       pad_to       = the length to pad the signal to (in samples) [default: empty (i.e., none)]
%
%   Outputs:
%       deviation    = the difference between real amplitude and the mean of 
%                      surrogate amplitudes. This is what you perform your
%                      statistical tests on. Frequency x participants
%       frex         = frequency
%       real_amp     = the amplitude spectrum of the real data. Frequency x
%                      participants
%
%   Citation: Harris, A. M., & Beale, H. A. (2024). Detecting behavioural oscillations 
%             with increased sensitivity: A modification of Brookshire's (2022) 
%             AR-surrogate method. bioRxiv, 2024-08.
%
%   License:  This work is licensed under the Creative Commons Attribution 4.0 license (CC BY 4.0). 
%             To view a copy of this license, visit: https://creativecommons.org/licenses/by/4.0/ 
%
function [deviation, frex, real_amp] = ARSurrSpectByPs(data, srate, n_surrogates, pad)
    
    if nargin < 3 || isempty(n_surrogates)
        n_surrogates = 1000;
    end
    
    if nargin < 4
        pad = [];
    end
    
    num_ps = size(data,2);
    num_frex = floor(size(data,1)/2);

    mdl = arima(1, 0, 0);

    deviation = nan(num_frex, num_ps);
    real_amp = deviation;
    
    for p = 1:num_ps
        %fit the AR(1) model
        estMdl = estimate(mdl, data(:,p), 'Display', 'off');
    
        %generate new data
        surr = simulate(estMdl, size(data,1), 'NumPaths', n_surrogates);
        
        % calculate spectra
        [real_amp(:,p), frex] = fftSpect(data(:,p)', srate, pad);
        surr_amp = mean(fftSpect(surr',srate, pad),1);
    
        % record difference
        deviation(:,p) = real_amp(:,p)' - surr_amp;
    end
end

function [spectrum,frex] = fftSpect(data,samplingRate,pad_to)
    % Inputs:
    % data = trials x time
    % srate
    % pad_to (in samples)
    
    if pad_to
        len = pad_to;
    else
        len = size(data,2);
        pad_to = [];
    end
    frex = samplingRate*(0:(len/2))/len;
    data = bsxfun(@minus, data, mean(data,2)); % mean subtraction is required for zero-padding
    comp_out = fft(double(data),pad_to,2);
    amps = (abs(comp_out/len)*2);
    
    frex = frex(2:end);
    
    if mod(len,2)
        spectrum = amps(:,2:ceil(len/2));
    else
        spectrum = amps(:,2:(len/2)+1);
    end

end