function recvAudio_cb(obj, event)
%tic
global msg idx

%disp('In the callback.')
if (idx >= obj.TotalSamples)
    return;
end
data = getaudiodata(obj, 'double');
msg.push(data(idx:length(data)));
idx = length(data)+1;

%toc