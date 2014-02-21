function sound_acquisition_tgr_callback( obj,event )

% Global variables
global totalData;
global blklen2;

% get data
[data,time] = getdata(obj,blklen2);

% update 50% overlap buffer
totalData.time = [totalData.time(blklen2+1:end);time];
totalData.data = [totalData.data(blklen2+1:end);data];

% start block processing here