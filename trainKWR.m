% Train a continuous speech recognition (CSR) keyword-filler network
% for keyword recognition (KWR)
%
% Long Le
% University of Illinois
%

clear all; close all;

%addpath('../voicebox/');
%old = cd('../pmtk/');
%initPmtk3
%cd(old);
%% Load speech data
fs = 8e3;
win = 13e-3*fs; % == nfft unless explicitly specified 
inc = 10e-3*fs;

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

%% Build an HMM for each word
nSmax = 10; % Maximum number of Markov state per word

model = cell(nFiller, 1);
for k = 1:nFiller
    modelTmp = zeros(1, nSmax-1);
    loglik = zeros(1, nSmax-1);
    for nS = 3:nSmax
        % Gaussian observation assumption
        nO = size(fillerC{k}, 2);
        mu = repmat(mean(fillerC{k})', 1, nS);
        Sigma = reshape(repmat(cov(fillerC{k}), 1, nS), nO, nO, nS);
        emission0 = condGaussCpdCreate(mu, Sigma); 
        % HMM fit with gaussian observation
        pi0 = [1 zeros(1, nS-1)]; 
        % Each time step is inc/fs real time
        trans0 = triu(toeplitz([1-1/5 1/5 zeros(1, nS-2)])); trans0(end, end) = 1;
        
        % ML over dynamic, MAP over output process
        emissionPrior = emission0.prior;
        piPrior = zeros(nS, 1);
        transPrior = zeros(nS, nS);
        
        [modelTmp(nS-1), loglik(nS-1)] = hmmFit(fillerC{k}', nS, 'gauss','verbose',true,'maxIter',500,...
            'pi0', pi0, 'trans0', trans0, 'emission0', emission0, ...
            'piPrior', piPrior, 'transPrior', transPrior, 'emissionPrior', emissionPrior);
    end
    % compute and plot AIC/BIC scores & test likelihoods for all models 
    [~, idx] = max(loglik);
    model(k) = modelTmp(idx);
end