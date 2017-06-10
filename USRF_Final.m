clear;
%% Data Sampling
disp('Collecting Data');

delete(instrfind);

s = serial('Com3');
set(s,'DataBits',8);
set(s,'StopBits',1);
set(s,'BaudRate',9600);
set(s,'Parity','none');

fopen(s);

rawdata = zeros(1, 20000);
timestamps = zeros(1, 20000);
i = 1;

value = 0;
running = 1;

fprintf(s, 's'); % Send start message to microcontroller

while running
    value = fgetl(s);
    if ~strcmp(cellstr(value), 'END');
        if ~strcmp(value, '')
            rawdata(i) = str2double(value);
            value = fgetl(s);
            timestamps(i) = str2double(value);
            i = i + 1;
        end
    else
        running = 0;
    end
end

micsPulse = str2num(fgetl(s));  % in micros
micsBurst = str2num(fgetl(s));  % in micros
windowTime = str2num(fgetl(s)); % in micros
numSamples = str2num(fgetl(s));

fclose(s);

delete(s);

%% Data Processing
disp('Processing Data');

data = rawdata(~isnan(nonzeros(rawdata))); % Remove zeros and NAN's
timestamps = timestamps(~isnan(nonzeros(timestamps))); % Remove zeros and NAN's
avg = mean(data);
data = data - avg;

data = resample(data, timestamps);

% Filter Design
windowTimeSecs = (windowTime / 1000000) - (micsPulse / 1000000);
fs = numSamples / windowTimeSecs;
%fs = 600000; % 600kHz
samplePeriod = 1/fs;

resonantFrequency = 40000;
bandWidth = 2000;

% Resonant
w0 = resonantFrequency / (fs/2);
bw = bandWidth / (fs/2);
[b, a] = iirpeak(w0, bw);

filtered = filter(b, a, data);

n = linspace(0, fs, length(data));
rawFreq = fft(data);

filteredFreq = fft(filtered);

% Burst Patterns
burstLength = 0.00050;
signalFreq = 40000;
samplesInBurst = ceil(burstLength / samplePeriod);

% Single Pulse Burst
% x = 1:samplesInBurst;
% burstPattern = sin(2 * pi * x * signalFreq / fs);

% Linear Step
burstPattern = zeros(1, samplesInBurst);
samples_per_sequence = ceil(samplesInBurst / 10);
for i = 1:10
	x = 1:samples_per_sequence;
	stepSection = sin(2 * pi * x * (41000 - i * 200) / fs);
	
	start_index = 1 + (i-1) * samples_per_sequence;
	end_index = i * samples_per_sequence;
	burstPattern(start_index:end_index) = stepSection;
end

% Costas Array
% costas_array = [2 4 8 5 10 9 7 3 6 1];
% burstPattern = zeros(1, samplesInBurst);
% samples_per_sequence = ceil(samplesInBurst / 10);
% 
% for i = 1:10
% 	x = 1:samples_per_sequence;
%     costas_index = costas_array(i);
%     
% 	stepSection = sin(2 * pi * x * (39000 + costas_index * 200) / fs);
% 	
% 	start_index = 1 + (costas_index-1) * samples_per_sequence;
% 	end_index = costas_index * samples_per_sequence;
% 	burstPattern(start_index:end_index) = stepSection;
% end

filteredPattern = filter(b, a, burstPattern);

correlation = xcorr(filtered, burstPattern);
% correlation = xcorr(filtered, filteredPattern);
correlation = correlation((length(data)):length(correlation));% - length(burstPattern)));

[corr, sampleDistance] = max(abs(correlation));

speedOfSoundInAir = 334;% m/s
travelTime = sampleDistance * samplePeriod + (micsPulse / 1000000) - (micsBurst / 1000000)/2;
distance = round( travelTime * speedOfSoundInAir / 2, 3);

%% Graphing
disp('Plotting Data');

if corr > 0.05
    fprintf(['Correlation Coefficient of ', num2str(corr,3), '\n']);
    fprintf(['There is an object ', num2str(distance), ' m or ', num2str(distance * 3.28084), ' ft away.\n']); 
else
    fprintf(['No signal found. Highest correlation: ', num2str(corr,3), '\n']);
end

% figure;
% subplot(3, 1, 1);
% plot(data);
% title('Unbiased Input Data');
% ylabel('Volts (V)');
% xlabel('Samples');
% subplot(3, 1, 2);
% plot(filtered);
% title('Filtered Data');
% ylabel('Volts (V)');
% xlabel('Samples');
% subplot(3, 1, 3);
% plot(correlation);
% title('Cross Correlation');
% ylabel('Corellation Coefficient');
% xlabel('Samples');
% 
% figure;
% subplot(2, 1, 1);
% plot(n, abs(rawFreq));
% title('Frequency Domain of Raw Data');
% ylabel('Num Points');
% xlabel('Frequency');
% subplot(2, 1, 2);
% plot(n, abs(filteredFreq));
% title('Frequency Domain of Filtered');
% ylabel('Num Points');
% xlabel('Frequency');
% 
% figure;
% nfft = 128;
% noverlap = nfft/2;
% hwindow = blackman(nfft);
% subplot(2, 1, 1);
% spectrogram(data,hwindow,noverlap,nfft,fs);
% title('Spectrogram of raw data');
% subplot(2, 1, 2);
% spectrogram(filtered,hwindow,noverlap,nfft,fs);
% title('Spectrogram of filtered data');