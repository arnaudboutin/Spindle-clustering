% Adrien Conessa (CIAMS, Université Paris-Saclay)
% Arnaud Boutin (CIAMS, Université Paris-Saclay)

% -------------------------------------------------------------s
% Spindles should be preprocessed and classified by their stage before
% ------------------------------------------------------------

% extract spindles for the first x min of NREM23 sleep

%% some vars

time_to_extract=20; %minutes

time_to_extract=time_to_extract*60;

subject_to_process=2:31; %  subj to process
baseline_or_conso={'baseline','conso'}; % night to process
channels={'Fp1','Fp2',...
    'F7','F3','Fz','F4','F8',...
    'FT9','FC5','FC1','FC2','FC6','FT10',...
    'T7','C3','Cz','C4','T8',...
    'CP5','CP1','CP2','CP6',...
    'P7','P3','Pz','P4','P8',...
    'O1','Oz','O2'};

stages_str	= {'NREM2', 'NREM3', 'NREM23'}; % stages to process
biEEG_str   = 'bad1s';  % fieldname with bad intervals detected from the electrode
biSps_str   = 'biSps';	% fieldname with bad intervals that replace spindles during preprocessing

an_desc = 'byStage';
sps_str	= {'sps', 'spsGrp', 'spsIso'};




%% Dir

MainDir='your dir\'; % your directories

sleep_dir_path  = [MainDir '\sps_by_stage\']; % spsByStage directory
output_path = [MainDir '\sps_time_specific\']; % output directory

addpath([Maindir '\functions']) % path with ISr_f_extractSpindleTimeSpecific function

%% subjects

allFiles = dir(fullfile(sleep_dir_path));
allFiles = allFiles(3:end,:);

subjects=cell(1,1);
for nFile=1:length(allFiles)
    subjects{1,nFile} = allFiles(nFile).name;
end

%% process

for chan=1:numel(channels)

    source_EEG = channels{chan}; % current chan
    fprintf(['processing ' source_EEG '\n'])


    for i_subj = subject_to_process - 1 % loop over each subject
        subj            = subjects{i_subj};
        subj_dir_path   = [sleep_dir_path subj];

        if ~exist([output_path subj], 'dir') % create output folder for subject
            mkdir([output_path subj]);
        end

        if exist(subj_dir_path, 'dir')
            disp('----------------------------------------------------------------------------------------------------------------');
            disp(subj_dir_path);

            for inight=1:2 % loop over each night
                night_type=baseline_or_conso{inight};
    
                spindles_source_path	= fullfile(subj_dir_path, [subj '_' night_type '_spsGrpIso_' an_desc '_' source_EEG '.mat']); % load sps data

    
                %% LOAD DATA, & PREPROCESS SPINLDES
                  
                if ~exist(spindles_source_path,'file') % continue if no sps
                    continue
                end
                    
                % load & extract all spindles
                load(spindles_source_path)
                stage_to_process={'NREM2','NREM3','NREM23'};
                
                for idx_field=1:numel(stage_to_process) % extract stage of interest

                    spsTimeSpecific.(stage_to_process{idx_field})=spsByStage.(stage_to_process{idx_field});

                end

                % find the last epoch wanted
                cumulative_sum_duration=cumsum(spsByStage.NREM23.durations); % duration of each epoch
                last_epoch= find(cumulative_sum_duration<time_to_extract,1,'last')+1; 

           
                
                if ~(last_epoch > numel(cumulative_sum_duration)) % if the last epoch wanted is not the last sleep epoch
                    

                    last_onset = spsByStage.NREM23.onsets(last_epoch)+(time_to_extract-cumulative_sum_duration(last_epoch-1)); % get the last possible onset
              
                    spsTimeSpecific=ISr_f_extractSpindleTimeSpecific(spsTimeSpecific,last_onset); % extract all spindles before the last possible onset
                    spsTimeSpecific.TimeLimit=time_to_extract/60; % just for reference


                elseif isempty(last_epoch) % basically, if the last epoch is in the first epoch (we are not talking about 30-sec epoch, but continous epoch, until change of stage)
                    last_epoch=1;
                    last_onset = spsByStage.NREM23.onsets(last_epoch)+time_to_extract;

                    spsTimeSpecific=f_extractSpindleTimeSpecific(spsTimeSpecific,last_onset);
                    spsTimeSpecific.TimeLimit=time_to_extract/60;


                else

                    % if the time limit is too large, take all epochs,
                    % return spsByStage basically
                    spsTimeSpecific.TimeLimit=cumulative_sum_duration(end)/60;
                end
    
                %% CLEAR & SAVE
    
                % save the file
                save_fname = fullfile([output_path subj], [subj '_' night_type '_spsGrpIso_time_' num2str(time_to_extract/60) '_' source_EEG '.mat']);
                save(save_fname, 'spsTimeSpecific');
                % clear the loaded file
                clear spsTimeSpecific
                clear spsByStage

            end % for night

        end % IF the subject directory exists

    end % FOR each subject

end
% clearvars;

disp('Sps time extracted done !')
