 % --------------------------------
% Spindles should be preprocessed
% Categorise spindle into isolated or grouped sps
% --------------------------------

%% some vars

subject_to_process=[]; %  subj to process

channels={'Pz'};

sps_str     = 'spsNoLong';  % or SpsNoLong
bi_str      = 'biSps';


%% spindle type
type=''; % 'fast' 'slow' or '' if both

if ~isempty(type)
    TypeDir=[type '_sps\'];
    type=['_' type];
else
    TypeDir='';
end

%% Dir

MainDir='D:\EEG_data_PPIMOBS';

sleep_dir_path  = [MainDir '\spindle_processing\' TypeDir 'sps_prep\'];
hypno_dir_path  = [MainDir '\spindle_processing\stage_extracted\'];
output_path = [MainDir '\spindle_processing\' TypeDir 'sps_by_type\'];


%% subjects

allFiles = dir(fullfile(sleep_dir_path));
allFiles=allFiles(3:end,:);

subjects=cell(1,1);
for nFile=1:length(allFiles)
    subjects{1,nFile}       = allFiles(nFile).name;
end

%% process


for chan=1:numel(channels)
    
    source_EEG = channels{chan};

    %% TYPES FOR SPINDLE EVENTS

    max_eventDur = 60; % any event that lasts longer than <max_eventDur> (in seconds) is excluded (spindle train of more than 60 sec for exemple) control if it is the case

    an_desc = 'spsGrpIso';

    typeInfo(1).desc       = 'Grp';	% grouped spindles
    typeInfo(1).gapMinMax  = [0 6];	% lower and upper limit for between-spindle gap, in seconds

    typeInfo(2).desc       = 'Iso'; 	% isolated spindles 
    typeInfo(2).gapMinMax  = [6 inf];  % lower and upper limit for between-spindle gap, in seconds
    % 6 exclu


    for i_subj = subject_to_process
        
        subj            = subjects{i_subj};
        subj_dir_path   = fullfile(sleep_dir_path, subj);

        if ~exist([output_path subj], 'dir') % create output folder
            mkdir([output_path subj]);
        end

        if exist(subj_dir_path, 'dir')
            disp('----------------------------------------------------------------------------------------------------------------');
            disp(subj_dir_path);
            spindles_source_path	= fullfile(subj_dir_path, [subj type '_spsPrep_' source_EEG '.mat']);

            spsByType       = [];

            %% LOAD PREPROCESSED SPINDLES

            if ~exist(spindles_source_path,'file')
                continue
            end
            
            load(spindles_source_path)
           
            bi  = spsPrep.(bi_str);
            sps = spsPrep.(sps_str);

            %% SEPARATE PREPROCESSED SPINDLES BY TYPE

            [sps, typeInfoTmp]  = f_addSpindleType(sps, typeInfo);
            spsByType.sps       = sps;
            spsByType.typeInfo	= typeInfoTmp;
            spsByType.(bi_str) 	= bi;

            for i_type = 1 : numel(typeInfoTmp)
                desc        = typeInfoTmp(i_type).desc;
                inds_frst   = typeInfoTmp(i_type).inds_frst;
                spsFrst      = sps(inds_frst);

                if isempty(spsFrst)
                    fprintf(['no ' desc ' spindles\n']) 
                    continue
                end
                
                if strcmp(desc,'Grp')
                    for i_sp = 1 : numel(spsFrst)
                        inds_grp = spsFrst(i_sp).inds_grp;
                        spsGrp = sps(inds_grp);
                        spsFrst(i_sp).onsets    = [spsGrp.onset];
                        spsFrst(i_sp).durations = [spsGrp.duration];

                        % set spindle duration to the total duration of the spindle event
                        spsFrst(i_sp).duration  = (spsFrst(i_sp).onsets(end)+spsFrst(i_sp).durations(end)) - spsFrst(i_sp).onset;
                    end

                    % exclude any event longer than <max_eventDur> (in seconds)
                    duration_tmp = [spsFrst.duration];
                    inds = find(duration_tmp > max_eventDur);
                    if ~isempty(inds)
                        fprintf('WARNING ! An event in sps grp is too long - CHECK!!!\n');

                    else
                        fprintf(['no grp longer than ' num2str(max_eventDur) 'seconds\n']);
                    end
                end

                spsByType.(['sps' desc]) = spsFrst;
            end

            %% CLEAR & SAVE

            % clear the loaded file

            save_fname = fullfile([output_path subj], [subj type '_' an_desc '_' source_EEG '.mat']);
            save(save_fname, 'spsByType');

            clear spsPrep; 
            clear spsByType
            
        end % IF the subject directory exists

    end % FOR each subject
end % FOR each channel
% clearvars;

disp('Sps by type done !')
