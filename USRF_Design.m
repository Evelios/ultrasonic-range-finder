fs = 2e6;

%% Resonator Filter
f_res = 40e3;
df_res = 2e3;

w0 = f / (fs/2);
bw = df / (fs/2);

[b, a] = iirpeak(w0, bw);

%% Band Stop Elyptic Filter
fp1 = 40e3;
fp2 = 80e3;

df_bs = 4e3;
fs1 = fp1 - df_bs;
fs2 = fp2 + df_bs;

% Normalize frequencies
fp1 = fp1 / (fs/2);
fp2 = fp2 / (fs/2);

fs1 = fs1 / (fs/2);
fs2 = fs2 / (fs/2);

filter_order = 50;

d = fdesign.bandpass('N,Fst1,Fp1,Fp2,Fst2', filter_order, fs1, fp1, fp2, fs2);
hd = design(d, 'equiripple');

freqz(hd);