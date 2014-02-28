% Train a continuous speech recognition (CSR) keyword-filler network
% for keyword recognition (KWR)
%
% Long Le
% University of Illinois
%

clear all; close all;

%addpath('../voicebox/');

%% Parameters
fs = 8e3;
win = 13e-3*fs; % == nfft unless explicitly specified 
inc = 10e-3*fs;

%% Load speech data
fnames = dir('speech/train/filler/*.mp3');
numfids = length(fnames);
filler = cell(1,numfids);
for k = 1:numfids
    tmp = ['speech/train/filler/' fnames(k).name];
	[filler{k}, tmpFs] = audioread(tmp);
    filler{k} = filler{k}(:,1);
	filler{k} = resample(filler{k}, fs, tmpFs);
end

fnames = dir('speech/train/keyword/*.mp3');
numfids = length(fnames);
keyword = cell(1,numfids);
for k = 1:numfids
    tmp = ['speech/train/keyword/' fnames(k).name];
	[keyword{k}, tmpFs] = audioread(tmp);
    keyword{k} = keyword{k}(:,1);
	keyword{k} = resample(keyword{k}, fs, tmpFs);
end

%speech = cell2mat([filler'; keyword']);

%% Feature extraction
nFiller = numel(filler);
fillerC = cell(nFiller, 1);
for k = 1:nFiller
    % 12 mel cepstrum coefficients and first order derivative, i.e. delta
	fillerC{k} = melcepst(filler{k}, fs, 'd', 12, floor(3*log(fs)), win, inc);
end

nKeyword = numel(keyword);
keywordC = cell(nKeyword, 1);
for k = 1:nKeyword
    % 12 mel cepstrum coefficients and first order derivative, i.e. delta
	keywordC{k} = melcepst(keyword{k}, fs, 'd', 12, floor(3*log(fs)), win, inc);
end

featSpace = 



