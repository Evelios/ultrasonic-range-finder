sequences = 10;
start_frequency = 10;
step_frequency = 10;
max_frequency = sequences * step_frequency;

samples_per_sequence = 1000;
samples_per_burst = sequences * samples_per_sequence;

burst = [];

%% Single Frequency Single Pulse
    
burst = zeros(1, samples_per_burst);

x = 1:samples_per_sequence;

sequence_frequency = start_frequency;
sequence_period = 1 / sequence_frequency;
sequence = sin(sequence_period * x);

burst(1:samples_per_sequence) = sequence;

figure;
plot(burst);
title('Single Frequency Signle Pulse');
xlabel('Samples (n)');
ylabel('Amplitude');

%% Single Frequency Multiple Pulse

burst = zeros(1, samples_per_burst);

for m = 1:sequences

    if ( mod(m, 2) == 1 )
        x = 1:samples_per_sequence;

        sequence_frequency = start_frequency;
        sequence_period = 1 / sequence_frequency;
        sequence = sin(sequence_period * x);

        start_index = 1 + (m-1) * samples_per_sequence;
        end_index = m * samples_per_sequence;
        burst(start_index:end_index) = sequence;
    end
end

figure;
plot(burst);
title('Single Frequency Multiple Pulse');
xlabel('Samples (n)');
ylabel('Amplitude');

%% Linear Frequency Modulation

y = 1:samples_per_burst;
burst = exp(j*y.*y);

figure;
plot(real(burst));
title('Linear Frequency Modulation');
xlabel('Samples (n)');
ylabel('Amplitude');

%% Stepped Frequency Modulation

burst = zeros(1, samples_per_burst);

for m = 1:sequences
    x = 1:samples_per_sequence;
    
    sequence_frequency = start_frequency + (m-1) * step_frequency;
    sequence_period = 1 / sequence_frequency;
    sequence = sin(sequence_period * x);
    
    start_index = 1 + (m-1) * samples_per_sequence;
    end_index = m * samples_per_sequence;
    burst(start_index:end_index) = sequence;
end

figure;
plot(burst);
title('Stepped Frequency Modulation');
xlabel('Samples (n)');
ylabel('Amplitude');

%% Costas Array Modulation

costas_array = [2 4 8 5 10 9 7 3 6 1];

for m = 1:sequences
    x = 1:samples_per_sequence;

    costas_index = costas_array(m);
    
    sequence_frequency = start_frequency + (costas_index-1) * step_frequency;
    sequence_period = 1 / sequence_frequency;
    sequence = sin(sequence_period * x);

    start_index = 1 + (m-1) * samples_per_sequence;
    end_index = m * samples_per_sequence;
    burst(start_index:end_index) = sequence;
end

figure;
plot(burst);
title('Costas Array Frequency Modulation');
xlabel('Samples (n)');
ylabel('Amplitude');