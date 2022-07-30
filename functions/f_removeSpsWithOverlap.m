function [spsRm, indsRm, badInt] = f_removeSpsWithOverlap(sps, intervals, intMinGap, badInt, badMinGap)
%f_removeSpindleOverlap removes spindles that overlap with intervals
% overlap is any gap smaller than <int_min_gap>. Removed intrevals are
% replaced by bad intervals; the latter are merged if the gap is smaller
% than <badMinGap>
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   OUTPUT
%       spsRm 	a spindle structure after the overlap removal
%       indsRm	indices of spindles that were removed
%       badInt	bad intervals after they were expended and merged if needed
%
%   INPUT
%       sps        [cell array]
%           spindle info
%           .onset
%           .duration
%           .other fields...
%
%       intervals   intervals to test if spindles overlap with them
%           .onsets
%           .durations
%
%       intMinGap	a minimum gap in seconds between spindles and
%                   <intervals>; spindles with a gap smaller than
%                   <intMinGap> from <intervals> are removed; the default value is 0
%
%       badInt      bad intervals that are expended and merged if needed;
%                   if intervals contains bad intervals then bad_int = intervals
%
%       badMinGap	a minimum gap in seconds between bad intervals;
%                   bad intervals with a gap smaller than <bad_min_gap> are
%                   merged; the default value is 0
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

if nargin < 5 || isempty(badMinGap),    badMinGap = 0; end
if nargin < 4 || isempty(badInt),       badInt = []; end
if nargin < 3 || isempty(intMinGap),    intMinGap = 0; end

%% REMOVE OVERLAPS FROM INTERVALS1 & ADD BAD INTERVALS IF NEEDED

allSps = struct(...
            'onsets', [],...
            'durations', []...
            );  
allSps.onsets      = [allSps.onsets sps.onset];
allSps.durations   = [allSps.durations sps.duration];

disp('LOOKING FOR SPINDLES THAT OVERLAP WITH INTERVALS............');

for i_sp = 1 : numel(allSps.onsets)
    sp_start   = allSps.onsets(i_sp);
    sp_end     = sp_start + allSps.durations(i_sp);

    for i_int = 1 : numel(intervals.onsets)
        int_start       = intervals.onsets(i_int);
        int_end         = int_start + intervals.durations(i_int);
        int_gap_start   = int_start - intMinGap;
        int_gap_end     = int_end + intMinGap;
        
        if ((int_gap_start <= sp_start) && (sp_start < int_gap_end))||...
                ((int_gap_start < sp_end) && (sp_end <= int_gap_end))
            disp(['Spindle ' num2str(i_sp) ' [' num2str(sp_start) '   ' num2str(sp_end) ']']);
            disp(['is within the gap smaller than ' num2str(intMinGap) ' from ....']);
            disp(['interval ' num2str(i_int) ' [' num2str(int_start) '   ' num2str(int_end) ']']);
            fprintf('The spindle will be removed.\n\n');
        
            % Add bad interval if needed
            if ~isempty(badInt)
                badInt.onsets(end+1)       = sp_start;
                badInt.durations(end+1)	= sp_end - sp_start;
            end
            
            % interval to remove is set to NaN
            allSps.onsets(i_sp) = NaN;
            
        end % IF int1 overlap with int2

    end % FOR each intervals2

end % FOR each intervals1

% remove NaNs
indsRm = find(isnan(allSps.onsets));
if ~isempty(indsRm)
    sps(indsRm) = [];
end

spsRm = sps;

%% MERGE BAD INTERVALS

if ~isempty(badInt)
    badInt = f_sortAndMerge(badInt, badMinGap); % intervals are sorted and merged
else
    badInt = [];
end

end

