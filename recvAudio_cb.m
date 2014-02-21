function recvAudio_cb(obj, event)
%tic
global msg idx

%disp('In the callback.')
if (idx >= obj.TotalSamples)
    return;
end
data = getaudiodata(obj, 'double');
msg.push(data(idx+1:obj.TotalSamples));
idx = obj.TotalSamples;

%toc