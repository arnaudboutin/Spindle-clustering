function [o_sps, o_inds] = f_addSpindleStage(sps, stage)
%f_addSpindleStage add stage field to spindle events
% spindle events can be single spindles, groups or isolated spindles
%
% The spindle event is asigned to a given stage if it started and ended in
% this stage or if more than half of its duration overlaps with this stage
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   OUTPUT
%       o_sps   [struct]
%           spindles with additinal field according to the stage
%           with integers indicating spindle index within the stage interval
%
%       o_inds	[vector of doubles]
%       	indices of spindle events, that occured during the given stage only
%
%   INPUT
%       sps	[struct]
%           spindle events, i.e., single spindles, groups or isolated spindles
%           .onset       [double]        spindle event onset in seconds
%           .duration    [double]        spindle event duration in seconds
%           .other fields
%       stage     	[struct]
%           information for the given stage
%           .desc
%           .onsets     [vector of double]     all onsets for the stage
%           .durations 	[vector of double]     all durations for the stage
% 
%
% created by Ella Gabitov on March 13, 2020

%% PREPARE ONSETS AND DURATIONS FOR ANALYSIS

% get spindle onsets & durations
spsOnsets       = [sps.onset];
spsDurations	= [sps.duration];

% make sure that spindles are sorted by their onsets
if ~issorted(spsOnsets)
    error('The spindles are not sorted by their onsets. CHECK!!!');
end

% get stage info and sort by onsets
[stageOnsets, inds_stagesSorted]	= sort(stage.onsets);
stageDurations                      = stage.durations;
stageDurations                      = stageDurations(inds_stagesSorted);

%%

inds_withinStage = [];

for i_stage=1 : numel(stageOnsets)
    stageOnset     = stageOnsets(i_stage);
    stageOffset    = stageOnsets(i_stage)+stageDurations(i_stage);
    
    count_sp = 0; % spindle counter within the stage interval
    
    % the last spindle before the onset of the current stage interval
    inds_sps   = find(spsOnsets < stageOnset);
    if ~isempty(inds_sps)
        i_sp        = inds_sps(end);
        spOnset     = spsOnsets(i_sp);
        spOffset    = spOnset+spsDurations(i_sp);
        % longer time of the spindle duration overlaps with the current stage interval
        if (stageOnset - spOnset) < (spOffset - stageOnset)
            count_sp  	= count_sp + 1;
            sps(i_sp).(stage.desc)	= count_sp;
            inds_withinStage     	= [inds_withinStage i_sp];
        end
    end
    
    % spindles that started during the current stage interval
    inds_sps1   = find(stageOnset <= spsOnsets);
    inds_sps2   = find(spsOnsets < stageOffset);
    inds_sps    = inds_sps1(ismember(inds_sps1, inds_sps2));
    if ~isempty(inds_sps)        
        for i=1:numel(inds_sps)-1
            count_sp             	= count_sp + 1;
            i_sp                	= inds_sps(i);
            sps(i_sp).(stage.desc)	= count_sp;
        end
        inds_withinStage = [inds_withinStage inds_sps(1:end-1)];
        
        % check the last spindle
        i_sp        = inds_sps(end);
        spOnset     = spsOnsets(i_sp);
        spOffset	= spOnset+spsDurations(i_sp);
        % at least half of the spindle duration overlaps with the current stage interval
        if (stageOffset - spOnset) >= (spOffset - stageOffset)
            count_sp                = count_sp + 1;
            sps(i_sp).(stage.desc)	= count_sp;
            inds_withinStage = [inds_withinStage i_sp];
        end
    end
         
end

o_sps   = sps;
o_inds 	= inds_withinStage;

end





