function o_sps = f_calcSpindleGap(sps, stage_str)
%f_calcSpindleGap calculate gaps between adjacent spindles
% gaps are calculated between spindle onsets
%
% ASSAMPTION: all spindles have value in the field indicated by stage_str
% This value indicate the index/counter of the spindle within the sleep interval
% starting from 1 to ... n
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   OUTPUT
%       o_sps 
%           spindles with additional field containing spindle gaps
%           .gaps [double 1x2]  gaps before and after the spindle
%
%   INPUT
%       sps     [cell array]    spindle info
%           .onset
%           .duration
%           .... other fields
%
%       stage_str   [string]
%           the field with the stage to indicate the first spindle within
%           each sleep interval; contains spindle index/counter within the
%           sleep interval starting from 1 to ... n
%
% created by Ella Gabitov on March 13, 2020

o_sps = sps;

if numel(o_sps) < 2
    if numel(o_sps) == 1
        o_sps{1}.gaps = [NaN NaN];
    end
    return;
end

% two first spindles
gap         = NaN;
count       = o_sps(1).(stage_str);
postCount	= o_sps(2).(stage_str);
if count+1 == postCount
    gap = o_sps(2).onset-o_sps(1).onset;
end
o_sps(1).gaps 	= [NaN gap];
o_sps(2).gaps(1)	= gap;

for i_spindle=2 : numel(o_sps)-1
    gap         = NaN;
    count       = o_sps(i_spindle).(stage_str);
    postCount	= o_sps(i_spindle+1).(stage_str);
    if count+1 == postCount
        gap = o_sps(i_spindle+1).onset-o_sps(i_spindle).onset;
    end
    o_sps(i_spindle).gaps(2) 	= gap;
    o_sps(i_spindle+1).gaps(1)	= gap;
end

% two last spindles
gap                         = NaN;
count                       = o_sps(end-1).(stage_str);
postCount                  	= o_sps(end).(stage_str);
if count+1 == postCount
    gap = o_sps(end).onset-o_sps(end-1).onset;
end
o_sps(end-1).gaps(2)	= gap;
o_sps(end).gaps         = [gap NaN];

end

