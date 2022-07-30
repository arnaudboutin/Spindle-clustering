function [o_sps, indsRm, o_bi] = f_removeLongSpindles(sps, spMaxDur, bi)
%f_removeLongSpindles removes spindles that are too long
% the removed spinldes are replaced by bad intervals
% bad intervals that are too close apart are merged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   OUTPUT
%       o_sps 	spindles after their removal
%       indsRm	indices of spindles that were removed
%       o_bi   	bad intervals after they were updated and merged if needed
%
%   INPUT
%       sps         [cell array]
%           spindle info
%           .onset
%           .duration
%           .other fields...
%
%       spMaxDur  	[double]
%                   a maximum spidle duration, in seconds
%                   spindles longer than <spMaxDur> are removed
%                   and replaced by bad intervals
%
%       bi          bad intervals that are expended and merged if needed;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

if nargin < 4 || isempty(biMinGap), biMinGap = 0; end

if nargin < 3 || isempty(bi)
    bi.desc         = 'biSps';
    bi.onsets       = [];
    bi.durations    = [];
end

%% REMOVE SPINDLES LONGER THAN spMaxDur & REPLACE THEM BY BAD INTERVALS

fprintf(['\nLOOKING FOR SPS LONGER THAN ' num2str(spMaxDur) 'seconds...............\n'])

spsDurations    = [sps.duration]; % extract spindle durations into vector
indsRm          = find(spsDurations > spMaxDur);

if ~isempty(indsRm)
    disp(['Spindles with the following indices are longer than ' num2str(spMaxDur) 's and, therefore, will be removed:']);
    disp(indsRm);
    
    % add bad intervals instead of removed spindles
    bi.onsets(end+1:end+numel(indsRm))  	= [sps(indsRm).onset];
    bi.durations(end+1:end+numel(indsRm))	= [sps(indsRm).duration];
    
    % remove spindles
    sps(indsRm) = [];
else
    fprintf(['no sps longer than ' num2str(spMaxDur) 'sec\n'])
end

o_sps = sps;

%% SORT & MERGE BAD INTERVALS

if ~isempty(bi)
    o_bi = f_sortAndMerge(bi); % intervals are sorted and merged if they overlap
else
    o_bi = [];
end

end

