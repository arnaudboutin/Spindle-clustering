function intervals_merged = f_sortAndMerge(intervals, min_gap)
%f_sortAndMerge merges intervals with a gap smaller than <min_gap>
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   OUTPUT
%       intervals_merged    structure with marged intervals that contains
%                           the same fields as <intervals> sorted by onsets
%
%   INPUT
%       intervals 	a structure that contains onsets and duration
%       min_gap     a minimum gap in seconds
%                   intervals with a gap smaller than <min_gap> are merged
%                   the default value is 0
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

if nargin < 2 || isempty(min_gap), min_gap = 0; end

field_names = fieldnames(intervals);    % get all sub-fields
% remove desc from the list of fields
field_names(ismember(field_names, 'desc')) = [];

% sort
[~, inds_sorted]	= sort(intervals.onsets);
% sort all fields
for i_field = 1 :  numel(field_names)
    intervals.(field_names{i_field}) = intervals.(field_names{i_field})(inds_sorted);
end

i           = 1;
i_next      = i+1;

fprintf('\nLOOKING FOR OVERLAPING AND CLOSELY SPACED INTERVALS............\n');

while i < numel(intervals.onsets)
    int_onset   = intervals.onsets(i);
    int_offset 	= int_onset + intervals.durations(i);

    while i_next <= numel(intervals.onsets)&&...
            (intervals.onsets(i_next) - int_offset) <= min_gap
        int_offset                     = max(int_offset, intervals.onsets(i_next) + intervals.durations(i_next));
        intervals.onsets(i_next)    = NaN; % will be removed
        i_next                      = i_next +1;
    end

    % update the durations
    intervals.durations(i) = int_offset - int_onset;

    i           = i_next;
    i_next      = i+1;

end

% remove merged intervals; were set to NaN
inds2remove = find(isnan(intervals.onsets));
if ~isempty(inds2remove)
    disp(['The intervals ' num2str(inds2remove) ' were merged with the preceding ones and will be removed.']);
    % do it to all fields
    for i_field = 1 :  numel(field_names)
        intervals.(field_names{i_field})(inds2remove) = [];
    end  
else
    disp(['No intervals were merged']);
end

intervals_merged = intervals;

end

