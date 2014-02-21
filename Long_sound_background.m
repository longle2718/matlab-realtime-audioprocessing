%% Data Acquisition and Analysis using MATLAB
% MATLAB supports data acquisition using the Data Acquisition Toolbox.
% This code example shows you how to easily acquire and analyze data in 
% MATLAB.  Uses MATLAB to acquire two seconds of sound data from a 
% sound card, calculate the frequency components, and plot the results.  
% See note below on how to easily update this example to use different 
% supported data acquisition hardware.
%
%% Note: Automatically generating a report in MATLAB
% Press the "Save and Publish to HTML" button in the MATLAB Editor to 
% execute this example and automatically generate a report of this work.
%
%% Step 1: Create an analog input object to communicate with data acquisition device
% In this case, a Windows sound card is used ('winsound').
clear all

%% Step 2: Configure the analog input to acquire 2 seconds of data at 8000Hz
global Fs;
Fs = 16000;

global blklen2;
blklen2 = 256;

ai = analoginput('winsound');
addchannel(ai,1);
duration = inf;
set (ai, 'SampleRate', Fs);
set (ai, 'SamplesPerTrigger', Fs*duration);
set (ai, 'SamplesAcquiredFcn', @Long_sound_callback);
set (ai, 'SamplesAcquiredFcnCount', blklen2);
% set (ai, 'TimerFcn', @sound_acquisition_tmr_callback);
% set (ai, 'TimerPeriod', 0.5);

global totalData
% keep a circular buffer of blklen
totalData.time = zeros(blklen,1);
totalData.data = zeros(blklen,1);

%% Step 3: Start the acquisition

start(ai);
%% Step 4: Stop acquisition
stop(ai);

%% Step 5: Clean up
delete(ai);
clear ai