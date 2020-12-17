%%
% Simulation system composition: signal input (random bitstream), OFDM modulation, simulation channel transmission, OFDM demodulation, signal output
% Simulation analysis content: Bit error rate under different SNR conditions is calculated according to input and output bitstreams.
% and draw the curve for modulation requirements:
% The subcarrier interval of % OFDM modulation is 15KHz
% cycle prefix length, number of subcarriers, pilot frequency interval and OFDM symbol number are adjustable,
% Each subcarrier is modulated using QPSK
% No spread spectrum technology is used, no up-conversion is performed by multiplying the carrier wave, and no grooming pilot performance is tested
%%
clc;
clear ;
close ;
tic;
disp("simulation start");
%% Parameter Settings
sta_num = 5;%The simulation number of times
SNR = -4:1:25; 
number_carriers = 100;       %The subcarrier number
cp_LEN = 15;           %Cyclic prefix length
M = 8;                    %QPSK，M=4
is__pilot_k = 1;           %The massive pilot
q = 8;                    %fs = q*B_baseband;
pilot__interval = 4;       %Pilot frequency interval
number_ofdm_symbol = 99;     %Number of ofdm symbols
%% The above parameters are adjustable
f_delta = 15e3;
n = 1;
while(true)
%     if(2^n >= number_carriers / pilot__interval * (pilot__interval +1))
    if(2^n >= number_carriers )
        num_fft = 2^n;
        break;
    end
    n = n+1;
end
number_bit = number_carriers * number_ofdm_symbol * log2(M);%Binary bit number
B_baseband = number_carriers * f_delta;                  %Baseband width
fs = q*B_baseband;                                    %Digital system sampling rate
ts = 1/fs;
fd = 300;                                          %Doppler frequency deviation
path_power = [-1.0 -1.0 -1.0 0 0 0 -3.0 -5.0 -7.0];
path_delays = [0 50 120 200 230 500 1600 2300 5000]*1e-9;
% chan = rayleighchan(ts, fd, path_delays, path_power);  
r_chan = comm.RayleighChannel('SampleRate',fs, ...
    'PathDelays',path_delays,'AveragePathGains',path_power, ...
    'MaximumDopplerShift',fd,'FadingTechnique','Sum of sinusoids');

%% Baseband data generation
data_source_bit = randi([0,1],1,number_bit);
%% Channel coding (convolutional code, reinterleaving)
L=7;                %Convolution code constraint length
tb_len=6*L;          %Viterbi decoder backtrace depth
trellis = poly2trellis(7,[133 171]);       %(2,1,7) convolution coding
data_conv = convenc(data_source_bit,trellis);
data_scramble = matintrlv(data_conv, log2(M), length(data_conv) / log2(M));
%% QPSK modulation
data_dec = bi2de(reshape(data_scramble,length(data_scramble)/log2(M),log2(M)));
data_moded = pskmod(data_dec,M,pi/M);
scatterplot(data_moded);
%% String and transform
data_moded = reshape(data_moded,number_carriers,length(data_moded)/number_carriers);
%% Spread spectrum
%% Zero padding
data_buling = [data_moded;...
    zeros(num_fft-size(data_moded,1),size(data_moded,2))];
%% Inserted pilot frequency
if (is__pilot_k==1)
    pilot_bit_k = randi([0,1],1,log2(M)*num_fft);
    pilot_seq = pskmod(bi2de...
    (reshape(pilot_bit_k,length(pilot_bit_k)/log2(M),log2(M))),M,pi/M);
    data_pilot_inserted = insert_pilot_f(data_buling,pilot_seq,pilot__interval,is__pilot_k);
end

%% IFFT
data_ifft = ifft(data_pilot_inserted,num_fft)*num_fft;
%data_ifft = ifft(data_pilot_inserted,num_fft)*sqrt(num_fft);
%% Insert guard intervals, cyclic prefixes
data_after_cp = [data_ifft(num_fft-cp_LEN+1:end,:);data_ifft];
%% And string conversion
data_total = reshape(data_after_cp,[],1);
%% Pulse forming,
sendfir = rcosdesign(0.4,4,fs/B_baseband,'sqrt');
data_upsam = upsample(data_total,fs/B_baseband);
data_send = conv(data_upsam,sendfir,'same');
%% drawing
sig = data_send;
figure(2);
subplot(311);
plot(real(sig));
title('real')
subplot(312);
plot(imag(sig));
title('imag')
subplot(313);
y_fft=abs(fft(sig,q*num_fft));
x_fft=fs*((1:(q*num_fft))/(q*num_fft)-1/2);
plot(x_fft,20*log10(fftshift(y_fft./max(y_fft))));
title('fft')
%% DA
%% The variable frequency
%% Channel (via multi-channel Rayleigh channel, AWGN channel)

Ber=zeros(1,length(SNR));
for jj=1:length(SNR) 
    for ii=1:sta_num
        channel_out = step(r_chan,data_send);
        rx_channel=awgn(channel_out,SNR(jj),'measured');       
%% The variable frequency
%% AD
        rx_data1 = conv(rx_channel, sendfir, 'same');
        rx_data2 = rx_data1(1:fs/B_baseband:length(rx_data1));
%% String and transform
        rx_data3=reshape(rx_data2,num_fft+cp_LEN,[]);
%% Remove the cyclic prefix
        rx_data4=rx_data3(cp_LEN+1:end,:);
%% FFT
        rx_data_fft = (1/num_fft)*fft(rx_data4,num_fft);
%% Channel Estimation and Interpolation (equalization)
%% Channel correction
        [rx_data_delpilot,H] = get_pilot_f(rx_data_fft,pilot__interval);
        rx_data_estimation = chan_estimation_f...
        (rx_data_delpilot,H,pilot_seq,pilot__interval);
%% Zero and string conversions
        rx_data_quling = rx_data_estimation(1:number_carriers,:);
        rx_data_psk = reshape(rx_data_quling,[],1);
%         scatterplot(rx_data_psk);
%% Algorithm to
%% QPSK demodulation
        demodulation_data=pskdemod(rx_data_psk,M,pi/M);    
        De_data1 = reshape(demodulation_data,[],1);
        De_data2 = de2bi(De_data1);
        De_Bit = reshape(De_data2,1,[]);   
%% (Unintertwine)
        rx_data_jiejiaozi = matdeintrlv(De_Bit, log2(M), length(De_Bit) / log2(M));
%% Channel decoding (Viterbi decoding)
        rx_data_deco = vitdec(rx_data_jiejiaozi,trellis,tb_len,'trunc','hard');   %硬判决
%% Calculate bit error rate
[~, ber] = biterr(rx_data_deco(1:length(data_source_bit)),data_source_bit);%Bit error rate after decoding
Ber(jj)=Ber(jj)+ber;
    end
Ber(jj)=Ber(jj)/sta_num;
fprintf("SNR = %d dB, ber = %.5f \n",SNR(jj),Ber(jj));
end
figure(3);
sig = rx_channel;
subplot(311);
plot(real(sig));
title("real")
subplot(312);
plot(imag(sig));
title("imag")
subplot(313);
y_fft=abs(fft(sig,q*num_fft));
x_fft=fs*((1:(q*num_fft))/(q*num_fft)-1/2);
plot(x_fft,20*log10(fftshift(y_fft./max(y_fft))));
title("fft")
figure(4);
%  semilogy(SNR,Ber2,'b-s');
%  hold on;
semilogy(SNR,Ber,'r-o');
hold on;
xlabel('SNR');
ylabel('BER');
title('BER curve under ETU300 superimposed AWGN channel');

toc;