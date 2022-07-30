function [o_sps, indsSparse, o_bi] = f_removeSparseSpindles(sps, spMaxGap, bi)
%f_removeSparseSpindles detects and removed sparse spindles that are away
% from other spinldes more than <regGap>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   OUTPUT
%       o_sps   	only regular spindles after the sparse spindles are removed
%       indsSparse	indices of sparse spindles
%       o_bi        bad intervals after replacement of the removed sparse spindles
%
%   INPUT
%       sps         [cell array]
%           spindle info
%           .onset
%           .duration
%           .other fields...
%
%       spMaxGap	[double]
%                   a maximum onset-onset gap, in seconds, between regular spindles
%                   is calculated from the spindle onset to the next spinlde onset
%                   a spindle with inter-spindle gap greater than <regGap> is removed
% 
%       bi          structure with bad intervals
%           .desc
%           .onsets
%           .durations
%                   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

if nargin < 3 || isempty(bi)
    bi.desc         = 'biSps';
    bi.onsets       = [];
    bi.durations    = [];
end
    
if nargin < 2 || isempty(spMaxGap)
    o_sps       = sps;
    indsSparse	= [];
    o_bi        = bi;
    return;
end

%%

indsSparse = [];

isPrevSparse = true;
for i_sp=1 : numel(sps)-1
    
    % either the very first spindle or the spindle preceded by sparsed spindle
    if isPrevSparse
        if (sps(i_sp+1).onset-sps(i_sp).onset) > spMaxGap
            disp('A sparse spindle has been found:');
            disp(['Spindle ' num2str(i_sp)      ', onset ' num2str(sps(i_sp).onset)]);
            disp(['Spindle ' num2str(i_sp+1)    ', onset ' num2str(sps(i_sp+1).onset)]);
            disp(['Spindle ' num2str(i_sp) ' will be removed.']);
            indsSparse(end+1) = i_sp;
        end        
    end
    
    % update the status of the previous spindle for the next check
    isPrevSparse = (sps(i_sp+1).onset-sps(i_sp).onset) > spMaxGap;
    
end % FOR each spindle

% check the last spindle
i_sp = i_sp + 1;
if isPrevSparse
    disp('The last spindle is sparse:');
    disp(['Spindle ' num2str(i_sp)      ', onset ' num2str(sps(i_sp).onset)]);
    disp('will be removed.');
    indsSparse(end+1) = i_sp;
end

if ~isempty(indsSparse)
    % replace sparse spindles by bad intervals
    bi.onsets(end+1:end+numel(indsSparse))    = [sps(indsSparse).onset];
    bi.durations(end+1:end+numel(indsSparse)) = [sps(indsSparse).duration];
    
    % remove sparse spindles
    sps(indsSparse) = [];
end

o_sps	= sps;

%% SORT & MERGE BAD INTERVALS

if ~isempty(bi)
    o_bi = f_sortAndMerge(bi); % intervals are sorted and merged if they overlap
else
    o_bi = [];
end


end

