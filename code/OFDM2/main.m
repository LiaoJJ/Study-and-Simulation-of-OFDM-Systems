%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Version 3.0
%%% 16QAM调制(官方函数)
%%% IFFT(官方函数)
%%% 添加循环前缀(单径AWGN中CP好像没啥用？？)
%%% AWGN信道
%%% 去除循环前缀
%%% FFT(官方函数)
%%% 16QAM解调(官方函数)
%%% BER分析
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;close all;clc;
%% 基带数字信号及一些初始化
NFRAME = 3; % 每一帧的OFDM符号数
NFFT = 64; % 每帧FFT长度
NCP = 16; % 循环前缀长度
NSYM = NFFT + NCP; % OFDM符号长度
M = 16; K = 4; % M:调制阶数，K:log2(M)

EbN0 = 0:1:20; % 设出比特信噪比(dB)
snr = EbN0 + 10 * log10(K); % 由他俩关系推出(dB)
BER(1 : length(EbN0)) = 0; % 初始化误码率

file_name=['OFDM_BER_NCP' num2str(NCP) '.dat'];
fid=fopen(file_name, 'w+');

X = randi([0,15],1,NFFT * NFRAME); % 生成数字基带信号
%%
for i = 1 : length(EbN0) % 对于每一种比特信噪比，计算该通信环境下的误码率
    %% 16QAM调制(官方函数)
    X_mod = qammod(X,M,'gray') / (sqrt(10)); % 16QAM调制，格雷码星座图，并归一化
    %% IFFT与循环前缀添加
    x(1 : NFFT * NFRAME) = 0; % 预分配x数组
    xt(1 : (NFFT + NCP) * NFRAME) = 0; % 预分配x_t数组

    len_a = 1 : NFFT; % 处理的X位置
    len_b = 1 : (NFFT + NCP); % 处理的X位置(加上CP的长度)
    len_c = 1 : NCP;
    len_left = 1 : (NFFT / 2); len_right = (NFFT / 2 + 1) : NFFT; % 每一符号分为左右两边？？

    for frame = 1 : NFRAME % 对于每个OFDM符号都要翻转和IFFT
        x(len_a) = ifft([X_mod(len_right), X_mod(len_left)]); % 左右翻转再ifft
        xt(len_b) = [x(len_c + NFFT - NCP), x(len_a)]; % 添加CP后的信号数组

        len_a = len_a + NFFT; % 更新找到下一个符号起点位置
        len_b = len_b + NFFT + NCP; % 更新找到下一个符号起点位置(CP开头)
        len_c = len_c + NFFT;
        len_left = len_left + NFFT; len_right = len_right + NFFT;
    end
    %% 由snr计算噪声幅度并加噪
%      P_s = xt * xt' / NSYM / NFRAME; % 计算信号功率
%       delta1 = sqrt(10 .^ (-snr(i) / 10) * P_s / 2); % 计算噪声标准差
%       yr = delta1 * (randn(size(xt)) + 1i * randn(size(xt)));
    yr = awgn(xt,snr(i),'measured'); % 官方函数直接加噪
    %% 去除循环前缀并且FFT
    y(1 : NFFT * NFRAME) = 0; % 预分配y数组
    Y(1 : NFFT * NFRAME) = 0; % 预分配Y数组

    len_a = 1 : NFFT; % 处理的y位置
    len_b = 1 : NFFT; % 处理的y位置
    len_left = 1 : (NFFT / 2); len_right = (NFFT / 2 + 1) : NFFT; % 每一符号分为左右两边

    for frame = 1 : NFRAME % 对于每个OFDM符号先去CP，再FFT再翻转
        y(len_a) = yr(len_b + NCP); % 去掉CP

        Y(len_a) = fft(y(len_a)); % 先fft再翻转
        Y(len_a) = [Y(len_right), Y(len_left)];

        len_a = len_a + NFFT;
        len_b = len_b + NFFT + NCP;
        len_left = len_left + NFFT; len_right = len_right + NFFT;
    end
    %% 16QAM解调(官方函数)
    Yr = qamdemod(Y * sqrt(10),M,'gray');
    %% BER计算
    Neb = sum(sum(de2bi(Yr,K) ~= de2bi(X,K))); % 转为2进制，计算具体有几bit错误
    Ntb = NFFT * NFRAME * K;  %仿真的总比特数 
    BER(i) = Neb / Ntb;
    
    fprintf('EbN0 = %d[dB], BER = %d / %d = %.3f\n', EbN0(i),Neb,Ntb,BER(i))
    fprintf(fid, '%d %5.3f\n', EbN0(i),BER(i));
end
%% BER作图分析
fclose(fid);
disp('Simulation is finished');
plot_ber(file_name,K);