% (1)   Extracts sleep stages into the same mat file; missing stages are added
%       with empty values for onsets and duration
% (2)   Merges NREM2 & NREM3 into NREM23
% (3)   Merges bad intervals with a gap smaller than <bad_min_gap>


subject_to_process=[];

% Minimum gap, in seconds, between bad intervals; bad intervals with smaller gap are merged
bad_min_gap = 1;    

%% Dir

source_sleep_dir_path   = '';
source_fields           = {'wake', 'NREM1', 'NREM2', 'NREM3', 'REM', 'BadIntervals'};

output_sleep_dir_path   = '';
output_fields           = {'wake', 'NREM1', 'NREM2', 'NREM3', 'REM', 'bad'};


%% subjects

allFiles = dir(fullfile(source_sleep_dir_path, '*.mat'));

subjects=cell(1,1);
for nFile=1:length(allFiles)
    filename                = allFiles(nFile).name;
    iStart_subjID           = strfind(filename, 'S');
    subjects{1,nFile}       = filename(1:iStart_subjID(1)+3);
end

%% process

for i_subj = subject_to_process
    subj = subjects{i_subj};
    
    if ~exist([output_sleep_dir_path subj], 'dir')
        mkdir([output_sleep_dir_path subj]);
    end
    
    
    if exist(source_sleep_dir_path, 'dir')
        fprintf(['\nProcessing ' subjects{i_subj} '...\n']);

        % load score file
        source_path  = fullfile(source_sleep_dir_path, [subj '_nap.mat']);
        load(source_path);
        nap_sleep = [];

            %% EXTRACT SLEEP STAGES/ INTERVALS

        for i_field = 1 : numel(source_fields)

            source_field_str                    = source_fields{i_field};
            output_field_str                    = output_fields{i_field};
            nap_sleep.(output_field_str).desc   = output_field_str;

            if isfield(hypno_sieste{3,1}, source_field_str)

                % round up onsets only for sleep stages
                if strcmp(source_field_str, 'BadIntervals')
                    nap_sleep.(output_field_str).onsets = hypno_sieste{3,1}.(source_field_str).onset(:)';
                else
                    nap_sleep.(output_field_str).onsets = ceil(hypno_sieste{3,1}.(source_field_str).onset(:))';
                end
                nap_sleep.(output_field_str).durations = hypno_sieste{3,1}.(source_field_str).duration(:)';

            else
                nap_sleep.(output_field_str).onsets     = [];
                nap_sleep.(output_field_str).durations   = [];
            end

        end % FOR each sleep stage

        %% MERGE BAD INTERVALS

        disp(' --------------------------- MERGE BAD INTERVALS --------------------------- ')

        nap_sleep.bad1s = f_sortAndMerge(nap_sleep.bad, bad_min_gap); 

        %% MERGE NREM2 & NREM3 INTO NREM23

        disp(' --------------------------- MERGE NREM2 & NREM3 --------------------------- ')
        NREM2_onsets    = nap_sleep.NREM2.onsets;
        NREM2_durations	= nap_sleep.NREM2.durations;
        NREM3_onsets    = nap_sleep.NREM3.onsets;
        NREM3_durations = nap_sleep.NREM3.durations;

        % combine NREM2 & NREM3
        NREM23.desc         = 'NREM23';
        NREM23.onsets       = [NREM2_onsets NREM3_onsets];
        NREM23.durations    = [NREM2_durations NREM3_durations];

        % merge & save
        nap_sleep.NREM23 = f_sortAndMerge(NREM23);

        %% CLEAR & SAVE


        save_fpath = fullfile(output_sleep_dir_path, subj, [subj '_nap_01_stages.mat']); % change 01 if there are more sleep recording
        save(save_fpath, 'nap_sleep');
        
        clear hypno_sieste; % clear the loaded file
        clear nap_sleep

    end % IF the subject directory exists
    
end % FOR each subject
% clearvars;
disp('stage extracted !')
