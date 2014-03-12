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
%% Load speech data and extract features
fs = 8e3;
win = 13e-3*fs; % == nfft unless explicitly specified 
inc = 10e-3*fs;

dirnames = dirs('TIDIGIT_adults_crop/train/');
nKeyword = numel(dirnames);
keyword = cell(nKeyword, 1);
keywordC = cell(nKeyword, 1); % Cepstrum
labTrain = cell(nKeyword, 1); % Label
nO = 8;
for k = 1:nKeyword
    labTrain{k} = dirnames(k);
    files = dir(['TIDIGIT_adults_crop/train/' dirnames{k} '/*.wav']);
    numfiles = numel(files);
    keyword{k} = cell(numfiles, 1);
    keywordC{k} = cell(numfiles, 1);
    for l = 1:numfiles
        [tmpY, tmpFs] = audioread(['TIDIGIT_adults_crop/train/' dirnames{k} '/' files(l).name]);
        tmpY = resample(tmpY, fs, tmpFs);
        %tmpY = tmpY + 2e-3*randn(size(tmpY));
        keyword{k}{l} = tmpY(:,1);
        keywordC{k}{l} = melcepst(tmpY(:,1), fs, '', nO, floor(3*log(fs)), win, inc)'; % d x T
    end
end

%% Build an HMM for each word
M = round([3:6]);
nM = numel(M);

model = cell(nKeyword, 1);
modelScore = cell(nKeyword, 1);
for k = 1:nKeyword
    disp(['==== keyword ' num2str(k) ' ====']);
    modelTmp = cell(1, nM);
    loglikHist = cell(1, nM);
    for l = 1:nM
        % Gaussian observation assumption
        mu = repmat(zeros(nO, 1), 1, M(l));
        Sigma = reshape(repmat(eye(nO), 1, M(l)), nO, nO, M(l));
        emission0 = condGaussCpdCreate(mu, Sigma); 
        % HMM fit with gaussian observation
        pi0 = [1 zeros(1, M(l)-1)]; 
        % Each time step is inc/fs real time
        trans0 = triu(toeplitz([1-1/5 1/5 zeros(1, M(l)-2)])); trans0(end, end) = 1;
        
        % ML over dynamic, MAP over output process
        emissionPrior = emission0.prior;
        piPrior = zeros(M(l), 1);
        transPrior = zeros(M(l), M(l));
        
        [modelTmp{l}, loglikHist{l}] = hmmFit(keywordC{k}, M(l), 'gauss','verbose',true,'maxIter',500,...
            'pi0', pi0, 'trans0', trans0, 'emission0', emission0, ...
            'piPrior', piPrior, 'transPrior', transPrior, 'emissionPrior', emissionPrior);
    end
    % compute and plot AIC/BIC scores likelihoods for all models 
    AIC = zeros(1, nM);
    BIC = zeros(1, nM);
    [tmpR, tmpC] = cellfun(@size, keywordC{k}');
    T = sum(tmpC);
    for l = 1:nM
        d = M(l) + M(l)^2 + nO*M(l) + nO^2*M(l);
        AIC(l) = loglikHist{l}(end) - d;
        BIC(l) = loglikHist{l}(end) - d*log(T)/2;
    end
    [~, idx] = max(BIC);
    disp(['Selected model with ' num2str(M(idx)) ' states'])
    model{k} = modelTmp{idx};
    modelScore{k} = BIC{idx};
end
save allModels.mat model

%% Simple test for the word 'key'
trainScore = zeros(nKeyword, nKeyword);
for k = 1:nKeyword
    wrapfun = @(x) hmmLogprob(model{k}, x) - ...
        (model{k}.nstates + model{k}.nstates^2 + nO*model{k}.nstates + nO^2*model{k}.nstates)*log(size(x, 2))/2;
    for l = 1:nKeyword
        trainScore(k, l) = sum(cellfun(wrapfun, keywordC{l}));
    end
end
[~, idx] = max(trainScore, [], 2);
probRecog = mean(idx == [1:nKeyword]')
find(idx ~=  [1:nKeyword]')