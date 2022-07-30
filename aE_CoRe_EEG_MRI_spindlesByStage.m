% -------------------------------------------------------------
% Spindles should be preprocessed and classified by their type
% ------------------------------------------------------------

% Combines sleep stages and spindles into single ...mat file
% The spindles are classified by stage
% The spindle event is asigned to a given stage if it started and ended in
% this stage or if more than half of its duration overlaps with this stage

%% some vars

subject_to_process=[]; %  subj to process

channels={'Pz'};

stages_str	= {'NREM2', 'NREM3', 'NREM23'};
biEEG_str   = 'bad1s';  % fieldname with bad intervals detected from the electrode
biSps_str   = 'biSps';	% fieldname with bad intervals that replace spindles during preprocessing

an_desc = 'spsGrpIso';
sps_str	= {'sps', 'spsGrp', 'spsIso'};


%% spindle type
type=''; % 'fast' 'slow' or '' if both

if ~isempty(type)
    TypeDir=[type '_sps\'];
    type=['_' type];
else
    TypeDir='';
end

%% Dir

MainDir='';

sleep_dir_path  ='';
hypno_dir_path  = '';
output_path = '';

%% subjects

allFiles = dir(fullfile(sleep_dir_path));
allFiles = allFiles(3:end,:);

subjects=cell(1,1);
for nFile=1:length(allFiles)
    subjects{1,nFile} = allFiles(nFile).name;
end

%% process

for chan=1:numel(channels)

    source_EEG = channels{chan};

    for i_subj = subject_to_process - 4 
        subj            = subjects{i_subj};
        subj_dir_path   = [sleep_dir_path subj];
        subj_hyp_dir_path   = fullfile(hypno_dir_path, ['hypno_S' subj(7:end)]);

        if ~exist([output_path subj], 'dir')
            mkdir([output_path subj]);
        end

        if exist(subj_dir_path, 'dir')
            disp('----------------------------------------------------------------------------------------------------------------');
            disp(subj_dir_path);

            stages_source_path      = fullfile(subj_hyp_dir_path, ['hypno_S' subj(7:end) '_nap_01_stages.mat']);
            spindles_source_path	= fullfile(subj_dir_path, [subj type '_' an_desc '_' source_EEG '.mat']);


            %% LOAD DATA, & PREPROCESS SPINLDES
            % spindle preprocessing includes spindle merge and removal

            load(stages_source_path)
            spsByStage = nap_sleep;

            if ~exist(spindles_source_path,'file')
                continue
            end
            
            % load & extract all spindles
            load(spindles_source_path)
            
            % save bad intervals that replace spindles removed during preprocessing
            spsByStage.(biSps_str)  = spsByType.(biSps_str);

            if ~isfield(spsByType,'spsGrp') || numel(spsByType.sps)<3
                fprintf('not enough spindles\n')
                continue
            end

            % combine bad intervals
            bi.desc         = 'bi';
            bi.onsets       = [spsByStage.(biEEG_str).onsets spsByStage.biSps.onsets];
            bi.durations    = [spsByStage.(biEEG_str).durations spsByStage.biSps.durations];
            bi              = f_sortAndMerge(bi);

            %% CLASSIFY & SAVE SPINDLES BY STAGE

            % add field for each stage to the spindles
            for i_stage=1 : numel(stages_str)
                stage_str	= stages_str{i_stage};
                stage_tmp	= spsByStage.(stage_str);
                for i_sps = 1 : numel(sps_str)
                    [sps, inds.(stage_str).(sps_str{i_sps})] = f_addSpindleStage(spsByType.(sps_str{i_sps}), stage_tmp);
                    spsByType.(sps_str{i_sps})  = sps;
                end
            end

            % save spindles by stage
            for i_stage = 1 : numel(stages_str)
                stage_str	= stages_str{i_stage};
                for i_sps = 1 : numel(sps_str)
                    spsTmp = spsByType.(sps_str{i_sps});
                    spsTmp = (spsTmp(inds.(stage_str).(sps_str{i_sps})));  % spindles for the current stage only
                    spsByStage.(stage_str).(sps_str{i_sps}) = spsTmp;

                    % remove spindles that overlap with bad intervals & save
                    [spsTmp, indsRm, bi]                                = f_removeSpsWithOverlap(spsTmp, bi, 0, bi);
                    spsByStage.(stage_str).([sps_str{i_sps} 'NoBi'])    = spsTmp;
                end
            end

            spsByStage.bi = bi;

            %% CLEAR & SAVE

            % clear the loaded file


            save_fname = fullfile([output_path subj], [subj type '_' an_desc '_byStage_' source_EEG '.mat']);
            save(save_fname, 'spsByStage');
            
            clear nap_sleep
            clear spsByType
            clear spsTmp
            clear spsByStage

        end % IF the subject directory exists

    end % FOR each subject

end % FOR each channel
% clearvars;

disp('Sps by stage done !')
