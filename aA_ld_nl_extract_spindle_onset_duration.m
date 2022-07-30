%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detection of grouped and isolated spindles
% The critarion of inter-spindle interval (ISI) refers to time interval
% between onsets of adjacent spindles; is set to 6 secs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Information extracted for each spindle:
%   onset
%   duration


% clearvars 
clc

subject_to_process=[];


channels={'Pz'};


mainDirPath         = '';   % full path to the main directory
spindleDataDir      = '';   % directory with spindle data; should be placed under <main_dir_path>
spinldeOutputDir    = '';   % output directory to save the exctracted spindles ; will be placed under <main_dir_path>

%% some vars

sleepStage          = 'NREM23'; %'NREM2' for NREM2 - 'NREM3' for NREM3 - 'NREM23' for NREM2 & NREM3 together
% Sleep Stage 
disp(['Sleep stage: ' sleepStage]);
if strcmp(sleepStage,'NREM2')
    indSleepStage = 2;
elseif strcmp(sleepStage,'NREM3')
    indSleepStage = 3;
elseif strcmp(sleepStage,'NREM23')
    indSleepStage = [2 3];
end


%% process

for chan=1:numel(channels)
    % Electrode of interest: Pz, C3, C4   
    currentElectrode    = channels{chan}; 

    % store recap in txt file
    sps_recap=fopen( [mainDirPath '\sps_recap.txt'], 'a' );
    fprintf(sps_recap,['\n' datestr(datetime) ' --- extracted for ' currentElectrode '\n']);
    fclose(sps_recap);     


    spindleDirPath = fullfile(mainDirPath, spindleDataDir);   % full path to the directory that contains spindle data
    if ~exist(spindleDirPath, 'dir') 
        warning(['Looking for the spindle data directory: ' spindleDirPath ' ...']);
        error('The direcory with spindle data does not exist. CHECK!!!');
    end

    outputDirPath = fullfile(mainDirPath, spinldeOutputDir);  % full path to the output directory
    % Create output folder if it do not exist before running the analysis 
    if ~exist(outputDirPath, 'dir')
        mkdir(outputDirPath);
    end

    % get all spindle files for all subjects
    allFiles = dir(fullfile(spindleDirPath, '*.mat'));

    % Loop over all subjects / files
    for nFile=subject_to_process

        filename                = allFiles(nFile).name;
        [~, dataFileName, ~]    = fileparts(filename);
        iStart_subjID           = strfind(dataFileName, 'conso_');
        dataFileName            = dataFileName(iStart_subjID:end);
        subj                    = dataFileName(1:9);

        output_subj_dir_path    = fullfile(outputDirPath, subj);
        if ~exist(output_subj_dir_path, 'dir')
            mkdir(output_subj_dir_path);
        end

        % Display file name
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        disp(['Filename: ', filename]);

        % LOAD Spindles;
        % each line represents one detected spindle over all recorded electrodes
        load(fullfile(spindleDirPath, allFiles(nFile).name), 'SS');

        % LOAD Info
        load(fullfile(spindleDirPath, allFiles(nFile).name), 'Info');
        indexElectrode = find(strcmp(convertStringsToChars([Info.Electrodes.labels]), currentElectrode));

        % Display the number of detected spindles over all electrodes
        disp(['Found ', num2str(length(SS)) ' spindles over all electrodes and sleep stages'])

        if isempty(SS)
            continue
        end

        
        scoring     = reshape([SS.scoring], length(Info.Electrodes), length(SS))';      % detected spindles are marked with numbers indicating their sleep stage 
        refStarts 	= reshape([SS.Ref_Start], length(Info.Electrodes), length(SS))';    % spindle starts/onsets
        refEnds 	= reshape([SS.Ref_End], length(Info.Electrodes), length(SS))';      % spindle ends
        peak2peak 	= reshape([SS.Ref_Peak2Peak], length(Info.Electrodes), length(SS))';    % spindle peak to peak amplitude
        peakwav 	= reshape([SS.Ref_PeakWavelet], length(Info.Electrodes), length(SS))';    % spindle peak power

        indsSpFound = find(ismember(scoring(:,indexElectrode), indSleepStage));


        % Show spindles on specific electrode and scoring
        disp(['Found ' num2str(numel(indsSpFound)), ' spindles on ' currentElectrode ' for ' sleepStage]);

        
        % Overwrite text file with these infos
        sps_recap=fopen([mainDirPath '\sps_recap.txt'], 'a' );
        fprintf(sps_recap,[subj ' : ' num2str(numel(indsSpFound)) ' spindles on ' currentElectrode ' for ' sleepStage '\n']);
        fclose(sps_recap);     

        % Get onsets, in the ascending order, for spindles of interest only
        currSpStarts                = refStarts(indsSpFound, indexElectrode);
        [currSpStarts, sort_inds]   = sort(currSpStarts);
        currSpStarts                = currSpStarts/Info.Recording.sRate; % convert into seconds with accuracy level of 6 decimal digits

        % Get ends, in the same order as starts, for spindles of interest only
        currSpEnds	= refEnds(indsSpFound, indexElectrode);
        currSpEnds	= currSpEnds(sort_inds)/Info.Recording.sRate; % convert into seconds with accuracy level of 6 decimal digits
       
        % get the max peak 2 peak amp, in the same order, for spindles of interest only
        currSpPeaks  =  peak2peak(indsSpFound, indexElectrode);
        currSpPeaks	 =  currSpPeaks(sort_inds); % convert into seconds with accuracy level of 6 decimal digits

        % get the peak wavelet 
        currSpWavs   =  peakwav(indsSpFound, indexElectrode);
        currSpWavs	 =  currSpWavs(sort_inds); % convert into seconds with accuracy level of 6 decimal digits
        
        
        %% SET SPINLDE INFO
        
        spindles=struct([]);
        
        
        for i_sp = 1:numel(currSpStarts)
            currSpStart         	  = currSpStarts(i_sp);
            currSpEnd                 = currSpEnds(i_sp);
            currSpPeak                = double(currSpPeaks(i_sp));
            currSpWav                = currSpWavs(i_sp);
            
            spindles(i_sp).onset  	  = currSpStart;
            spindles(i_sp).duration	  = currSpEnd - currSpStart;
            spindles(i_sp).amplitude  = currSpPeak;
            spindles(i_sp).peakwav    = currSpWav;
            
            
        end

        outputFilePath = fullfile(output_subj_dir_path, [subj '_spindles_' currentElectrode '_' sleepStage '.mat']);
        save(outputFilePath, 'spindles');

        clear spindles
        
    end
    disp('---------------------------------------------------------------------------------------------');
    disp('Extraction of spindle info including onsets, duraiton and type - DONE!!!');
    disp(['The output has been saved into ' outputDirPath ' directory.']);
    disp('----------------------------------------------------------------------------------------------');
end

% clearvars;

