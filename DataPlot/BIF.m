% BIF: Used by Main program DataPlot. 
%       This is a set of "Built In Formulas" (BIF) to give the DataPlot
%       user more functionality.
% Written by:	J. van Zyl
% Date:			2015
% Updated:      J. van Zyl
% Last Date:    

function varargout = BIF(varargin)

% Calling the right function
if ~nargin || strncmp(varargin{1},' ',1) % For any invalid calls
 return
else
    fh = str2func(varargin{1});
    Output = '[varargout{1}';
    for I = 1:nargout-1
        Output = [Output, ', varargout{', num2str(I+1), '}'];
    end
    Output = [Output, ']'];
    eval([Output, ' = fh(varargin{2:end});']) % Feed this function all the remaining input arguments
end


% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function  [Freq, Amplitude] = FFT(Data, HP, SampleFreq)
% [C_FFT_DATA, FREQ] = plot_fft(DATA, SAMPLEFREQ) Plots the FFT for DATA
% given the sample frequency SAMPLEFREQ. If no SAMPLEFREQ specified it will
% calculate it from the Time data.
% The function plot the fft and return the results C_FFT_DATA and FREQ
% LP is a "High Pass" filter typically used to throw away the results below
% 1 Hz just to make the  plot more user friendly. Default is zero

if ~nargin || isempty(Data)% Check that there is at least input data
    uiwait(msgbox('No Data  input for function FFT','FFT INPUT'));
    return
end

Samples = length(Data(:,2));    
if nargin < 3 || isempty(SampleFreq) % Check if SampleFreq was given as input
    TimeDiff = (Data(end-1,1)-Data(2,1)); % Answer in seconds & Throw away the beginning and end points in case they are bad values
    SampleFreq = (Samples-2)/TimeDiff;         
end

Data(isnan(Data)) = 0; % Get rid of NaN values - set to zero

Duration = Samples/SampleFreq; % Points/Frequency
NyqSamples = Samples/2
Freq = [0:1/Duration:NyqSamples/Duration];
    
fft_data = fft(Data(:,2));
Amplitude = (abs(fft_data(1:NyqSamples+1)))/NyqSamples;

if nargin < 2 || isempty(HP) % Check if HP was given as input
    return % No High Pass filtering
else
    Pos = find(Freq <= HP)
    Freq = Freq(Pos(end):end);
    Amplitude = Amplitude(Pos(end):end);
end 

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% Calculating PSD using old PSD function
function [Fx_psd, Ax_psd] = PSD(Data, HP, SampleFreq)

if ~nargin || isempty(Data)% Check that there is at least input data
    uiwait(msgbox('No Data  input for function PSD','PSD INPUT'));
    return
end

Samples = length(Data(:,2));    
if nargin < 3 || isempty(SampleFreq) % Check if SampleFreq was given as input
    TimeDiff = (Data(end-1,1)-Data(2,1)); % Answer in seconds & Throw away the beginning and end points in case they are bad values
    SampleFreq = (Samples-2)/TimeDiff;         
end

Data(isnan(Data)) = 0; % Get rid of NaN values - set to zero

[Ax_psd,Fx_psd] = psd(Data(:,2), length(Data), SampleFreq);
Ax_psd = Ax_psd/SampleFreq;

if nargin < 2 || isempty(HP) % Check if HP was given as input
    return % No High Pass filtering
else
    Pos = find(Fx_psd <= HP);
    Fx_psd = Fx_psd(Pos(end):end);
    Ax_psd = Ax_psd(Pos(end):end);
end 

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
function [Data1N, Data2N, Data2R] = IPDat(Data1, Data2)
% Takes two sets of data from the 1553 bus with different lenghts and
% interpolates points according to the time stamps for each set so that 
% you end up with two sets of data that is of equal lenght 
% and that has the same time stamps
% DATA1 becomes DATA1N and DATA2 becomes DATA2N
% DATA2R is DATA2N but reduced so that only the time stamps correlating
% with the original DATA1 is available. This is so that for calculation
% purposes you can run this function on multiple parameters for DATA2 
% while keeping DATA1 always the same parameter. That way all parameters
% will have the same amount of data and time stamps correlating with DATA1

% Check that at least the different times coincide 
if Data1(end,1) > Data2(1,1) && Data2(end,1) > Data1(1,1)
else
    uiwait(msgbox('The Timestamps of the 2 series never overlap','TIME ERROR'));
    Data1N(1:2,1:2) = 0;
    Data2N(1:2,1:2) = 0;
    Data2R(1:2,1:2) = 0;
    return
end

%Get start times to within 1 data point
if Data1(1,1) > Data2(1,1)
    Pos = find(Data2(:,1) > Data1(1,1),1);
    Data2(1:Pos-1,1) = Data1(1,1);  % Pad with data all having the same time stamp
    Data2(1:Pos-1,2) = NaN;         % Padded data is all NaN
elseif Data2(1,1) > Data1(1,1)
    Pos = find(Data1(:,1) > Data2(2,1),1);
    Data1(1:Pos-1,1) = Data2(1,1);  % Pad with NaN data all having
    Data1(1:Pos-1,2) = NaN;         % the same time stamp equals to Data2 timestamp
end % Data now starts at the same time to within 1 data point

LenDat1  = length(Data1(:,1));
LenDat2  = length(Data2(:,1));
MaxLen = LenDat1 + LenDat2;
Data1N(1:MaxLen,1:2) = NaN;
Data2N(1:MaxLen,1:2) = NaN;
Cnt = 0; CntDat1 = 1; CntDat2 = 1; 

while CntDat1 < LenDat1 && CntDat2 < LenDat2 % As long as you haven't reached the end of DATA1 or DATA2 run loop
    Cnt = Cnt+1; % Increment new data counter
    if Data1(CntDat1,1) == Data2(CntDat2,1) % If they have the same time stamps
        Data1N(Cnt,:) = Data1(CntDat1,:);   % Just transfer the data for both 
        Data2N(Cnt,:) = Data2(CntDat2,:);   % to the new parameters
        CntDat1 = CntDat1 + 1; CntDat2 = CntDat2 + 1; % Increment both counters
    elseif Data1(CntDat1,1) > Data2(CntDat2,1)  % If Data1's time stamp is later than Data2
        Data1N(Cnt,1) = Data2(CntDat2,1);       % Data1 gets the Time stamp of Data2 but its data = "NaN"
        Data2N(Cnt,:) = Data2(CntDat2,:);       % Data2's data just gets transfered to the new parameter Data2N
        CntDat2 = CntDat2 + 1;
    elseif Data1(CntDat1,1) < Data2(CntDat2,1)  % If Data1's time stamp is earlier than Data2
        Data2N(Cnt,1) = Data1(CntDat1,1); % Data2N gets the Time stamp of Data1 but its data stays "NaN"
        Data1N(Cnt,:) = Data1(CntDat1,:); % Data1's data just gets transfered to the new parameter Data1N
        CntDat1 = CntDat1 + 1;
    end
end
Data1N = Data1N(1:Cnt,:); % Get rid of all the NaN values at the end of file
Data2N = Data2N(1:Cnt,:); % Get rid of all the NaN values at the end of file

Data1N = InterpDat(Data1N); % Interpolate the data to fill in the NaN spaces with real values
Data2N = InterpDat(Data2N);

Data2R = ReduceData(Data1(:,1), Data2N); % Reduces points for Data2N to the correspond to Data1

% ********************************************************************
function Data = InterpDat(Data)
% Interpolate the data to fill in the NaN spaces with real values
if isnan(Data(1,2))
    Data(1,2) = 0; % Make first data point 0 if it is NaN
end
Len = length(Data(:,1));

for I = 1:Len-1
    if isnan(Data(I,2)) % Check if value is "NaN"
   %     Pos = I - 1 + find(~isnan(Data(I:end,2)),1) % DONT USE - TOOOO SLOW !!
         for N = 0:Len-I % Returns first occurence of a non "NaN" value
             if ~isnan(Data(I+N,2));
                Pos = N+I;
                 break
             end
         end
        StartTime = Data(I-1,1);   
        for J = 1:Pos-I+1 % Calculations have been compressed into one line to save processor time
            Data(I-1+J,2) = (Data(I-1+J,1)-StartTime)*... % Delta time part
                (Data(Pos,2) - Data(I-1,2))/(Data(Pos,1) - StartTime)... % Factor part
                + Data(I-1,2); % Start value + Delta x Factor
        end 
    end
end


% ********************************************************************
function DataN = ReduceData(Time, Data)
% This function reduces the number of Data points from Data to coincide
% with the number of Data points originally in Data1
Len = length(Data(:,1));
Cnt = 1;
DataN(1:length(Time),1:2) = NaN;
for I = 1:Len
    if Time(Cnt) == Data(I,1)
        DataN(Cnt,:) = Data(I,:);
        Cnt = Cnt + 1;
    end     
end

% ***   END function IPDat  ***
% =========================================================================
% =========================================================================
% =========================================================================
function [Spec, freq_vector] = psd(varargin)
%PSD Power Spectral Density estimate.
%   NOTE 1: To express the result of PSD, Pxx, in units of
%           Power per Hertz multiply Pxx by 1/Fs [1].
%
%   NOTE 2: The Power Spectral Density of a continuous-time signal,
%           Pss (watts/Hz), is proportional to the Power Spectral 
%           Density of the sampled discrete-time signal, Pxx, by Ts
%           (sampling period). [2] 
%       
%               Pss(w/Ts) = Pxx(w)*Ts,    |w| < pi; where w = 2*pi*f*Ts

error(nargchk(1,7,nargin,'struct'))
Data = varargin{1};
nfft=varargin{2};
Fs = varargin{3};
window = hanning(nfft);
noverlap = 0;

% compute PSD
window = window(:);
n = length(Data);		    % Number of data points
nwind = length(window); % length of window
if n < nwind            % zero-pad x if it has length less than the window length
    Data(nwind)=0;  n=nwind;
end
% Make sure x is a column vector; do this AFTER the zero-padding 
% in case x is a scalar.
Data = Data(:);		
k = fix((n-noverlap)/(nwind-noverlap));	% Number of windows
                    					% (k = fix(n/nwind) for noverlap=0)
index = 1:nwind;
KMU = k*norm(window)^2;	% Normalizing scale factor ==> asymptotically unbiased

Spec = zeros(nfft,1); 
for i=1:k
    xw = window.*(Data(index));
    index = index + (nwind - noverlap);
    Xx = abs(fft(xw,nfft)).^2;
    Spec = Spec + Xx;
end

% Select first half
if rem(nfft,2),    % nfft odd
    select = (1:(nfft+1)/2)';
else
    select = (1:nfft/2+1)';
end
Spec = Spec(select);
freq_vector = (select - 1)*Fs/nfft;
Spec = Spec*(1/KMU);   % normalize


% =========================================================================
% =========================================================================
function w = hanning(varargin)
%HANNING   Hanning window.
%   HANNING(N) returns the N-point symmetric Hanning window in a column
%   vector.  Note that the first and last zero-weighted window samples
%   are not included.

% Check for trivial order
% [n,w,trivialwin] = check_order(varargin{1});
% if trivialwin 
%     return 
% end

%w = sym_hanning(n);
w = sym_hanning(varargin{1});

% ---------------------------------------------------------------------
function w = sym_hanning(n)
%SYM_HANNING   Symmetric Hanning window. 
%   SYM_HANNING Returns an exactly symmetric N point window by evaluating
%   the first half and then flipping the same samples over the other half.

if ~rem(n,2)
   % Even length window
   half = n/2;
   w = calc_hanning(half,n);
   w = [w; w(end:-1:1)];
else
   % Odd length window
   half = (n+1)/2;
   w = calc_hanning(half,n);
   w = [w; w(end-1:-1:1)];
end

% ---------------------------------------------------------------------
function w = calc_hanning(m,n)
%CALC_HANNING   Calculates Hanning window samples.
%   CALC_HANNING Calculates and returns the first M points of an N point
%   Hanning window.

w = 0.5*(1 - cos(2*pi*(1:m)'/(n+1))); 

% =========================================================================
% =========================================================================
function [n_out, w, trivalwin] = check_order(n_in)
%CHECK_ORDER Checks the order passed to the window functions.
% [N,W,TRIVALWIN] = CHECK_ORDER(N_ESTIMATE) will round N_ESTIMATE to the
% nearest integer if it is not alreay an integer. In special cases (N is [],
% 0, or 1), TRIVALWIN will be set to flag that W has been modified.

w = [];
trivalwin = 0;

if ~(isnumeric(n_in) && isfinite(n_in)),
    error(generatemsgid('InvalidOrder'),'The order N must be finite.');
end

% Special case of negative orders:
if n_in < 0,
   error(generatemsgid('InvalidOrder'),'Order cannot be less than zero.');
end

% Check if order is already an integer or empty
% If not, round to nearest integer.
if isempty(n_in) || n_in == floor(n_in),
   n_out = n_in;
else
   n_out = round(n_in);
   warning(generatemsgid('InvalidOrder'),'Rounding order to nearest integer.');
end

% Special cases:
if isempty(n_out) || n_out == 0,
   w = zeros(0,1);               % Empty matrix: 0-by-1
   trivalwin = 1; 
elseif n_out == 1,
   w = 1;
   trivalwin = 1;   
end
