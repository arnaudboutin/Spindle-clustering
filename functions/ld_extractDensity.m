% ld_extractDensity
% 

clear all
clc

% Load eeglab
% addpath('/home/borear/Documents/Research/Source/matlab_toolboxes/eeglab');
% addpath('/home/borear/Documents/Research/Source/matlab_toolboxes/spindlesDetection');
% addpath(genpath('/home/borear/Documents/Research/Source/matlab_toolboxes/swa-matlab/'))

maindir = 'G:\eranet\EEG analysis\Spindles\output';
cd ([maindir]);

eegFolder = [maindir filesep 'Group_NoNap' filesep];
outputeegFolder = [maindir filesep 'Group_NoNap' filesep];

% Compute Density
% 1: Number of spindles / min
% 2: window for each spindle
computeDensity = 2;
if computeDensity == 1
    o_vars.computeDensity = 'Compute Density: Number of spindles / min';
else
    o_vars.computeDensity = 'Compute Local Density: window for each spindle';
    o_vars.computeDensityWindow = 30; % Seconds MidWindow
end
disp(o_vars.computeDensity)

% SleepStage
% 2: NREM2
% 3: NREM3
% 23: NREM2 and NREM3
o_vars.sleepStage = '2'; %sleepStage = '3' or sleepStage = '23'
if strcmp(o_vars.sleepStage,'2')
    indexSleepStage = '3'; % Hardcoded to check
    disp('Sleep stage: NREM2') 
elseif strcmp(o_vars.sleepStage,'3')
    indexSleepStage = '4'; % Hardcoded to check
    disp('Sleep stage: NREM3') 
elseif strcmp(o_vars.sleepStage,'23')
    indexSleepStage = '3:4'; % Hardcoded to check
	disp('Sleep stage: NREM2 and NREM3') 
end

% Electrodes
% 0: all Doesnt work anymore
% 1: Fz
% 2: Cz
% 3: Pz
% ....
currentElectrodes = 13;

% Subjects
allFiles = dir([ eegFolder '*.mat']); %dir([ eegFolder '*.dat']);

o_vars.spindles = zeros(1,length(allFiles));
o_vars.density = zeros(1,length(allFiles));
o_vars.scoring = zeros(1,length(allFiles));
o_vars.subjects = cell(1,length(allFiles));

for iFile=1:length(allFiles)
    
    % Input FileName
    i_name = allFiles(iFile).name(1:end);
    o_vars.subjects{iFile} = i_name;
    disp(i_name);
    
    % Load output spindles
    try
    i_SS = load([outputeegFolder i_name], 'SS');
    catch
%    i_SS = load([outputeegFolder 'o_SleepEEG_MSL_' i_name '_02_AllChannels.mat'], 'SS');
    end    
    i_SS = i_SS.SS;
        
    % Load output Informations
    try
    i_Infos = load([outputeegFolder i_name], 'Info');
    i_Infos = i_Infos.Info;
    catch
 %   i_Infos = load([outputeegFolder 'o_SleepEEG_MSL_' i_name '_02_AllChannels.mat'], 'Info');  
 %   i_Infos = i_Infos.Info;
    end
    
    try
        % Remove warnings
        warning('off','MATLAB:unknownElementsNowStruc')
        
        markers = load([eegFolder allFiles(iFile).name(1:end-3) 'mat']);
        scoring = markers.D.other.CRC.score{1,1};
        scoringLengthSecs = markers.D.other.CRC.score{3,1};
        disp('Old version with scoring within mat file')
    catch
        disp('New version with scoring in output file')
        scoring = i_Infos.markers.Scoring;
        scoringLengthSec = (scoring(2).position - scoring(1).position) * i_Infos.Recording.sRate;
        tmpScoring = ld_convertScoring2Num({scoring.description});
        scoring = tmpScoring;
        clear tmpScoring
    end

    %%     
    % Scoring for each participant
    scoring(isnan(scoring)) = 0;
    unqScoring = unique(scoring);
    countScoring=histc(scoring, unqScoring);

    if length(unqScoring) < 4  && strcmp(o_vars.sleepStage,'23')
        indexSleepStage = '3';
    elseif length(unqScoring) < 4 && strcmp(o_vars.sleepStage,'3')
        break
    end

    o_vars.scoring(iFile) = sum(countScoring(str2num(indexSleepStage))); %#ok<ST2NM>

    %%
    % Electrodes
    if currentElectrodes == 0 % doesnt work anymore :(
        o_vars.electrodes = '@ll';
        disp('Electrode: @ll')
        for nSp=1:length(i_SS) % Put NaNs where there is no spindle
            i_SS(nSp).Ref_Start(~i_SS(nSp).Ref_Start) = nan;
        end
    else
        disp(['Electrode: ',i_Infos.Electrodes(currentElectrodes).labels])
        o_vars.electrodes = i_Infos.Electrodes(currentElectrodes).labels;
        tmpSS = i_SS(1);
        
        index = currentElectrodes;
        
        for nSp=1:length(i_SS) % Get only Spindle which starts from a specific electrode
            i_SS(nSp).Ref_Start(~i_SS(nSp).Ref_Start) = nan;
%             [value, index] = min(i_SS(nSp).Ref_Start);
%             if index == currentElectrodes
            if ~isnan(i_SS(nSp).Ref_Start(index)) && i_SS(nSp).Ref_Frequency(index) > 11 &&  i_SS(nSp).Ref_Frequency(index) < 17
               tmpSS(end+1) = i_SS(nSp);
            end
        end
        tmpSS(1)= [];
        i_SS = tmpSS;
        clear tmpSS
    end
    
    %%
    % Compute Density
    
    switch computeDensity
        case 1 % Compute density using mean(nbSpindle/min)
           
            for nSp=1:length(i_SS)
%                 [value, index] = min(i_SS(nSp).Ref_Start);
                index = currentElectrodes;
                if ~isempty(strfind(o_vars.sleepStage, num2str(i_SS(nSp).scoring(index))))
                    o_vars.spindles(iFile) = o_vars.spindles(iFile) + 1; 
                end
            end
            o_vars.density(iFile) = o_vars.spindles(iFile) * 3 / o_vars.scoring(iFile);

        case 2 % window for each spindle
            
            % Density for each spindles that reaches the criteria of electrode and sleepStage
            currentSp = 0; % Spindle meet criteria
            localDensity = zeros(1, length(i_SS));
            for nSp=1:length(i_SS)
%                 [value, index] = min(i_SS(nSp).Ref_Start);
                index = currentElectrodes;
                value = i_SS(nSp).Ref_Start(index);
                % Check if spindles meet criteria of SleepStage
                if ~isempty(strfind(o_vars.sleepStage, num2str(i_SS(nSp).scoring(index))))
                    currentSp = currentSp + 1;
                     
                    
                    for lSp=1:length(i_SS) % for each spindle
%                         [tmpValue, tmpIndex] = min(i_SS(lSp).Ref_Start);
                        
                        tmpValue = i_SS(lSp).Ref_Start(index);
                        
                        % Check if spindles meet criteria of SleepStage
                        if ~isempty(strfind(o_vars.sleepStage, num2str(i_SS(lSp).scoring(index))))
                            
                            % Check if spindle is within the window
                            if (abs(value - tmpValue)/ i_Infos.Recording.sRate <= o_vars.computeDensityWindow)
                                localDensity(currentSp) =  localDensity(currentSp) + 1;
                            end
                        end
                    end
                end
            end
            localDensity = localDensity(localDensity~=0);
            o_vars.density(iFile) = mean(localDensity);
            o_vars.spindles(iFile) = sum(localDensity);
    end % End of switch
end

output = ['NoNap_' o_vars.electrodes '_NREM' o_vars.sleepStage '_Density' num2str(computeDensity) '.mat'];
save(output,'o_vars')