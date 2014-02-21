% Real time audio process
% Note that in Window 8, audio data are preprocessed, i.e. pitch auto
% cancellation, therefore cannot get raw audio data

clear all; close all;

addpath('../audioProcess/voicebox/');
addpath('C:\Users\long\Desktop\projects\cygwin\msub');

%% Parameters
global msg idx done
msg = CQueue();
idx = 1;
done = false;
recTime = 5; % seconds
fs = 22050;
nBits = 8;
nChannels = 1;
figure;

% Configure audio recorder
a = audiorecorder(fs, nBits, nChannels);
a.TimerFcn = {@recvAudio_cb};
a.TimerPeriod = 0.05; % second
a.StopFcn = {@endAudio_cb};

%% Main 
record(a, 30);
while(~done)
    pause(0.05); % waiting for the queue to build up
    % Dequeue
    data = msg.content(); msg.remove();
    if (numel(data) == 0)
        disp('empty data')
        continue;
    end
    for k =1:numel(data)
        dataDFT = fft(data{k});
        N = length(dataDFT);
        dataDFT = dataDFT(1:N/2+1);
        freq = 0:fs/N:fs/2;
        plot(freq, abs(dataDFT)); grid on
        axis([0 fs/2 0 1]);
        xlabel('Frequency (Hz)'); ylabel('Magnitude')
        drawnow;
    end
end
close;
delete(a);