%% MEG Data Analysis - Subject Level

% Note: This script completes subject-level analyses, including loading the
% behavioral log and MEG files, extracting events of interest, cutting
% epcohs, and plotting/visualizing the data.

% Channel Dictionary: 
% UADC007 = button press
% UADC008 = button press
% UADC009 = EyeLink
% UADC010 = EyeLink
% UADC013 = EyeLink
% UADC016 = pixel channel
% UPPT001 = parrallel port

% Written by: Sharif I. Kronemer
% Last Modified: 7/19/2025

clear all

%% Directories & Paths

% Root dir
root_dir = '/Users/kronemersi/Library/CloudStorage/OneDrive-NationalInstitutesofHealth';

% Add paths
addpath(genpath(fullfile(root_dir,'General_Analysis_Tools/Behavioral_Analysis')))
addpath(genpath(fullfile(root_dir,'General_Analysis_Tools/spm12/external')))
addpath(fullfile(root_dir,'Real_Time_Perception_Study/Analysis/Analysis_Code/MEG_Analysis'))
addpath(fullfile(root_dir,'/Real_Time_Perception_Study/Analysis/Analysis_Code/MEG_Analysis/fieldtrip-20230503/template/layout'))
addpath(fullfile(root_dir,'/Real_Time_Perception_Study/Analysis/Analysis_Code/MEG_Analysis/fieldtrip-20230503/plotting'))
addpath(genpath(fullfile(root_dir,'Analysis_Code/EyeLink/Permutation_Analysis')))
   
% Subject ID
subject_list = {'P4'};

% Create visualization (y or n)
create_visualization = 'n';

% Run analysis or load previous data
% 'load' and 'run'
run_or_load = 'load';

%% Loop over Subject
% Loop over subjects
for sub = 1:length(subject_list)

    % Define Subject ID
    subID = subject_list{sub};

    disp(['Running subject ', subID,'...'])

    % Data directory
    data_dir = fullfile(root_dir,'Cortical_Blindness_Study/Data',subID,'MEG_1');

    % Define behavioral file
    beh_dir = fullfile(data_dir,'Behavior');

    % Output directory
    output_dir = fullfile(root_dir,'Cortical_Blindness_Study/Analysis/Subject_Analysis/',subID,'MEG_1','MEG');
    
    % Check if output dir exists; create it if not
    if isempty(dir(output_dir))
    
        mkdir(output_dir)
    
    end 
    
    % MEG parent folders
    parent_folder = dir(fullfile(data_dir,'MEG'));
    
    % MEG file names
    run_folders = dir(fullfile(data_dir,'MEG',parent_folder(1).name,'*ds'));
    
    % Log file
    log_file = dir([fullfile(beh_dir,'*.log')]);
    
    %% Analysis Parameters

    % Sampling rate (Hz)
    sampling_rate = 1200;

    % ISI event time - min max intervals
    % Note: These values are given in milliseconds assuming 1000 Hz
    min_ISI = 4000;
    min_ISI = min_ISI*(sampling_rate/1000);
    
    max_ISI = 7000;
    max_ISI = max_ISI*(sampling_rate/1000);
    
    ISI_event_time = [min_ISI,max_ISI];

    % Epoch duration
    % Note: Enter as milliseconds assuming 1000Hz 
    half_epoch_duration = 4000;
    half_epoch_duration = half_epoch_duration*(sampling_rate/1000);

    % Baseline interval
    baseline_duration = 1000;
    baseline_duration = baseline_duration*(sampling_rate/1000);

    % Define MEG channels 
    % Note: Check the header file for channel label information
    MEG_channels = 30:298;

    % Topoplot time interval
    % Note: Relative to stimulus onset (0) and in milliseconds assuming 1000Hz
    topoplot_min = -500;
    topoplot_min = (topoplot_min*(sampling_rate/1000))+half_epoch_duration;
    
    topoplot_max = 4000;
    topoplot_max = (topoplot_max*(sampling_rate/1000))+half_epoch_duration;

    topoplot_interval = 500;
    topoplot_interval = topoplot_interval*(sampling_rate/1000);

    %% Run New Analysis
    if isequal(run_or_load,'run')

        %% Open Behavioral Log File
        
        % If more than one log file is found in single session
        if size(log_file,1) > 1
        
            continue
    
        % If only one file present, use this one for analysis
        else
            
            file_num = 1;
        
        end
        
        % Include all files and combine them
        if isequal(file_num,'All')
        
            % Initialize raw matrix
            log_data = {};
        
            % Loop over the files
            for current_file = 1:size(log_file,1)
        
                % Open log data file
                log_current_file = importdata(fullfile(beh_dir,log_file(current_file).name));
        
                % Combine file
                log_data = [log_data; log_current_file];
        
            end
        
        % Bracketed time
        elseif length(file_num) > 1
        
            % Initialize raw matrix
            log_data = {};
        
            % Loop over the files
            for current_file = file_num
        
                % Open log data file
                log_current_file = importdata(fullfile(beh_dir,log_file(current_file).name));
        
                % Combine file
                log_data = [log_data; log_current_file];
        
            end
        
        % Read the individual log file
        else 
        
            % Open log data
            cd(beh_dir)
            log_data = importdata(log_file(file_num).name);
        
        end
        
        %% Find Events of Interest from Log File
        
        % Initialize event variables
        block_onset_row = [];
        
        % Mine log file for specific string variables and store rows
        for row = 1:size(log_data,1)
    
            % Find the block start
            if any(~cellfun('isempty',strfind(log_data(row),'Block #')))
        
                block_onset_row = [block_onset_row; row];
            
            end
        
        end
        
        % Check the number of blocks/MEG folders match
        if ~isequal(size(run_folders,1),length(block_onset_row))
        
            error('MEG and log file block # mismatch!')
        
        end
        
        %% Extract MEG Data and Events
        
        % Load FieldTrip (Note: There can be some permission/privacy alerts)
        disp('Load FieldTrip...')
        ft_defaults
       
        % Initialize cross block variables 
        % Note: MEG version of study did not have the isoluminate or white stimulus
        distractor_plus_location_array = [];
        distractor_cross_location_array = [];
        glare_stimuli_sighted_epochs = [];
        glare_stimuli_blinded_epochs = [];
        nonglare_stimuli_sighted_epochs = [];
        nonglare_stimuli_blinded_epochs = [];

        ISI_distractor_plus_location_array = [];
        ISI_distractor_cross_location_array = [];        
        ISI_glare_stimuli_sighted_epochs = [];
        ISI_glare_stimuli_blinded_epochs = [];
        ISI_nonglare_stimuli_sighted_epochs = [];
        ISI_nonglare_stimuli_blinded_epochs = [];
    
        % Non-target and all target epochs
        nontarget_stimuli_sighted_epochs = [];
        nontarget_stimuli_blinded_epochs = [];
        distractor_stimuli_sighted_epochs = [];
        distractor_stimuli_blinded_epochs = [];
        
        ISI_distractor_stimuli_sighted_epochs = [];
        ISI_distractor_stimuli_blinded_epochs = [];
        ISI_nontarget_stimuli_sighted_epochs = [];
        ISI_nontarget_stimuli_blinded_epochs = [];
    
        % Loop over MEG runs
        for run = 1:size(run_folders,1)
        
            disp(['Running MEG block #',num2str(run)])
    
            % Initialize subject-file event variables
            glare_location_array = [];
            nonglare_location_array = [];
            iso_location_array = [];
            white_location_array = [];
            distractor_location_array = [];
            all_stimuli_type_array = [];
        
            % Run data directory 
            run_data_dir = fullfile(data_dir,'MEG',parent_folder(1).name,run_folders(run).name);
        
            %% Extract Block Log File Info
                
            % If the current run is less the total # runs
            if run < size(run_folders,1)
        
                rate_prune_rows = block_onset_row(run):block_onset_row(run+1);
        
            % If the current run is equal to the total # runs
            else
        
                rate_prune_rows = block_onset_row(run):size(log_data,1);
        
            end
            
            % Search log within the current block rows
            for row = rate_prune_rows
            
                % All stimuli type array
                if any(~cellfun('isempty',strfind(log_data(row),'All Stimuli Type Array')))
            
                    % Extract row string
                    row_string = cell2mat(log_data(row));
            
                    % Bracket index
                    bracket_1 = strfind(row_string,'[');
                    bracket_2 = strfind(row_string,']');
            
                    % If end bracket not found
                    if isempty(bracket_2)
            
                        row_string_2 = cell2mat(log_data(row+1));                    
                        bracket_2 = strfind(row_string_2,']');
            
                    end
            
                    % Locations
                    if ~isempty(row_string_2)
            
                        % Setup arrays to combine
                        array_1 = row_string(bracket_1:end);
                        array_2 = row_string_2(1:bracket_2);
            
                        % Combine arrays
                        location_array = str2num([array_1,array_2]);
            
                    else
                    
                        location_array = str2num(row_string(bracket_1:bracket_2));
            
                    end
            
                    % Add block location array
                    all_stimuli_type_array = [all_stimuli_type_array; location_array];
            
                % Glare stimulus array
                elseif any(~cellfun('isempty',strfind(log_data(row),'Glare Stimuli Location Array')))
            
                    % Extract row string
                    row_string = cell2mat(log_data(row));
            
                    % Bracket index
                    bracket_1 = strfind(row_string,'[');
                    bracket_2 = strfind(row_string,']');
            
                    % Locations
                    location_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add block location array
                    glare_location_array = [glare_location_array; location_array];
            
                % Nonglare stimulus array
                % Note: Old version of the task had different naming of
                % nonglare stimulus
                elseif any(~cellfun('isempty',strfind(log_data(row),'Non Glare Stimuli Location Array'))) || ...
                        any(~cellfun('isempty',strfind(log_data(row),'Nonglare Stimuli Location Array')))
                   
                    % Extract row string
                    row_string = cell2mat(log_data(row));
            
                    % Bracket index
                    bracket_1 = strfind(row_string,'[');
                    bracket_2 = strfind(row_string,']');
            
                    % Locations
                    location_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add block location array
                    nonglare_location_array = [nonglare_location_array; location_array];
            
                % Iso stimulus array
                elseif any(~cellfun('isempty',strfind(log_data(row),'Iso Stimuli Location Array')))
                   
                    % Extract row string
                    row_string = cell2mat(log_data(row));
            
                    % Bracket index
                    bracket_1 = strfind(row_string,'[');
                    bracket_2 = strfind(row_string,']');
            
                    % Locations
                    location_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add block location array
                    iso_location_array = [iso_location_array; location_array];
            
                % White stimulus array
                elseif any(~cellfun('isempty',strfind(log_data(row),'White Stimuli Location Array')))
                   
                    % Extract row string
                    row_string = cell2mat(log_data(row));
            
                    % Bracket index
                    bracket_1 = strfind(row_string,'[');
                    bracket_2 = strfind(row_string,']');
            
                    % Locations
                    location_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add block location array
                    white_location_array = [white_location_array; location_array];
            
                % Distractor stimulus array
                % Note: This is relevant for an earlier task version (v7) without
                % the cross/plus distractor types
                elseif any(~cellfun('isempty',strfind(log_data(row),'Distractor Stimuli Location Array')))
                   
                    % Extract row string
                    row_string = cell2mat(log_data(row));
            
                    % Bracket index
                    bracket_1 = strfind(row_string,'[');
                    bracket_2 = strfind(row_string,']');
            
                    % Locations
                    location_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add block location array
                    distractor_location_array = [distractor_location_array; location_array];
            
                % Distractor stimulus plus array
                elseif any(~cellfun('isempty',strfind(log_data(row),'Distractor Plus Stimuli Location Array')))
                   
                    % Extract row string
                    row_string = cell2mat(log_data(row));
            
                    % Bracket index
                    bracket_1 = strfind(row_string,'[');
                    bracket_2 = strfind(row_string,']');
            
                    % Locations
                    location_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add block location array
                    distractor_plus_location_array = [distractor_plus_location_array; location_array];
            
                % Distractor stimulus plus array
                elseif any(~cellfun('isempty',strfind(log_data(row),'Distractor Cross Stimuli Location Array')))
                   
                    % Extract row string
                    row_string = cell2mat(log_data(row));
            
                    % Bracket index
                    bracket_1 = strfind(row_string,'[');
                    bracket_2 = strfind(row_string,']');
            
                    % Locations
                    location_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add block location array
                    distractor_cross_location_array = [distractor_cross_location_array; location_array];
            
                end
            
            end 
    
            %% Load MEG Data/Header
        
            disp('Loading and restructuring data...')
            
            % Data matrix (electrodes x time x trials); Note: trials are arbitarily
            % cut epochs by the MEG system and do not represent some actually task
            % increment.
            meg4_file = dir(fullfile(run_data_dir,'*.meg4'));
            run_data = ft_read_data(fullfile(run_data_dir,meg4_file(1).name));
            
            % Header file
            header_file = dir(fullfile(run_data_dir,'*.res4'));
            run_header = ft_read_header(fullfile(run_data_dir,header_file(1).name));

            % Find MEG channels
            MEG_channels = find(strcmp(run_header.chantype,'meggrad'));
            
            % Find the trigger channels - parallel port and pixel channels
            parallel_channel = find(strcmp('UPPT001',run_header.label));
            pixel_channel = find(strcmp('UADC016',run_header.label));
        
            % Find the button press channels
            button_1_channel = find(strcmp('UADC007',run_header.label));
            button_2_channel = find(strcmp('UADC008',run_header.label));
        
            %% Extract MEG Trigger Times
        
            % Note: The MEG data is collected in "trials" that are continuous
            % series of data. To return to a continuous time vector, the trials can
            % be concatenated. 
            
            % Collapse the data across trials 
            parallel_data = [];
            pixel_data = [];
            button_1_data = [];
            button_2_data = [];
            MEG_data = [];
            
            % Loop over trials and add to full data variable
            % Note: This is necessary because the continuous MEG data is stored in
            % trial segements
            for trial = 1:size(run_data,3)
            
                % Extract the data
                parallel_data = [parallel_data,run_data(parallel_channel,:,trial)];
                button_1_data = [button_1_data,run_data(button_1_channel,:,trial)];
                button_2_data = [button_2_data,run_data(button_2_channel,:,trial)];
                MEG_data = [MEG_data,run_data(MEG_channels,:,trial)];
    
            end
                  
            % Modify button data to help detect onset and offset - the button pulse
            % appears as an right side up square wave
            % Note: Set all values less than 0 to zero; set all values greater than
            % 3 to 0; this help manage some artifact in the trigger pulse 
            button_1_data(button_1_data > 3) = 0;
            button_1_data(button_1_data < 0) = 0;
            button_2_data(button_2_data > 3) = 0;
            button_2_data(button_2_data < 0) = 0;
        
            %% Find Trigger/Pixel Events
            
            % Parallel port trigger
        
            % Take 1st derivative
            parallel_diff_data = diff(parallel_data);
            
            % Find peaks - outputs = peak values and time points/sample
            [start_pp_peaks, start_event_trigger] = findpeaks(parallel_diff_data);
            [end_pp_peaks, end_event_trigger] = findpeaks(-parallel_diff_data);
            
            % Remove the first trigger event that corresponds with the block onset
            start_event_trigger(1) = [];
            end_event_trigger(1) = [];
            start_pp_peaks(1) = [];
            end_pp_peaks(1) = [];
        
            % Find the trigger durations
            pp_duration = end_event_trigger - start_event_trigger;
                  
            % Special case with 115/block 1; recording did not begin until
            % halfway through the behavioral task
            if isequal(subID,'115') && isequal(run,1)
            
               all_stimuli_type_array(1:length(all_stimuli_type_array)-length(start_event_trigger)) = [];
            
            end

            % Check the number of triggers equals trial events
            if ~isequal(length(start_event_trigger),length(end_event_trigger),length(all_stimuli_type_array))
    
                error('Number of stimuli and triggers mismatch!')
    
            end
        
            %% Preprocess the MEG Data
        
            disp('Preprocess MEG data...')
        
            % Setup preprocessing parameters
            cfg = [];
            cfg.continuous = 'yes'; % Data is continuous
            cfg.bpfilter = 'yes'; % Bandpass filter
            cfg.bpfreq = [0.1 115]; % Bandpass low frequency and high frequency
            cfg.dftfilter = 'yes'; % Line noise removal
            cfg.dftfreq = [60 120]; % Line noise frequency bands to remove
            cfg.dataset = run_data_dir;
        
            % Run FieldTrip preprocessing function
            MEG_proc_struct = ft_preprocessing(cfg);
        
            % Extract data
            MEG_proc_data = cell2mat(MEG_proc_struct.trial);
            MEG_proc_data = MEG_proc_data(MEG_channels,:);
            MEG_sensor_labels = MEG_proc_struct.label(MEG_channels);
        
            % Visually compare raw and preprocessed data
            if isequal(create_visualization,'y')
        
                % Extract pre and post-processed data
                test_data = MEG_data(1,1:1000);
                test_data = test_data - nanmean(test_data);
        
                % Plot
                figure 
                hold on
    
                plot(MEG_proc_data(1,1:1000))
                plot(test_data)
    
            end
        
            %% Cut Epochs and Add to Epoch Variable
    
            disp('Cutting epochs...')
        
            % Epoch addition counter
            glare_counter = 0;
            nonglare_counter = 0;
            distractor_counter = 0;
            cross_distractor_counter = 0;
            plus_distractor_counter = 0;
            ISI_counter = 0;

            % Projector delay (19ms - calculated with 100 participants)
            projector_delay = 19;

            % Create random ISI idx
            ISI_start_event_trigger = randi(ISI_event_time,1,size(start_event_trigger,2));

            % Loop over trigger events
            for event = 1:size(start_event_trigger,2)
        
                % Define current event time
                % Note: 1 frame correction for delay of projector display
                event_time = start_event_trigger(event)+projector_delay;
                ISI_time = ISI_start_event_trigger(event);

                % Epoch start/end
                epoch_start = event_time - half_epoch_duration;
                epoch_end = event_time + half_epoch_duration;

                ISI_epoch_start = event_time - half_epoch_duration + ISI_time;
                ISI_epoch_end = event_time + half_epoch_duration + ISI_time;
        
                % Cut epoch (channels x time)
                epoch_data = MEG_proc_data(:,epoch_start:epoch_end);
                ISI_epoch_data = MEG_proc_data(:,ISI_epoch_start:ISI_epoch_end);

                % Baseline epoch (pre-stimulus interval)
                epoch_data = epoch_data - nanmean(epoch_data(:,half_epoch_duration - baseline_duration:half_epoch_duration),2);
                ISI_epoch_data = ISI_epoch_data - nanmean(ISI_epoch_data(:,half_epoch_duration - baseline_duration:half_epoch_duration),2);

                % Check stimulus type
    
                % Glare
                if all_stimuli_type_array(event) == 0
    
                    % Add to counter
                    glare_counter = glare_counter+1;
    
                    % Location 1
                    % Note: How the locations are organized by sighted and
                    % blinded is unique to subject P4 - alternative if
                    % statments required to satisfy other patient visual
                    % field ability
                    if isequal(glare_location_array(glare_counter),1)
   
                        glare_stimuli_sighted_epochs = cat(3,epoch_data, glare_stimuli_sighted_epochs);
                        nontarget_stimuli_sighted_epochs = cat(3,epoch_data, nontarget_stimuli_sighted_epochs);

                        ISI_glare_stimuli_sighted_epochs = cat(3,ISI_epoch_data, ISI_glare_stimuli_sighted_epochs);
                        ISI_nontarget_stimuli_sighted_epochs = cat(3,ISI_epoch_data, ISI_nontarget_stimuli_sighted_epochs);

                    % Location 2
                    else 
    
                        glare_stimuli_blinded_epochs = cat(3,epoch_data, glare_stimuli_blinded_epochs);
                        nontarget_stimuli_blinded_epochs = cat(3,epoch_data, nontarget_stimuli_blinded_epochs);

                        ISI_glare_stimuli_blinded_epochs = cat(3,ISI_epoch_data, ISI_glare_stimuli_blinded_epochs);
                        ISI_nontarget_stimuli_blinded_epochs = cat(3,ISI_epoch_data, ISI_nontarget_stimuli_blinded_epochs);

                    end
    
                % Nonglare
                elseif all_stimuli_type_array(event) == 1
                    
                    % Add to counter
                    nonglare_counter = nonglare_counter+1;
    
                    % Location 1
                    if isequal(glare_location_array(nonglare_counter),1)
    
                        nonglare_stimuli_sighted_epochs = cat(3,epoch_data, nonglare_stimuli_sighted_epochs);
                        nontarget_stimuli_sighted_epochs = cat(3,epoch_data, nontarget_stimuli_sighted_epochs);

                        ISI_nonglare_stimuli_sighted_epochs = cat(3,ISI_epoch_data, ISI_nonglare_stimuli_sighted_epochs);
                        ISI_nontarget_stimuli_sighted_epochs = cat(3,ISI_epoch_data, ISI_nontarget_stimuli_sighted_epochs);

                    % Location 2
                    else 

                       nonglare_stimuli_blinded_epochs = cat(3,epoch_data, nonglare_stimuli_blinded_epochs);
                       nontarget_stimuli_blinded_epochs = cat(3,epoch_data, nontarget_stimuli_blinded_epochs);

                       ISI_nonglare_stimuli_blinded_epochs = cat(3,ISI_epoch_data, ISI_nonglare_stimuli_blinded_epochs);
                       ISI_nontarget_stimuli_blinded_epochs = cat(3,ISI_epoch_data, ISI_nontarget_stimuli_blinded_epochs);

                    end
    
                % Cross Distractor
                elseif all_stimuli_type_array(event) == 5 
    
                    % Add to counter
                    cross_distractor_counter = cross_distractor_counter+1;
    
                    % Location 1
                    % Note: Cross and plus distractor events are stored
                    % together in one distractor variable but considered
                    % separately because of unique locaiton arrays
                    if isequal(distractor_cross_location_array(cross_distractor_counter),1)

                        distractor_stimuli_sighted_epochs = cat(3,epoch_data, distractor_stimuli_sighted_epochs);
                        ISI_distractor_stimuli_sighted_epochs = cat(3,ISI_epoch_data, ISI_distractor_stimuli_sighted_epochs);

                    % Location 2
                    else 

                       distractor_stimuli_blinded_epochs = cat(3,epoch_data, distractor_stimuli_blinded_epochs);
                       ISI_distractor_stimuli_blinded_epochs = cat(3,ISI_epoch_data, ISI_distractor_stimuli_blinded_epochs);

                    end
    
                % Plus Distractor
                elseif all_stimuli_type_array(event) == 4
    
                    % Add to counter
                    plus_distractor_counter = plus_distractor_counter+1;
    
                    % Location 1
                    if isequal(distractor_plus_location_array(plus_distractor_counter),1)
    
                        distractor_stimuli_sighted_epochs = cat(3,epoch_data, distractor_stimuli_sighted_epochs);
                        ISI_distractor_stimuli_sighted_epochs = cat(3,ISI_epoch_data, ISI_distractor_stimuli_sighted_epochs);

                    % Location 2
                    else 
    
                       distractor_stimuli_blinded_epochs = cat(3,epoch_data, distractor_stimuli_blinded_epochs);
                       ISI_distractor_stimuli_blinded_epochs = cat(3,ISI_epoch_data, ISI_distractor_stimuli_blinded_epochs);

                    end
    
                end
    
            end
        
        end

        % Save data
        cd(output_dir)
        save MEG_epochs.mat glare* nonglare* distractor* nontarget* ISI* -v7.3
    
    %% Load Previous Analysis Results
    else
    
        disp('Loading data...')
        load(fullfile(output_dir,"MEG_epochs.mat"))
    
    end

    %% Permutation Analysis

    % Statistical Parameters

    % Channel to test
    test_channel = 65;

    % Number of permutations
    num_permutations = 5000;
    
    % Are samples dependent (default is true)
    dependent_samples = 'true';
    
    % Define alpha threshold
    p_threshold = 0.05;
    
    % Two-sided
    two_sided = 'true';

    % Permutation baseline
    % Note: Enter as milliseconds assuming 1000Hz 
    perm_baseline_time = 500;
    perm_baseline_time = perm_baseline_time*(sampling_rate/1000);
    perm_baseline = half_epoch_duration-perm_baseline_time:half_epoch_duration;

    % Query interval
    % Note: Enter as milliseconds assuming 1000Hz 
    perm_query_int_time = 500;%250;
    perm_query_int_time = perm_query_int_time*(sampling_rate/1000);
    perm_query_int = half_epoch_duration+1:half_epoch_duration+perm_query_int_time;

    % Create combined ISI data (mean across the 3D matrices)
    ISI_nontarget_stimuli_all_epochs = (ISI_nontarget_stimuli_sighted_epochs+ISI_nontarget_stimuli_blinded_epochs)/2;

    % Define event types
    %group_list = {{'nontarget_stimuli_sighted_epochs','ISI_nontarget_stimuli_all_epochs'};...
    %    {'nontarget_stimuli_blinded_epochs','ISI_nontarget_stimuli_all_epochs'};...
    %    {'nontarget_stimuli_sighted_epochs','nontarget_stimuli_blinded_epochs'}};
    group_list = {{'nontarget_stimuli_sighted_epochs','ISI_nontarget_stimuli_sighted_epochs'};...
        {'nontarget_stimuli_blinded_epochs','ISI_nontarget_stimuli_blinded_epochs'};...
        {'nontarget_stimuli_sighted_epochs','nontarget_stimuli_blinded_epochs'}};

     % Loop over event types
    for event = 1:length(group_list)
    
        % Define current phase type
        event_type = group_list{event};

        disp(['Running stats ',event_type{1},' vs ', event_type{2},'...'])

        % Rename data to generic variable (channel x time x trials)
        data_1 = eval(event_type{1});
        data_2 = eval(event_type{2});
    
        % Select channel to test
        data_1 = squeeze(data_1(test_channel,:,:));
        data_2 = squeeze(data_2(test_channel,:,:));
    
        %% Main and Subtraction Epoch Subtraction and Baseline 
        
        % Data 1
    
        % Calculate baseline values [subjects]
        group_1_baseline = squeeze(nanmean(data_1(perm_baseline,:),1));
    
        % Convert baseline [time x subjects]
        group_1_baseline = repmat(group_1_baseline,[size(data_1,1),1]);
    
        % Subtract baseline from main data
        group_1_baselined_data = data_1 - group_1_baseline;
    
        % Data 2
    
        % Calculate baseline values [subjects]
        group_2_baseline = squeeze(nanmean(data_2(perm_baseline,:),1));
    
        % Convert baseline [time x subjects]
        group_2_baseline = repmat(group_2_baseline,[size(data_2,1),1]);
    
        % Subtract baseline from main data
        group_2_baselined_data = data_2 - group_2_baseline;
    
        %% Run Permutation Tests
    
        disp('Running permutation test')
    
        tic
    
        % Perm testing
        [clusters, pval, t_sums, permutation_distribution] = permutest_TimeCourses(group_1_baselined_data(perm_query_int,:), group_2_baselined_data(perm_query_int,:), dependent_samples, ...
            p_threshold, num_permutations, two_sided);
    
        toc 
    
        % Find significant clusters pvalue < 0.05
        sig_clust = find(pval < 0.05);
    
        % Find the significant time points
        sig_time_pts = sort([clusters{sig_clust}]);
    
        % Update sig_times_pts to match epoch length
        sig_time_pts = sig_time_pts + min(perm_query_int);
    
        % Save output
        cd(output_dir)
        save(['perm_results_',event_type{1},'_vs_',event_type{2},'.mat'],'clusters','pval','t_sums','permutation_distribution','sig_clust','sig_time_pts');

    end

    %% Average Across Epochs within Subject

    % Average across epochs (channel x time x epochs)
    mean_glare_sighted_epochs = nanmean(glare_stimuli_sighted_epochs,3);
    mean_nonglare_sighted_epochs = nanmean(nonglare_stimuli_sighted_epochs,3);
    mean_distractor_sighted_epochs = nanmean(distractor_stimuli_sighted_epochs,3);
    mean_nontarget_sighted_epochs = nanmean(nontarget_stimuli_sighted_epochs,3);

    mean_glare_blinded_epochs = nanmean(glare_stimuli_blinded_epochs,3);
    mean_nonglare_blinded_epochs = nanmean(nonglare_stimuli_blinded_epochs,3);
    mean_distractor_blinded_epochs = nanmean(distractor_stimuli_blinded_epochs,3);
    mean_nontarget_blinded_epochs = nanmean(nontarget_stimuli_blinded_epochs,3);

    mean_ISI_glare_sighted_epochs = nanmean(ISI_glare_stimuli_sighted_epochs,3);
    mean_ISI_nonglare_sighted_epochs = nanmean(ISI_nonglare_stimuli_sighted_epochs,3);
    mean_ISI_distractor_sighted_epochs = nanmean(ISI_distractor_stimuli_sighted_epochs,3);
    mean_ISI_nontarget_sighted_epochs = nanmean(ISI_nontarget_stimuli_sighted_epochs,3);

    mean_ISI_glare_blinded_epochs = nanmean(ISI_glare_stimuli_blinded_epochs,3);
    mean_ISI_nonglare_blinded_epochs = nanmean(ISI_nonglare_stimuli_blinded_epochs,3);
    mean_ISI_distractor_blinded_epochs = nanmean(ISI_distractor_stimuli_blinded_epochs,3);
    mean_ISI_nontarget_blinded_epochs = nanmean(ISI_nontarget_stimuli_blinded_epochs,3);

    mean_ISI_nontarget_all_epochs = nanmean(cat(3,ISI_nontarget_stimuli_sighted_epochs,ISI_nontarget_stimuli_blinded_epochs),3);

    % SEM calculation
    SEM_glare_sighted_epochs = std(glare_stimuli_sighted_epochs,[],3)/sqrt(size(glare_stimuli_sighted_epochs,3));
    SEM_glare_blinded_epochs = std(glare_stimuli_blinded_epochs,[],3)/sqrt(size(glare_stimuli_blinded_epochs,3));
    SEM_ISI_glare_sighted_epochs = std(ISI_glare_stimuli_sighted_epochs,[],3)/sqrt(size(ISI_glare_stimuli_sighted_epochs,3));
    SEM_ISI_glare_blinded_epochs = std(ISI_glare_stimuli_blinded_epochs,[],3)/sqrt(size(ISI_glare_stimuli_blinded_epochs,3));

    SEM_nonglare_sighted_epochs = std(nonglare_stimuli_sighted_epochs,[],3)/sqrt(size(nonglare_stimuli_sighted_epochs,3));
    SEM_nonglare_blinded_epochs = std(nonglare_stimuli_blinded_epochs,[],3)/sqrt(size(nonglare_stimuli_blinded_epochs,3));
    SEM_ISI_nonglare_sighted_epochs = std(ISI_nonglare_stimuli_sighted_epochs,[],3)/sqrt(size(ISI_nonglare_stimuli_sighted_epochs,3));
    SEM_ISI_nonglare_blinded_epochs = std(ISI_nonglare_stimuli_blinded_epochs,[],3)/sqrt(size(ISI_nonglare_stimuli_blinded_epochs,3));

    SEM_distractor_sighted_epochs = std(distractor_stimuli_sighted_epochs,[],3)/sqrt(size(distractor_stimuli_sighted_epochs,3));
    SEM_distractor_blinded_epochs = std(distractor_stimuli_blinded_epochs,[],3)/sqrt(size(distractor_stimuli_blinded_epochs,3));
    SEM_ISI_distractor_sighted_epochs = std(ISI_distractor_stimuli_sighted_epochs,[],3)/sqrt(size(ISI_distractor_stimuli_sighted_epochs,3));
    SEM_ISI_distractor_blinded_epochs = std(ISI_distractor_stimuli_blinded_epochs,[],3)/sqrt(size(ISI_distractor_stimuli_blinded_epochs,3));

    SEM_nontarget_sighted_epochs = std(nontarget_stimuli_sighted_epochs,[],3)/sqrt(size(nontarget_stimuli_sighted_epochs,3));
    SEM_nontarget_blinded_epochs = std(nontarget_stimuli_blinded_epochs,[],3)/sqrt(size(nontarget_stimuli_blinded_epochs,3));
    SEM_ISI_nontarget_sighted_epochs = std(ISI_nontarget_stimuli_sighted_epochs,[],3)/sqrt(size(ISI_nontarget_stimuli_sighted_epochs,3));
    SEM_ISI_nontarget_blinded_epochs = std(ISI_nontarget_stimuli_blinded_epochs,[],3)/sqrt(size(ISI_nontarget_stimuli_blinded_epochs,3));

    SEM_ISI_nontarget_all_epochs = std(cat(3,ISI_nontarget_stimuli_sighted_epochs,ISI_nontarget_stimuli_blinded_epochs),[],3)/...
        sqrt(size(cat(3,ISI_nontarget_stimuli_sighted_epochs,ISI_nontarget_stimuli_blinded_epochs),3));

    % Average over channels left occiptial channels
    LO_mean_nontarget_sighted_epochs = nanmean(mean_nontarget_sighted_epochs(55:73,:),1);
    LO_mean_nontarget_blinded_epochs = nanmean(mean_nontarget_blinded_epochs(55:73,:),1);
    LO_mean_ISI_nontarget_all_epochs = nanmean(mean_ISI_nontarget_all_epochs(55:73,:),1);

    RO_mean_nontarget_sighted_epochs = nanmean(mean_nontarget_sighted_epochs(186:203,:),1);
    RO_mean_nontarget_blinded_epochs = nanmean(mean_nontarget_blinded_epochs(186:203,:),1);
    RO_mean_ISI_nontarget_all_epochs = nanmean(mean_ISI_nontarget_all_epochs(186:203,:),1);

    %% Visualize Results - Topoplots
    %{
    % % Setup preprocessing parameters
    % cfg = [];
    % cfg.continuous = 'yes'; % Data is continuous
    % cfg.bpfilter = 'yes'; % Bandpass filter
    % cfg.bpfreq = [0.1 115]; % Bandpass low frequency and high frequency
    % cfg.dftfilter = 'yes'; % Line noise removal - needs further testing
    % cfg.dftfreq = [60 120]; % Line noise frequency bands to remove
    % cfg.dataset = output_dir;
    % 
    % % Run FieldTrip preprocessing function
    % MEG_proc_struct = ft_preprocessing(cfg);

    % Prepare data struct
    cfg = [];
    epoch_data = ft_timelockanalysis(cfg,MEG_proc_struct);

    % Define channels
    epoch_data.label = epoch_data.label(MEG_channels);
    
    cfg = [];
    %cfg.xlim = [-0.4:0.2:1.4];
    %cfg.zlim = [-1e-27 1e-27];
    %cfg.baseline = [-0.5 -0.1];
    %cfg.baselinetype = 'relative';
    cfg.layout = 'CTF275_helmet';
    cfg.colorbar = 'East'; % Colorbar location
    cfg.zlim = [-1E-13 1E-13]; % Colorbar scale
    cfg.xlim = [topoplot_min:topoplot_interval:topoplot_max]; %[900:120:2400];
    cfg.ylim = [15 25];
    cfg.parameter = 'avg';
    cfg.colormap = '*RdBu';%'jet';
    cfg.style = 'both';
    cfg.comment = 'xlim';
    cfg.marker = 'off';
    cfg.markersymbol = 'o';
    cfg.markercolor = [0 0 0];
    cfg.commentpos = 'title';
    
    % Prepare structure
    epoch_data.dof = [];
    epoch_data.var = [];
    epoch_data.time = [1:(half_epoch_duration*2)+1];
    
    % Sighted
    %epoch_data.avg = mean_nontarget_sighted_epochs;
    epoch_data.avg = mean_distractor_sighted_epochs;

    % Plot figure
    figure; ft_topoplotER(cfg,epoch_data);
    
    % Blinded
    %epoch_data.avg = mean_nontarget_blinded_epochs';
    epoch_data.avg = mean_distractor_blinded_epochs;

    % Plot figure
    figure; ft_topoplotER(cfg,epoch_data);
    %}
    
    %% Visualize Results - Timecourses

    % Update renderer
    set(0, 'DefaultFigureRenderer', 'painters');

    % Average sensory

     % Plot mean epoch timecourses
    
    % Setup timevector
    timevector = -(half_epoch_duration):half_epoch_duration;
    
    % Y axis limits 
    max_y = 1E-13;
    min_y = -3E-13;
    
    % X axis limits
    max_x = 600;
    min_x = -60;
        
    % Plot
    figure
    hold on

    title(['Subject ', num2str(subID)])
    ylabel('Field Potential')
    xlabel('Time (ms)')
    ylim([min_y max_y])
    xlim([min_x max_x])
    xticks([-120:120:600])
    
    % Stimulus onset
    plot([0 0],[min_y max_y],'k')

    % Plot mean data
    plot(timevector, LO_mean_nontarget_sighted_epochs,'y')
    plot(timevector, LO_mean_nontarget_blinded_epochs,'b')
    plot(timevector, LO_mean_ISI_nontarget_all_epochs,'k')

    % Plot SEM data
    % plot(timevector, mean_nontarget_sighted_epochs(channel,:)+SEM_nontarget_sighted_epochs(channel,:),'--y')
    % plot(timevector, mean_nontarget_blinded_epochs(channel,:)+SEM_nontarget_blinded_epochs(channel,:),'--b')
    % plot(timevector, mean_nontarget_sighted_epochs(channel,:)-SEM_nontarget_sighted_epochs(channel,:),'--y')
    % plot(timevector, mean_nontarget_blinded_epochs(channel,:)-SEM_nontarget_blinded_epochs(channel,:),'--b')
    % plot(timevector, mean_ISI_nontarget_all_epochs(channel,:)+SEM_ISI_nontarget_all_epochs(channel,:),'--k')
    % plot(timevector, mean_ISI_nontarget_all_epochs(channel,:)-SEM_ISI_nontarget_all_epochs(channel,:),'--k')
    
    %% Individual sensors 

    % Left occipital sensors: 55-73
    % Right occipital sensors: 186-203 % Note: MRO13 is missing 
    % Central occipital sensors: 266-268
    
    % Plot mean epoch timecourses
    
    % Setup timevector
    timevector = -(half_epoch_duration):half_epoch_duration;
    
    % Y axis limits 
    max_y = 2.5E-13;%1E-13;
    min_y = -5.5E-13;%-5E-13;
    
    % X axis limits
    max_x = 500;%600;
    min_x = -50;%60;
    
    % Determine channel list
    % Occiptial channels right: 186:203
    % Occiptial channels left: 55:73
    % Occiptial channels center: 266:268
    % P4 representative channel: 65
    channel_list = 65; 
    
    % Plot
    figure
    hold on

    title(['Subject ', num2str(subID)])
    ylabel('Field Potential')
    xlabel('Time (ms)')
    ylim([min_y max_y])
    xlim([min_x max_x])
    %xticks([-120:120:600])
    xticks([0:100:500])

    % Stimulus onset
    plot([0 0],[min_y max_y],'k')
        
    % Loop over channels
    for channel = channel_list
    
        % Plot mean data
        plot(timevector, mean_nontarget_sighted_epochs(channel,:),'y')
        plot(timevector, mean_nontarget_blinded_epochs(channel,:),'b')
        plot(timevector, mean_ISI_nontarget_all_epochs(channel,:),'k')

        %plot(timevector, mean_ISI_nontarget_sighted_epochs(channel,:),'k')
        %plot(timevector, mean_ISI_nontarget_blinded_epochs(channel,:),'k')

        % Plot SEM data
        plot(timevector, mean_nontarget_sighted_epochs(channel,:)+SEM_nontarget_sighted_epochs(channel,:),'--y')
        plot(timevector, mean_nontarget_blinded_epochs(channel,:)+SEM_nontarget_blinded_epochs(channel,:),'--b')
        plot(timevector, mean_nontarget_sighted_epochs(channel,:)-SEM_nontarget_sighted_epochs(channel,:),'--y')
        plot(timevector, mean_nontarget_blinded_epochs(channel,:)-SEM_nontarget_blinded_epochs(channel,:),'--b')

        plot(timevector, mean_ISI_nontarget_all_epochs(channel,:)+SEM_ISI_nontarget_all_epochs(channel,:),'--k')
        plot(timevector, mean_ISI_nontarget_all_epochs(channel,:)-SEM_ISI_nontarget_all_epochs(channel,:),'--k')

        % plot(timevector, mean_ISI_nontarget_sighted_epochs(channel,:)+SEM_ISI_nontarget_sighted_epochs(channel,:),'--k')
        % plot(timevector, mean_ISI_nontarget_blinded_epochs(channel,:)+SEM_ISI_nontarget_blinded_epochs(channel,:),'--k')
        % plot(timevector, mean_ISI_nontarget_sighted_epochs(channel,:)-SEM_ISI_nontarget_sighted_epochs(channel,:),'--k')
        % plot(timevector, mean_ISI_nontarget_blinded_epochs(channel,:)-SEM_ISI_nontarget_blinded_epochs(channel,:),'--k')

        % Plot stats
        color_list = {'y','b','g'};
        
        % Loop over event types
        for event = 1:length(group_list)
        
            % Define current phase type
            event_type = group_list{event};
    
            % Load data
            cd(output_dir)
            load(['perm_results_',event_type{1},'_vs_',event_type{2},'.mat']);
    
            % Correct time values
            sig_time_pts = sig_time_pts - half_epoch_duration;
    
            % Find significant break points
            sig_breaks = find(diff(sig_time_pts) > 1);
        
            % If there breaks in sig times
            if not(isempty(sig_breaks))
                
                % Loop over discontinuous points
                for breaks = 1:length(sig_breaks)
        
                    % Current break point
                    break_point = sig_breaks(breaks);
        
                    % First break
                    if breaks == 1 
        
                        plot((sig_time_pts(1:break_point)),zeros(1,length(sig_time_pts(1:break_point))), color_list{event})
        
                        % If only one break point also plot to the end of sig times
                        if length(sig_breaks) == 1
        
                            % Between last break and end
                            plot([sig_time_pts(break_point+1:length(sig_time_pts))],zeros(1,length(sig_time_pts(break_point+1:length(sig_time_pts)))), color_list{event})
        
                        end
        
                    % Last break
                    elseif breaks == length(sig_breaks)
        
                        % Between penultimate and final break
                        plot([sig_time_pts(sig_breaks(breaks-1)+1):sig_time_pts(break_point)],...
                            zeros(1,length((sig_time_pts(sig_breaks(breaks-1)+1):sig_time_pts(break_point)))), color_list{event})
        
                        % Between last break and end
                        plot([sig_time_pts(break_point+1:length(sig_time_pts))],zeros(1,length(sig_time_pts(break_point+1:length(sig_time_pts)))), color_list{event})
        
                    % Middle breaks
                    else
        
                        plot([sig_time_pts(sig_breaks(breaks-1)+1):sig_time_pts(break_point)],...
                            zeros(1,length((sig_time_pts(sig_breaks(breaks-1)+1):sig_time_pts(break_point)))), color_list{event})
        
                    end
        
                end
    
            else
    
                % Plot continuous sig time points
                plot(sig_time_pts,zeros(1,length(sig_time_pts)),color_list{event})
    
            end
    
        end

    end

end