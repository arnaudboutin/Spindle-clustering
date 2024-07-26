function spsTimeSpecific = f_extractSpindleTimeSpecific(spsTimeSpecific,last_onset)
% Adrien Conessa (CIAMS, Université Paris-Saclay)
% Arnaud Boutin (CIAMS, Université Paris-Saclay)

stage_to_process={'NREM2','NREM3','NREM23'};
field_to_process={'sps','spsNoBi','spsGrp','spsGrpNoBi','spsIso','spsIsoNoBi'};

for idx_stage=1:numel(stage_to_process) % loop over each stage

    tmp_sps=spsTimeSpecific.(stage_to_process{idx_stage}); % extract stage data
    spsTimeSpecific.(stage_to_process{idx_stage})=tmp_sps; % just to instantiate all fields
    

    for idx_field=1:numel(field_to_process)

        spsTimeSpecific.(stage_to_process{idx_stage}).(field_to_process{idx_field})=tmp_sps.(field_to_process{idx_field})([tmp_sps.(field_to_process{idx_field}).onset]<last_onset);


    end


end
end