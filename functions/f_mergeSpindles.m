function [o_sps, indsMerged] = f_mergeSpindles(sps, spMinGap)
%f_mergeSpindles merges spindles that are too close apart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   OUTPUT
%       o_sps           spindles after their merge
%       indsMerged   	indices of spindles that were merged with the previous ones
%
%   INPUT
%       sps         [struct]    spindle info
%           .onset
%           .duration
%           .<other fields>...
%
%       spMinGap	[double]
%                   a minimum offset-onset gap, in seconds, between spindles
%                   is calculated from the spindle offset to the next spinlde onset
%                   two spindles with inter-spendle gap smaller than <min_gap> are merged
%                   if 0 - only spindles that overpap are merged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

if nargin < 2 || isempty(spMinGap), spMinGap = 0; end

%% REMOVE OVERLAPS FROM INTERVALS1 & ADD BAD INTERVALS IF NEEDED

indsMerged = [];

i_sp        = 1;
i_spNext    = i_sp+1;
while i_spNext <= numel(sps)
    sp_onset        = sps(i_sp).onset;
    sp_offset       = sp_onset + sps(i_sp).duration;
    spNext_onset    = sps(i_spNext).onset;
    spNext_offset   = spNext_onset + sps(i_spNext).duration;
    
    if (spNext_onset-sp_offset) < spMinGap
        fprintf('\n------------------------- SPINDLES WILL BE MERGED -------------------------\n');
        disp(['Spindle ' num2str(i_sp) ': [' num2str(sp_onset) '   ' num2str(sp_offset) ']']);
        disp(['is within the gap of ' num2str(spMinGap) ' from ....']);
        disp(['Spindle ' num2str(i_spNext) ': [' num2str(spNext_onset) '   ' num2str(spNext_offset) ']']);
        disp('The spinldes will be merged.');

        % merge spinldes
        sps(i_spNext).duration  = spNext_offset - sp_onset;
        indsMerged              = [indsMerged i_spNext];
    else
        i_sp = i_spNext;
    end % IF two spinldes should be merged
    i_spNext = i_spNext + 1;
end % WHILE there are spinldes to process

sps(indsMerged) = [];
o_sps = sps;

end

