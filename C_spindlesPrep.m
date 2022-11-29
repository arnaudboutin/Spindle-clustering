% Spindle preprocessing
% ------------------------
% (1) Merge spindles
% (2) Remove spinldes longer than 2 s
% (3) Remove sparse spindles leaving only spindles that occur regularly
%
% Periods that overlap with removed spinldes are added to bad intervals

%% some vars

subject_to_process=[]; %  subj to process
channels={'Pz'};

% spindle type
type=''; % 'fast' 'slow' or '' if both

if ~isempty(type)
    TypeDir=[type '_sps\'];
    type=['_' type];
else
    TypeDir='';
end

spMinGap	= 0.3; 	% minimum offset-onset inter-spindle gap, in seconds; spindles that are closer apart are merged
spMaxDur	= 2;    % maxinum spindle duration, in seconds; spindles that are longer are removed
spMaxGap    = 60;	% a maximum period, in seconds, between spindles; any spindle beyond this gap apart from others is removed


% the order of procedures 
procedure_desc = '1 - merge; 2 - remove long; 3 - remove sparse';

%% Dir

MainDir='';
sps_dir_path  = '';
output_path='';

%% subjects

allFiles = dir(fullfile(sps_dir_path));
allFiles=allFiles(3:end,:);

subjects=cell(1,1);
for nFile=1:length(allFiles)
    subjects{1,nFile}       = allFiles(nFile).name;
end
           
%% process


for chan=1:numel(channels)

    source_EEG = channels{chan};
    
    for i_subj = subject_to_process
        subj            = subjects{i_subj};
        subj_dir_path   = [sps_dir_path subj];

        if ~exist([output_path subj], 'dir')
            mkdir([output_path subj]);
        end


        if exist(subj_dir_path, 'dir')
            disp('----------------------------------------------------------------------------------------------------------------');
            disp(subj_dir_path);
            spindles_source_fpath	= fullfile(subj_dir_path, [subj type '_spindles_' source_EEG '_NREM23.mat']);

            spsPrep = [];
            spsPrep.procedure_desc = procedure_desc;

            %% LOAD AND PREPROCESS

            % load & extract all spindles
            load(spindles_source_fpath);

            if size(spindles,2)<2  % if no NREM2 or just 1 sps
                continue
            end

            spsPrep.spsRaw 	= spindles;

            % merge spindles that are too close apart;
            % gap between the spindles is calculated as an offset-onset gap
            [spsMerged, indsMerged]	= f_mergeSpindles(spsPrep.spsRaw, spMinGap);
            spsPrep.spsMerged       = spsMerged;
            spsPrep.indsMerged      = indsMerged;

            % remove spinldes longer than <spMaxDur>; they are
            % substituted by bad intervals <bi>
            [spsNoLong, indsLong, biSps]	= f_removeLongSpindles(spsMerged, spMaxDur);
            spsPrep.spsNoLong               = spsNoLong;
            spsPrep.indsLong                = indsLong;
            spsPrep.biSps                   = biSps;

%             remove sparse spindles; they are substituted by bad intervals <biSps>
            [spsNoSparse, indsSparse, biSps]	= f_removeSparseSpindles(spsNoLong, spMaxGap, biSps);
            spsPrep.spsNoSparse                 = spsNoSparse;
            spsPrep.indsSparse                  = indsSparse;
            spsPrep.biSps                       = biSps;

            %% CLEAR & SAVE

            % clear the loaded file

            output_fpath = fullfile(output_path, subj, [subj type '_spsPrep_' source_EEG '.mat']);
            save(output_fpath, 'spsPrep')
            
            clear spindles
            clear spsPrep


        end % IF the subject directory exists

    end % FOR each subject

end % FOR each channel

disp('Sps prep done !')
