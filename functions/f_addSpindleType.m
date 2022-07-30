function [o_sps, o_typeInfo] = f_addSpindleType(sps, typeInfo)
%Id_spindlesByType adds spindle type cosidering the interval/gap between them
% The inter-spindle interval is calculated between onsets of adjacent spindles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following fields are added to each spindle:
%   .i          spindle index
%   .i_wtnGrp  	index within the group
%	.type       e.g., isolated/dense/rhythmic/... according to the type_info
%	---------------
%	for type 1 only, i.e., the first spindle within the group
%	---------------
%	.inds_grp
%
%   OUTPUT
%       o_sps       [struct]  	spindles with indices and type
%       o_typeInfo  [struct]	also includes indices of the first spindle
%                               for each spindle event by its type
%       
%   INPUT
%       sps        [struct]    spindle info
%           .onset
%           .duration
%
%       typeInfo	[struct]
%           .desc       [string]
%           .gapMinMAx	[double double]     lower and upper gap limit, in
%                                           seconds, between 0 and inf
%
% created by Ella Gabitov on April 9, 2020

if isempty(sps)
    o_sps                   = sps;
    [typeInfo.inds_frst]    = deal([]);    % set empty vector for all struct elements
    o_typeInfo              = typeInfo;
    return;
end
    
%%

for i_type = 1 : numel(typeInfo)
    
    %% GET TYPE INFO
    
    desc    = typeInfo(i_type).desc;
    minGap  = typeInfo(i_type).gapMinMax(1);
    maxGap  = typeInfo(i_type).gapMinMax(2);
    
    inds_frst   = [];
    inds_grp    = [];
    
    prevGap = minGap + 1/power(10,10);     % for the very first spindle only
    
    %% ALL SPINDLES
    
    for i_sp = 1 : numel(sps)-1
        sps(i_sp).i     = i_sp;
        nextGap         = sps(i_sp+1).onset - sps(i_sp).onset;
        
        if (minGap < nextGap) && (nextGap <= maxGap)
            if minGap < prevGap
                % isolated spindle
                if maxGap == inf
                    sps(i_sp).type = desc;
                    inds_frst = [inds_frst i_sp];
                % part of the group    
                else
                    inds_grp = [inds_grp i_sp];
                end
            end
                    
        % the end of the current group
        elseif ~isempty(inds_grp)
            % the last spindle of the group
            if maxGap < nextGap
                inds_grp = [inds_grp i_sp];
            end
            
            if numel(inds_grp) > 1
                % set info for the first spindle in the group
                inds_frst                   = [inds_frst inds_grp(1)];
                sps(inds_grp(1)).inds_grp   = inds_grp;

                % set info for all spindles in the group
                [sps(inds_grp).type]        = deal(desc);
                inds_wtnGrp_cell         	= num2cell([1:numel(inds_grp)]);
                [sps(inds_grp).i_wtnGrp]	= deal(inds_wtnGrp_cell{:});
            end
            
            % reset group
            inds_grp = [];
            
        end % IF
        
        prevGap = nextGap;
            
    end % FOR each spindle
    
    %% THE VERY LAST SPINDLE
    
    i_sp        = i_sp+1;
    sps(i_sp).i = i_sp;
    
    if minGap < prevGap && prevGap <= maxGap
        % isolated spindle
        if maxGap == inf
            sps(i_sp).type = desc;
            inds_frst = [inds_frst i_sp];
        % part of the group    
        else
            inds_grp = [inds_grp i_sp];
        end
    end
    
    if numel(inds_grp) > 1
        % set info for the first spindle in the group
        inds_frst                   = [inds_frst inds_grp(1)];
        sps(inds_grp(1)).inds_grp   = inds_grp;

        % set info for all spindles in the group
        [sps(inds_grp).type]        = deal(desc);
        inds_wtnGrp_cell         	= num2cell([1:numel(inds_grp)]);
        [sps(inds_grp).i_wtnGrp]	= deal(inds_wtnGrp_cell{:});
    end
    
    typeInfo(i_type).inds_frst = inds_frst;
        
end % FOR each type

%% OUTPUT

o_sps       = sps;
o_typeInfo  = typeInfo;

end

