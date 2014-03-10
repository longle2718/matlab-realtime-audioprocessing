% Train (and test) a continuous speech recognition (CSR) keyword-filler network
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

files = dir('speech/train/*.mp3');
numfiles = length(files);
keyword = cell(1,numfiles);
labTrain = cell(numfiles, 1);
for k = 1:numfiles
    labTrain{k} = files(k).name(1:strfind(files(k).name,'.')-1);
	[keyword{k}, tmpFs] = audioread(['speech/train/' files(k).name]);
    keyword{k} = keyword{k}(:,1);
	keyword{k} = resample(keyword{k}, fs, tmpFs);
    keyword{k} = keyword{k} + 2e-3*randn(size(keyword{k}));
end

% Feature extraction
nKeyword = numel(keyword);
keywordC = cell(nKeyword, 1);
for k = 1:nKeyword
    % mel cepstrum coefficients and first order derivative, i.e. delta
	keywordC{k} = melcepst(keyword{k}, fs, '', 8, floor(3*log(fs)), win, inc);
end

%% Build an HMM for each word
M = round([3:6]);
nM = numel(M);

model = cell(nKeyword, 1);
for k = 1:nKeyword
    disp(['==== keyword ' num2str(k) ' ====']);
    modelTmp = cell(1, nM);
    loglikHist = cell(1, nM);
    for l = 1:nM
        % Gaussian observation assumption
        nO = size(keywordC{k}, 2);
        mu = repmat(mean(keywordC{k})', 1, M(l));
        Sigma = reshape(repmat(cov(keywordC{k}), 1, M(l)), nO, nO, M(l));
        emission0 = condGaussCpdCreate(mu, Sigma); 
        % HMM fit with gaussian observation
        pi0 = [1 zeros(1, M(l)-1)]; 
        % Each time step is inc/fs real time
        trans0 = triu(toeplitz([1-1/5 1/5 zeros(1, M(l)-2)])); trans0(end, end) = 1;
        
        % ML over dynamic, MAP over output process
        emissionPrior = emission0.prior;
        piPrior = zeros(M(l), 1);
        transPrior = zeros(M(l), M(l));
        
        [modelTmp{l}, loglikHist{l}] = hmmFit(keywordC{k}', M(l), 'gauss','verbose',true,'maxIter',500,...
            'pi0', pi0, 'trans0', trans0, 'emission0', emission0, ...
            'piPrior', piPrior, 'transPrior', transPrior, 'emissionPrior', emissionPrior);
    end
    % compute and plot AIC/BIC scores likelihoods for all models 
    AIC = zeros(1, nM);
    BIC = zeros(1, nM);
    for l = 1:nM
        d = M(l) + M(l)^2 + nO*M(l) + nO^2*M(l);
        T = size(keywordC{k},1);
        AIC(l) = loglikHist{l}(end) - d;
        BIC(l) = loglikHist{l}(end) - d*log(T)/2;
    end
    [~, idx] = max(BIC);
    disp(['Selected model with ' num2str(M(idx)) ' states'])
    model{k} = modelTmp{idx};
end
save allModels.mat model

% Simple test for the word 'key'
trainScore = zeros(nKeyword, nKeyword);
for k = 1:nKeyword
    for l = 1:nKeyword
        trainScore(k, l) = hmmLogprob(model{k}, keywordC{l}');
    end
end
[~, idx] = max(trainScore, [], 2);
probRecog = mean(idx == [1:nKeyword]')

%% Test built model
files = dir('speech/test/*.wav');
numfiles = length(files);
testword = cell(1,numfiles);
labTest = cell(numfiles, 1);
for k = 1:numfiles
    labTest{k} = files(k).name(1:strfind(files(k).name,'.')-1);
	[testword{k}, tmpFs] = wavread(['speech/test/' files(k).name]);
    testword{k} = testword{k}(:,1);
	testword{k} = resample(testword{k}, fs, tmpFs);
end

nTestword = numel(testword);
testwordC = cell(nTestword, 1);
for k = 1:nTestword
    testwordC{k} = melcepst(testword{k}, fs, '', 8, floor(3*log(fs)), win, inc);    
end

testScore = zeros(nKeyword, nTestword);
for k = 1:nKeyword
    for l = 1:nTestword
        testScore(k, l) = hmmLogprob(model{k}, testwordC{l}');
    end
end
[~, idx] = max(max(testScore, [], 2));