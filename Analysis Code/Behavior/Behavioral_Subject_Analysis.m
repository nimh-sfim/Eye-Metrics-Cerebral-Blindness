%% Perception Task - Behavioral Subject Analysis

% This script version corresponds with the results presented in Kronemer et
% al., 2025

% Written by: Sharif I. Kronemer
% Last Modified Date: 12/23/2024

% Version 3

clear all

%% Root Directories & Paths

% Root directory
root_dir = '/Users/kronemersi/Library/CloudStorage/OneDrive-NationalInstitutesofHealth';

%% Inputs and Analysis Parameters

% Patient (1) or control group (0) or custom list (2; single subject)
group_type = 2; 

% Session type (MEG, behavioral, adapted)
% Note: MEG and adapted session types are only relevant for patient
% participant P4; set group_type = 2 to run these sessions
session_type = 'adapted';

% Define subjects to run

% Patients 
if group_type == 1

    subject_list = {'P1','P2','P3','P4','P5','P6','P7','P8'};

% Controls
elseif group_type == 0

    % Controls
    subject_list = {'C1','C2','C3','C4','C5','C6','C7','C8'};


else 

    subject_list = {'P4'};

end

%% Parameters and Group Variables

% Max reaction time
max_RT = 5;

% Create visualizations? (y = yes; n = no)
create_visualizations = 'n';

% All group variables
group_glare_stim_brightness_perception = [];
group_nonglare_stim_brightness_perception = [] ;
group_iso_stim_brigthness_perception = [];

% Patient group variables
if group_type == 1

    group_sighted_RT = [];
    group_blinded_RT = [];
    
    group_sighted_perception_rate = [];
    group_blinded_perception_rate = [];
    
    group_sighted_shape_accuracy_rate = [];
    group_blinded_shape_accuracy_rate = [];

% Control group variables
else

    group_left_RT = [];
    group_right_RT = [];
    
    group_left_perception_rate = [];
    group_right_perception_rate = [];
    
    group_left_shape_accuracy_rate = [];
    group_right_shape_accuracy_rate = [];

end

%% Subject-Level Analysis

% Loop over subjects
for sub = 1:length(subject_list)

    % Define subject
    subID = subject_list{sub};

    disp(['Running subject ',num2str(subID)])
    
    %% Subject Directories
    
    % Data and output directory
    % Note: May need to update directory information for unique data
    % storage directories

    % Adapted task behavioral session
    if isequal(session_type, 'adapted')

        beh_dir = fullfile(root_dir,'Cortical_Blindness_Study/Data',subID,'OP4_adapted_Pilot/Behavior');
        output_dir = fullfile(root_dir,'Cortical_Blindness_Study/Analysis/Subject_Analysis',subID,'OP4_adapted_Pilot');

    % MEG session
    elseif isequal(session_type, 'MEG')

        beh_dir = fullfile(root_dir,'Cortical_Blindness_Study/Data',subID,'MEG_1/Behavior');
        output_dir = fullfile(root_dir,'Cortical_Blindness_Study/Analysis/Subject_Analysis',subID,'MEG_1');

    % Behavioral session
    else
    
        beh_dir = fullfile(root_dir,'Cortical_Blindness_Study/Data',subID,'OP4/Behavior');
        output_dir = fullfile(root_dir,'Cortical_Blindness_Study/Analysis/Subject_Analysis',subID,'OP4');

    end

    % Check output dir
    if isempty(dir(output_dir))
    
        mkdir(output_dir)
    
    end 
    
    %% Load Log Data
    
    % Find directories with log extension
    log_file = dir([fullfile(beh_dir,'*.log')]);

    % If more than one log file is found (e.g., multiple sessions or
    % restarting task during a single session)
    if size(log_file,1) > 1
    
        % Subject specific consideration file number
        if isequal(subID,'P1') % Note: File 1 = v7; Files 2-4 = v8

            file_num = [1,2,3,4];

        elseif ismember(subID,{'P4','P7'})
    
            file_num = [1,2,3];
    
        elseif ismember(subID,{'P2','P3','P5','P6','C6','P8'})

            file_num = [1,2];

        else
    
            error('Unknown subject condition - add condition!')
    
        end

    % If only one file present, use this one for analysis
    else
        
        file_num = 1;
    
    end
    
    % Initialize variables

    % Note: Variables only used for task v8
    correct_perceived_left_cross_distractor = [];
    correct_perceived_left_plus_distractor = [];
    correct_perceived_right_cross_distractor = [];
    correct_perceived_right_plus_distractor = [];

    perceived_left_cross_distractor = [];
    perceived_right_cross_distractor = [];
    perceived_left_plus_distractor = [];
    perceived_right_plus_distractor = [];

    distractor_cross_left_RT = [];
    distractor_plus_left_RT = [];
    distractor_cross_right_RT = [];
    distractor_plus_right_RT = [];
        
    % Note: Variables only used for task v7    
    perceived_left_distractor = [];
    perceived_right_distractor = [];

    distractor_left_RT = [];
    distractor_right_RT = [];

    % Loop over log files
    for file = file_num
    
        disp(['Running log file #', num2str(file)])
    
        % Open log data
        cd(beh_dir)
        log_data = importdata(log_file(file).name);
        
        %% Find Events of Interest
        
        % Initialize event variables
        afterimage_phase_onset = [];
        main_task_phase_onset = [];
        perception_phase_onset = [];
        
        % Mine log file for task phase events
        for row = 1:size(log_data,1)
        
            % Main phase
            if any(~cellfun('isempty',strfind(log_data(row),'Starting Glare Illusion Main Phase')))
               
                main_task_phase_onset = row;
        
            % Perception phase
            elseif any(~cellfun('isempty',strfind(log_data(row),'Starting Glare Illusion Perception Phase')))
        
                perception_phase_onset = row;
        
            % Afterimage phase (Note: Most subjects did not complete this phase)
            elseif any(~cellfun('isempty',strfind(log_data(row),'Starting Afterimage Perception Phase')))
        
                afterimage_phase_onset = row;
        
            % Button press condition
            % Note: Earlier version v7 of the task does not specify condition
            elseif any(~cellfun('isempty',strfind(log_data(row),'Button Condition')))
            
                % Extract row string
                row_string = cell2mat(log_data(row));
        
                % Colon index
                colon_idx = strfind(row_string,':');
        
                % Button condition
                button_condition = str2num(row_string(colon_idx+2:end));
        
            end
        
        end 

        % Special case for P4 - update button condition
        if isequal(subID,'P4') && any(ismember('OP4_adapted_Pilot', output_dir))
       
            button_condition = 1;

        end
    
        % Manually select start row 
        % Note: Due to behavioral performance, some subject blocks are
        % excluded from analyses. Values indicate the log_data row number.

        % Note: Skipping blocks 1 and 2
        if isequal(subID,'P5') && file == 1
    
            main_task_phase_onset = 900;
    
        % Note: Skipping blocks 1, 2, 3 
        elseif isequal(subID,'P5') && file == 2
    
            main_task_phase_onset = 1438;

        % Note: Skipping blocks 1 and 2
        elseif isequal(subID,'P6') && file == 1

            main_task_phase_onset = 917;

        % Note: Skipping block 1
        elseif isequal(subID,'P7') && file == 2

            main_task_phase_onset = 414;

        % Note: Skipping all log files
        elseif isequal(subID,'P8') && file == 1

            main_task_phase_onset = 4839;

        end
        
        % Check if button condition found
        % Note: Button condition determines which keys the participant was
        % instructed to select when they perceived a distractor
        if ~exist('button_condition','var')
    
           warning('Button condition variable missing!')
    
        end
    
        % Define end log row search range
        if ~isempty(perception_phase_onset)
        
            main_end_row = perception_phase_onset;
        
        % End of log file
        else
        
            main_end_row = length(log_data);
        
        end
        
        % Define end log row search range
        if ~isempty(afterimage_phase_onset)
        
            perception_end_row = afterimage_phase_onset;
        
        % End of log file
        else
        
            perception_end_row = length(log_data);
        
        end
        
        %% Main Task Phase

        % Reset variables for each file
        
        % Initialize subject-file event variables
        glare_location_array = [];
        nonglare_location_array = [];
        iso_location_array = [];
        white_location_array = [];
        distractor_location_array = [];
        all_stimuli_type_array = [];
        
        keypress_times = [];
        stimulus_times = [];

        right_stimulus_location = {};
        left_stimulus_location = {};

        % Task version v8 varaibles
        distractor_plus_location_array = [];
        distractor_cross_location_array = [];        

        % Find stimuli location arrays
        
        % Loop among main phase rows
        for row = main_task_phase_onset:main_end_row
        
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
        
            % Right stimulus location
            elseif any(~cellfun('isempty',strfind(log_data(row),'Right Stimulus Location')))
        
                % Extract row string
                loc = cell2mat(log_data(row));
        
                % Extract location
                values = loc(strfind(loc,'('):strfind(loc,')'));
        
                % Locations
                right_stimulus_location = [right_stimulus_location; values];
        
            % Left stimulus location
            elseif any(~cellfun('isempty',strfind(log_data(row),'Left Stimulus Location')))
        
                % Extract row string
                loc = cell2mat(log_data(row));
        
                % Extract location
                values = loc(strfind(loc,'('):strfind(loc,')'));
        
                % Locations
                left_stimulus_location = [left_stimulus_location; values];
        
             end
        
        end
        
        %% Find Perceived Distractor Stimuli
        
        % Loop among main phase rows
        for row = main_task_phase_onset:main_end_row
        
            % Find block number
            if any(~cellfun('isempty',strfind(log_data(row),'Block #')))
        
                % Row string
                row_string = cell2mat(log_data(row));
        
                % Number index
                num_idx = strfind(row_string,'#');
        
                % Extract block number
                block_num = str2num(row_string(num_idx+1:end));
        
                % Update block number for P5 and P6
                % Note: Skipping blocks 1 and 2
                if ismember(subID,{'P5','P6'}) && file == 1
    
                    block_num = block_num-2;

                % Note: Skipping blocks 1, 2, 3
                elseif ismember(subID,{'P5'}) && file == 2
    
                    block_num = block_num-3;

                % Note: Skipping blocks 1
                elseif ismember(subID,{'P7'}) && file == 2
    
                    block_num = block_num-1;
                    
                end

                % Reset trial counter
                cross_distractor_count = 0;
                plus_distractor_count = 0;
                distractor_count = 0;
        
                % Continue to next row
                continue
        
            end

            % Keypress events 1 and 2
            if any(~cellfun('isempty',strfind(log_data(row),'Keypress: 1'))) || ...
                    any(~cellfun('isempty',strfind(log_data(row),'Keypress: 2'))) 

                % Extra row string
                row_string = cell2mat(log_data(row));
                
                % EXP index
                DATA_index = strfind(row_string,'DATA');
                
                % Keypress time
                key_time = str2num(row_string(1:DATA_index(1)-3));

                % Subject correction
                if any(~cellfun('isempty',strfind(log_data(row-3),'Block duration:'))) && isequal(subID,'P4') && isequal(session_type,'adapted')

                    continue

                end

                % Store time
                keypress_times = [keypress_times; key_time];

            end
        
            % Draw stimulus events
            if any(~cellfun('isempty',strfind(log_data(row),'Draw Glare Stimulus'))) || ...
                any(~cellfun('isempty',strfind(log_data(row),'Draw Nonglare Stimulus'))) || ...
                any(~cellfun('isempty',strfind(log_data(row),'Draw Distractor Cross Stimulus'))) || ...
                any(~cellfun('isempty',strfind(log_data(row),'Draw Distractor Plus Stimulus'))) || ...
                any(~cellfun('isempty',strfind(log_data(row),'Draw White Stimulus'))) || ...
                any(~cellfun('isempty',strfind(log_data(row),'Draw Isoluminant Stimulus')))

                % Extra row string
                row_string = cell2mat(log_data(row));
                
                % EXP index
                DATA_index = strfind(row_string,'EXP');
                
                % Stimulus time
                stim_time = str2num(row_string(1:DATA_index(1)-3));

                % Store time
                stimulus_times = [stimulus_times; stim_time];

            end

            % All distractor stimulus
            % Note: This condition is used on task v7 - no cross or plus
            % distractors
            if any(~cellfun('isempty',strfind(log_data(row),'Draw Distractor Stimulus')))
        
                % Count distractor
                distractor_count = distractor_count+1;

                % Grab the stimulus presentation time

                % Extra row string
                row_string = cell2mat(log_data(row));
                    
                % EXP index
                DATA_index = strfind(row_string,'EXP');
                    
                % Stimulus time
                stim_time = str2num(row_string(1:DATA_index(1)-3));

                % Continue looping through log file for keypress
                for row = row+1:main_end_row
            
                    % Look for keypress
                    if any(~cellfun('isempty',strfind(log_data(row),'Keypress'))) 
        
                        % Extra row string
                        row_string = cell2mat(log_data(row));
                        
                        % EXP index
                        DATA_index = strfind(row_string,'DATA');
                        
                        % Keypress time
                        key_time = str2num(row_string(1:DATA_index(1)-3));

                        % Calculate RT
                        RT_time = key_time-stim_time;

                        % Right side
                        if isequal(distractor_location_array(block_num,distractor_count),1)
    
                            % Add perceived index
                            perceived_right_distractor = [perceived_right_distractor;1];

                            % Add RT
                            distractor_right_RT = [distractor_right_RT;RT_time];
    
                        % Left side
                        else
    
                            % Add perceived index
                            perceived_left_distractor = [perceived_left_distractor;1];

                            % Add RT
                            distractor_left_RT = [distractor_left_RT;RT_time];
    
                        end 
    
                        % Move onto next stimulus event
                        break
                                                               
                    % If you get to a new stimulus or block break; No button press
                    elseif any(~cellfun('isempty',strfind(log_data(row),'Starting Trial'))) || ...
                            any(~cellfun('isempty',strfind(log_data(row),'Block duration'))) 
        
                        % Right side
                        if isequal(distractor_location_array(block_num,distractor_count),1)
        
                            % Add no keypress NaN
                            perceived_right_distractor = [perceived_right_distractor;NaN];
                            distractor_right_RT = [distractor_right_RT;NaN];
        
                        % Left side
                        else
        
                            % Add no keypress NaN
                            perceived_left_distractor = [perceived_left_distractor;NaN];
                            distractor_left_RT = [distractor_left_RT;NaN];

                        end 
        
                        % Move onto next stimulus event
                        break
        
                    end
        
                end

            % Cross distractor stimulus 
            elseif any(~cellfun('isempty',strfind(log_data(row),'Draw Distractor Cross Stimulus')))
        
                % Count distractor
                cross_distractor_count = cross_distractor_count+1;

                % Grab the stimulus presentation time

                % Extra row string
                row_string = cell2mat(log_data(row));
                    
                % EXP index
                DATA_index = strfind(row_string,'EXP');
                    
                % Stimulus time
                stim_time = str2num(row_string(1:DATA_index(1)-3));

                % Continue looping through log file for keypress
                for row = row+1:main_end_row
            
                    % Look for keypress
                    if any(~cellfun('isempty',strfind(log_data(row),'Keypress'))) 
        
                        % Extra row string
                        row_string = cell2mat(log_data(row));
                        
                        % EXP index
                        DATA_index = strfind(row_string,'DATA');
                        
                        % Keypress time
                        key_time = str2num(row_string(1:DATA_index(1)-3));

                        % Calculate RT
                        RT_time = key_time-stim_time;
        
                        % Correct answer to distractor shape
                        % Note: Condition 1: + = 1; x = 2; Condition 2: + = 2; x = 1
                        if button_condition == 2 && any(~cellfun('isempty',strfind(log_data(row),'Keypress: 1'))) || ...
                           button_condition == 1 && any(~cellfun('isempty',strfind(log_data(row),'Keypress: 2')))
                            
                            % Right side
                            if isequal(distractor_cross_location_array(block_num,cross_distractor_count),1)
        
                                % Add perception index
                                perceived_right_cross_distractor = [perceived_right_cross_distractor;1];

                                % Add correct shape response
                                correct_perceived_right_cross_distractor = [correct_perceived_right_cross_distractor;1];

                                % Add RT
                                distractor_cross_right_RT = [distractor_cross_right_RT;RT_time];
        
                            % Left side
                            else
        
                                % Add perception index
                                perceived_left_cross_distractor = [perceived_left_cross_distractor;1];

                                % Add correct shape response
                                correct_perceived_left_cross_distractor = [correct_perceived_left_cross_distractor;1];

                                % Add RT
                                distractor_cross_left_RT = [distractor_cross_left_RT;RT_time];
        
                            end 
        
                            % Move onto next stimulus event
                            break
        
                        % Incorrect answer to distractor shape
                        elseif button_condition == 1 && any(~cellfun('isempty',strfind(log_data(row),'Keypress: 1'))) || ...
                               button_condition == 2 && any(~cellfun('isempty',strfind(log_data(row),'Keypress: 2')))
        
                            % Right side
                            if isequal(distractor_cross_location_array(block_num,cross_distractor_count),1)
        
                                % Add perception index
                                perceived_right_cross_distractor = [perceived_right_cross_distractor;1]; % Note: log keypress even if incorrect

                                % Add incorrect shape response
                                correct_perceived_right_cross_distractor = [correct_perceived_right_cross_distractor;0];

                                % Add RT
                                distractor_cross_right_RT = [distractor_cross_right_RT;RT_time];
        
                            % Left side
                            else
        
                                % Add perception index
                                perceived_left_cross_distractor = [perceived_left_cross_distractor;1]; % Note: log keypress even if incorrect

                                % Add incorrect shape response
                                correct_perceived_left_cross_distractor = [correct_perceived_left_cross_distractor;0];

                                % Add RT
                                distractor_cross_left_RT = [distractor_cross_left_RT;RT_time];
        
                            end
        
                            % Move onto next stimulus event
                            break
        
                        end
                         
                    % If you get to a new stimulus or block break; No button press
                    elseif any(~cellfun('isempty',strfind(log_data(row),'Starting Trial'))) || ...
                            any(~cellfun('isempty',strfind(log_data(row),'Block duration'))) 
        
                        % Right side
                        if isequal(distractor_cross_location_array(block_num,cross_distractor_count),1)
        
                            % % Add no keypress NaN
                            perceived_right_cross_distractor = [perceived_right_cross_distractor;NaN];
                            correct_perceived_right_cross_distractor = [correct_perceived_right_cross_distractor;NaN];
                            distractor_cross_right_RT = [distractor_cross_right_RT;NaN];
        
                        % Left side
                        else
        
                            % Add no keypress NaN
                            perceived_left_cross_distractor = [perceived_left_cross_distractor;NaN];
                            correct_perceived_left_cross_distractor = [correct_perceived_left_cross_distractor;NaN];
                            distractor_cross_left_RT = [distractor_cross_left_RT;NaN];

                        end 
        
                        % Move onto next stimulus event
                        break
        
                    end
        
                end
        
            % Plus distractor stimulus 
            elseif any(~cellfun('isempty',strfind(log_data(row),'Draw Distractor Plus Stimulus')))
        
                % Count distractor
                plus_distractor_count = plus_distractor_count+1;

                % Grab the stimulus presentation time

                % Extra row string
                row_string = cell2mat(log_data(row));
                    
                % EXP index
                DATA_index = strfind(row_string,'EXP');
                    
                % Stimulus time
                stim_time = str2num(row_string(1:DATA_index(1)-3));

                % Continue looping through log file for keypress
                for row = row+1:main_end_row
            
                    % Look for keypress
                    if any(~cellfun('isempty',strfind(log_data(row),'Keypress'))) 
        
                        % Extra row string
                        row_string = cell2mat(log_data(row));
                        
                        % EXP index
                        DATA_index = strfind(row_string,'DATA');
                        
                        % Keypress time
                        key_time = str2num(row_string(1:DATA_index(1)-3));

                        % Calculate RT
                        RT_time = key_time-stim_time;

                        % Correct answer to distractor shape
                        % Note: Condition 1: + = 1; x = 2; Condition 2: + = 2; x = 1
                        if button_condition == 1 && any(~cellfun('isempty',strfind(log_data(row),'Keypress: 1'))) || ...
                           button_condition == 2 && any(~cellfun('isempty',strfind(log_data(row),'Keypress: 2')))
                            
                            % Right side
                            if isequal(distractor_plus_location_array(block_num,plus_distractor_count),1)
        
                                % Add perception index
                                perceived_right_plus_distractor = [perceived_right_plus_distractor;1];

                                % Add correct shape response
                                correct_perceived_right_plus_distractor = [correct_perceived_right_plus_distractor;1];

                                % Add RT
                                distractor_plus_right_RT = [distractor_plus_right_RT;RT_time];
        
                            % Left side
                            else
        
                                % Add perception index
                                perceived_left_plus_distractor = [perceived_left_plus_distractor;1];

                                % Add correct shape response
                                correct_perceived_left_plus_distractor = [correct_perceived_left_plus_distractor;1];
        
                                % Add RT
                                distractor_plus_left_RT = [distractor_plus_left_RT;RT_time];

                            end 
        
                            % Move onto next stimulus event
                            break
            
                        % Incorrect answer to distractor shape
                        elseif button_condition == 2 && any(~cellfun('isempty',strfind(log_data(row),'Keypress: 1'))) || ...
                               button_condition == 1 && any(~cellfun('isempty',strfind(log_data(row),'Keypress: 2')))
        
                            % Right side
                            if isequal(distractor_plus_location_array(block_num,plus_distractor_count),1)
        
                                % Add perception index
                                perceived_right_plus_distractor = [perceived_right_plus_distractor;1]; % Note: log perceived keypress even if incorrect

                                % Add incorrect shape response
                                correct_perceived_right_plus_distractor = [correct_perceived_right_plus_distractor;0];

                                % Add RT
                                distractor_plus_right_RT = [distractor_plus_right_RT;RT_time];
        
                            % Left side
                            else
        
                                % Add perception index
                                perceived_left_plus_distractor = [perceived_left_plus_distractor;1]; % Note: log keypress even if incorrect

                                % Add incorrect shape response
                                correct_perceived_left_plus_distractor = [correct_perceived_left_plus_distractor;0];

                                % Add RT
                                distractor_plus_left_RT = [distractor_plus_left_RT;RT_time];
        
                            end 
        
                            % Move onto next stimulus event
                            break
        
                        end
        
                    % If you get to a new stimulus break; No button press
                    elseif any(~cellfun('isempty',strfind(log_data(row),'Starting Trial'))) || ...
                            any(~cellfun('isempty',strfind(log_data(row),'Block duration')))
        
                        % Right side
                        if isequal(distractor_plus_location_array(block_num,plus_distractor_count),1)
        
                            % Add no keypress NaN
                            perceived_right_plus_distractor = [perceived_right_plus_distractor;NaN];
                            correct_perceived_right_plus_distractor = [correct_perceived_right_plus_distractor;NaN];
                            distractor_plus_right_RT = [distractor_plus_right_RT;NaN];
        
                        % Left side
                        else
        
                            % Add no keypress NaN
                            perceived_left_plus_distractor = [perceived_left_plus_distractor;NaN];
                            correct_perceived_left_plus_distractor = [correct_perceived_left_plus_distractor;NaN];
                            distractor_plus_left_RT = [distractor_plus_left_RT;NaN];
        
                        end 
        
                        % Move onto next stimulus event
                        break
        
                    end
        
                end
               
            end
        
        end

        % Task version v7 subjects
        if ismember(subID,{'C2','C3'}) || isequal(subID,'P1') && file == 1

                % Check correct size of arrays
            if ~isequal(length(perceived_right_distractor), length(distractor_right_RT), length(perceived_left_distractor), length(distractor_left_RT),...
                    size(distractor_location_array,1)*size(distractor_location_array,2)/2)
    
                error('Data array length mistmatch!')
    
            end

            % Calculate the total number of events (necessary to combine values
            % when there are multiple log files)
            if file == 1
                
                num_distractor = size(distractor_location_array,1)*size(distractor_location_array,2);
    
            else
    
                num_distractor = num_distractor + (size(distractor_location_array,1)*size(distractor_location_array,2));
    
            end

        % Task version v8 subjects
        else

            % Check correct size of arrays
            if ~isequal(length(correct_perceived_left_plus_distractor), length(correct_perceived_right_plus_distractor), length(distractor_plus_left_RT),...
                    length(distractor_plus_right_RT), length(distractor_cross_left_RT),length(distractor_cross_right_RT))

                % Special exception for subject C6 (task crashed)
                if isequal(subID,'C6')
    
                    warning('Data array length mistmatch!')
    
                else
    
                    error('Data array length mistmatch!')
    
                end
    
            end
    
            % Calculate the total number of events (necessary to combine values
            % when there are multiple log files)
            if file == 1 || isequal(subID,'P1') && file == 2
                
                num_distractor_plus = (size(distractor_plus_location_array,1)*size(distractor_plus_location_array,2));
                num_distractor_cross = (size(distractor_cross_location_array,1)*size(distractor_cross_location_array,2));
    
            else
    
                num_distractor_plus = num_distractor_plus + (size(distractor_plus_location_array,1)*size(distractor_plus_location_array,2));
                num_distractor_cross = num_distractor_cross + (size(distractor_cross_location_array,1)*size(distractor_cross_location_array,2));
    
            end
        
        end

        %% Brightness Perception Task Phase

        % Note: This task phase studies the glare illusion vividness
        % Note: Location array: 0 = left; 1 = right - Keypress array: 1 =
        % left; 2 = right; 3 = same

        % Note: Logging of the comparisons was inaccurate: glare vs
        % nonglare = "Glare Stimuli Location Array"; glare vs iso =
        % "Nonglare Stimuli Location Array"; nonglare vs iso = "Iso Stimuli
        % Location Array"
       
        % Check if perception phase was completed
        if ~isempty(perception_phase_onset)

            % Initialize variables
            glare_vs_nonglare_perception = [];
            glare_vs_iso_perception = [];
            nonglare_vs_iso_perception = [];
            all_type_array = [];

            % Note: 0 = left; 1 = right
            glare_vs_nonglare_array = [];
            glare_vs_iso_array = [];
            nonglare_vs_iso_array = [];
            
            % Loop among main phase rows
            for row = perception_phase_onset:perception_end_row
            
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
            
                        % Combine type arrays
                        type_array = str2num([array_1,array_2]);
            
                    else
                    
                        % Type array
                        type_array = str2num(row_string(bracket_1:bracket_2));
            
                    end
            
                    % Add block location array
                    all_type_array = [all_type_array; type_array];
            
                end
            
                % Glare vs Nonglare Stimuli
                if any(~cellfun('isempty',strfind(log_data(row),'Glare Stimuli Location Array')))
            
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
            
                    % Type array
                    type_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add array
                    glare_vs_nonglare_array = [glare_vs_nonglare_array; type_array];
            
                end
            
                % Glare vs Isoluminant Stimuli
                if any(~cellfun('isempty',strfind(log_data(row),'Nonglare Stimuli Location Array')))
            
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
            
                    % Type array
                    type_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add array
                    glare_vs_iso_array = [glare_vs_iso_array; type_array];
            
                end
            
                % Nonglare vs Isoluminant Stimuli
                if any(~cellfun('isempty',strfind(log_data(row),'Iso Stimuli Location Array')))
            
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
            
                    % Type array
                    type_array = str2num(row_string(bracket_1:bracket_2));
            
                    % Add array
                    nonglare_vs_iso_array = [nonglare_vs_iso_array; type_array];
            
                end
            
                % Glare vs Nonglare Stimuli
                if any(~cellfun('isempty',strfind(log_data(row),'Draw Glare vs Nonglare Stimulus')))
            
                    % Find keypress event
                    for next_row = 1:50

                        % Find Keypress 1
                        if any(~cellfun('isempty',strfind(log_data(row+next_row),'Keypress: 1')))
                
                            glare_vs_nonglare_perception = [glare_vs_nonglare_perception, 1];

                            break
                
                        % Find Keypress 2
                        elseif any(~cellfun('isempty',strfind(log_data(row+next_row),'Keypress: 2')))
                
                            glare_vs_nonglare_perception = [glare_vs_nonglare_perception, 2];

                            break
                
                        % Find Keypress 3
                        elseif any(~cellfun('isempty',strfind(log_data(row+next_row),'Keypress: 3')))
                
                            glare_vs_nonglare_perception = [glare_vs_nonglare_perception, 3];

                            break
                
                        % No Keypress
                        elseif any(~cellfun('isempty',strfind(log_data(row+next_row),'Starting Trial')))
                
                            glare_vs_nonglare_perception = [glare_vs_nonglare_perception, NaN];
                
                            error('No keypress found!')
                
                        end

                    end
            
                % Glare vs Isoluminant Stimuli
                elseif any(~cellfun('isempty',strfind(log_data(row),'Draw Glare vs Iso Stimulus')))
            
                    % Find keypress event
                    for next_row = 1:50

                        % Find Keypress 1
                        if any(~cellfun('isempty',strfind(log_data(row+next_row),'Keypress: 1')))
                
                            glare_vs_iso_perception = [glare_vs_iso_perception, 1];
                
                            break

                        % Find Keypress 2
                        elseif any(~cellfun('isempty',strfind(log_data(row+next_row),'Keypress: 2')))
                
                            glare_vs_iso_perception = [glare_vs_iso_perception, 2];
                
                            break

                        % Find Keypress 3
                        elseif any(~cellfun('isempty',strfind(log_data(row+next_row),'Keypress: 3')))
                
                            glare_vs_iso_perception = [glare_vs_iso_perception, 3];
                
                            break

                        % No Keypress
                        elseif any(~cellfun('isempty',strfind(log_data(row+next_row),'Starting Trial')))
                
                            glare_vs_iso_perception = [glare_vs_iso_perception, NaN];
                
                            error('No keypress found!')
                
                        end

                    end
            
                % Nonglare vs Isoluminant Stimuli
                elseif any(~cellfun('isempty',strfind(log_data(row),'Draw Nonglare vs Iso Stimulus')))
            
                    % Find keypress event
                    for next_row = 1:50

                        % Find Keypress 1
                        if any(~cellfun('isempty',strfind(log_data(row+next_row),'Keypress: 1')))
                
                            nonglare_vs_iso_perception = [nonglare_vs_iso_perception, 1];

                            break
                
                        % Find Keypress 2
                        elseif any(~cellfun('isempty',strfind(log_data(row+next_row),'Keypress: 2')))
                
                            nonglare_vs_iso_perception = [nonglare_vs_iso_perception, 2];

                            break
                
                        % Find Keypress 3
                        elseif any(~cellfun('isempty',strfind(log_data(row+next_row),'Keypress: 3')))
                
                            nonglare_vs_iso_perception = [nonglare_vs_iso_perception, 3];

                            break
                
                        % No Keypress
                        elseif any(~cellfun('isempty',strfind(log_data(row+next_row),'Starting Trial')))
                
                            nonglare_vs_iso_perception = [nonglare_vs_iso_perception, NaN];
                
                            error('No keypress found!')
                
                        end

                    end
            
                end
            
            end

            % Check that all trials are collected
            if ~isequal(10,length(glare_vs_iso_array),length(nonglare_vs_iso_array),length(glare_vs_nonglare_array),...
                    length(glare_vs_iso_perception),length(nonglare_vs_iso_perception),length(glare_vs_nonglare_perception))

                error('Brightness perception phase variables incorrect size!')

            end
            
            % Note: That in the nonglare_vs_iso_array, the value applies to
            % the iso stimulus; in contrast, in the glare_vs_iso and
            % glare_vs_nonglare arrays the values apply to the glare
            % stimulus

            % Note: 1 point for indicating stimulus brighter; 0.5 point for
            % indicating stimulus was equally bright; 0 points for
            % indicating stimulus was not brighter.

            % Glare stimulus brighter
            glare_brighter = length(find(glare_vs_iso_array == 1 & glare_vs_iso_perception == 2)) + ...
                length(find(glare_vs_iso_array == 0 & glare_vs_iso_perception == 1)) + ...
                length(find(glare_vs_nonglare_array == 1 & glare_vs_nonglare_perception == 2)) + ...
                length(find(glare_vs_nonglare_array == 0 & glare_vs_nonglare_perception == 1)) + ...
                [(length(find(glare_vs_iso_perception == 3)) + length(find(glare_vs_nonglare_perception == 3)))/2];
            
            % Nonglare stimulus brigther
            nonglare_brighter = length(find(nonglare_vs_iso_array == 1 & nonglare_vs_iso_perception == 1)) + ...
                length(find(nonglare_vs_iso_array == 0 & nonglare_vs_iso_perception == 2)) + ...
                length(find(glare_vs_nonglare_array == 1 & glare_vs_nonglare_perception == 1)) + ...
                length(find(glare_vs_nonglare_array == 0 & glare_vs_nonglare_perception == 2)) + ...
                [(length(find(nonglare_vs_iso_perception == 3)) + length(find(glare_vs_nonglare_perception == 3)))/2];
            
            % Isoluminant stimulus brigther
            iso_brighter = length(find(nonglare_vs_iso_array == 1 & nonglare_vs_iso_perception == 2)) + ...
                length(find(nonglare_vs_iso_array == 0 & nonglare_vs_iso_perception == 1)) + ...
                length(find(glare_vs_iso_array == 1 & glare_vs_iso_perception == 1)) + ...
                length(find(glare_vs_iso_array == 0 & glare_vs_iso_perception == 2)) + ...
                [(length(find(nonglare_vs_iso_perception == 3)) + length(find(glare_vs_iso_perception == 3)))/2];

            % Check that the arrays are the right length
            if ~isequal(10,length(glare_vs_iso_array),length(glare_vs_nonglare_array),length(nonglare_vs_iso_array)) || ...
                    ~isequal(30, glare_brighter + nonglare_brighter + iso_brighter)

                error('Brightness perception arrays/score sum are the wrong size!')

            end

            % Store subject values in group variables
            group_glare_stim_brightness_perception = [group_glare_stim_brightness_perception; glare_brighter];
            group_nonglare_stim_brightness_perception = [group_nonglare_stim_brightness_perception; nonglare_brighter] ;
            group_iso_stim_brigthness_perception = [group_iso_stim_brigthness_perception; iso_brighter];

            % Plot Brightness Perception
            if create_visualizations == 'y'

                % Setup figure
                figure
                hold on
                
                % Setup figure labels
                title(['Brightness Perception - ', num2str(subID)])
                ylabel('Relative Perception Score')
                
                % Plot perception scores
                glare_plot = bar(1,glare_brighter,'b')
                nonglare_plot = bar(2,nonglare_brighter,'g')
                iso_plot = bar(3,iso_brighter,'k')
                
                % Legend
                legend([glare_plot nonglare_plot iso_plot],{'Glare Stimulus','Nonglare Stimulus','Iso Stimulus'})

            end

        end

    end
    
    %% Calculate Behavioral Results

    % Find any keypress beyond the max RT
    
    % Initialize variable 
    false_positive_rate = [];

    % Loop over keypresses
    for key = 1:length(keypress_times)

       % Current key time
       current_time = repmat(keypress_times(key),1,length(stimulus_times))';

       % Substract keypresses from stimulus time
       relative_time = stimulus_times - current_time;

       % Find a keypress within the max_RT of a stimulus
       if any(abs(relative_time(relative_time<0)) < max_RT)

           % Keypress timed with stimulus
           false_positive_rate = [false_positive_rate; 0];

       else
           
           % False positive keypress
           false_positive_rate = [false_positive_rate; 1];

       end

    end

    % Subjects completed task v7 only
    if ismember(subID,{'C2','C3'})

        % RT index
        left_RT_idx = distractor_left_RT < max_RT;
        right_RT_idx = distractor_right_RT < max_RT;

        % Perception rate - left vs right
        left_perception_rate = nansum(perceived_left_distractor(left_RT_idx))/(sum(isnan(distractor_left_RT))+sum(left_RT_idx));
        right_perception_rate = nansum(perceived_right_distractor(right_RT_idx))/(sum(isnan(distractor_right_RT))+sum(right_RT_idx));

        % Reaction time
        left_mean_RT = mean(distractor_left_RT(left_RT_idx),"omitnan");
        right_mean_RT = mean(distractor_right_RT(right_RT_idx),"omitnan");

        % Save variables
        cd(output_dir)
        save 'Glare_illusion_behavioral_results.mat' distractor_left_RT distractor_right_RT ...
            perceived_left_distractor perceived_right_distractor left_perception_rate right_perception_rate left_mean_RT right_mean_RT ...
            glare_brighter iso_brighter nonglare_brighter false_positive_rate

        % Store data by group type
        if group_type == 0

            % Store subject values in group variables
            group_left_RT = [group_left_RT; left_mean_RT];
            group_right_RT = [group_right_RT; right_mean_RT];
            
            group_left_perception_rate = [group_left_perception_rate; left_perception_rate];
            group_right_perception_rate = [group_right_perception_rate; right_perception_rate];
    
            % Enter NaN for cross/plus variables that does not apply for v7
            group_left_shape_accuracy_rate = [group_left_shape_accuracy_rate; NaN];
            group_right_shape_accuracy_rate = [group_right_shape_accuracy_rate; NaN];

        end

    % Subjects completed task v8
    else

        % Special treatment of subject P1 who completed v7 and v8
        if isequal(subID,'P1')

            % RT index
            left_plus_RT_idx = distractor_plus_left_RT < max_RT;
            right_plus_RT_idx = distractor_plus_right_RT < max_RT;
            left_cross_RT_idx = distractor_cross_left_RT < max_RT;
            right_cross_RT_idx = distractor_cross_right_RT < max_RT;
            left_RT_idx = distractor_left_RT < max_RT;
            right_RT_idx = distractor_right_RT < max_RT;

            % Combine task v7 and v8 results

            % Perception rate
            left_perception_rate = (nansum(perceived_left_plus_distractor(left_plus_RT_idx)) + nansum(perceived_left_cross_distractor(left_cross_RT_idx))+...
                nansum(perceived_left_distractor(left_RT_idx)))/(sum(isnan(distractor_plus_left_RT))+sum(isnan(distractor_cross_left_RT))+sum(isnan(distractor_left_RT))+...
                sum(left_plus_RT_idx)+sum(left_cross_RT_idx)+sum(left_RT_idx));
            right_perception_rate = (nansum(perceived_right_plus_distractor(right_plus_RT_idx)) + nansum(perceived_right_cross_distractor(right_cross_RT_idx))+...
                nansum(perceived_right_distractor(right_RT_idx)))/(sum(isnan(distractor_plus_right_RT))+sum(isnan(distractor_cross_right_RT))+sum(isnan(distractor_right_RT))+...
                sum(right_plus_RT_idx)+sum(right_cross_RT_idx)+sum(right_RT_idx));

            % Reaction time 
            left_mean_RT = mean([distractor_cross_left_RT(left_cross_RT_idx);distractor_plus_left_RT(left_plus_RT_idx);distractor_left_RT(left_RT_idx)],"omitnan");
            right_mean_RT = mean([distractor_cross_right_RT(right_cross_RT_idx);distractor_plus_right_RT(right_plus_RT_idx);distractor_right_RT(right_RT_idx)],"omitnan");
        
            % Calculate accuracy rate
            % Note: Comes from task v8 only
            left_distractor_shape_accuracy_rate = (nansum(correct_perceived_left_plus_distractor(left_plus_RT_idx))+...
                nansum(correct_perceived_left_cross_distractor(left_cross_RT_idx)))/(sum(left_plus_RT_idx)+sum(left_cross_RT_idx));


            right_distractor_shape_accuracy_rate = (nansum(correct_perceived_right_plus_distractor(right_plus_RT_idx))+...
                nansum(correct_perceived_right_cross_distractor(right_cross_RT_idx)))/(sum(right_plus_RT_idx)+sum(right_cross_RT_idx));

        else

            % RT index
            left_plus_RT_idx = distractor_plus_left_RT < max_RT;
            right_plus_RT_idx = distractor_plus_right_RT < max_RT;
            left_cross_RT_idx = distractor_cross_left_RT < max_RT;
            right_cross_RT_idx = distractor_cross_right_RT < max_RT;

            % Perception rate
            left_perception_rate = (nansum(perceived_left_plus_distractor(left_plus_RT_idx)) + nansum(perceived_left_cross_distractor(left_cross_RT_idx)))/...
               (sum(isnan(distractor_plus_left_RT))+sum(isnan(distractor_cross_left_RT))+...
               sum(left_plus_RT_idx)+sum(left_cross_RT_idx));
            %left_perception_rate = (nansum(perceived_left_plus_distractor) + nansum(perceived_left_cross_distractor))/...
            %    (length(perceived_left_plus_distractor) + length(perceived_left_cross_distractor));

            right_perception_rate = (nansum(perceived_right_plus_distractor(right_plus_RT_idx)) + nansum(perceived_right_cross_distractor(right_cross_RT_idx)))/...
              (sum(isnan(distractor_plus_right_RT))+sum(isnan(distractor_cross_right_RT))+...
               sum(right_plus_RT_idx)+sum(right_cross_RT_idx));
            %right_perception_rate = (nansum(perceived_right_plus_distractor) + nansum(perceived_right_cross_distractor))/...
            %    (length(perceived_right_plus_distractor) + length(perceived_right_cross_distractor));

            % Reaction time
            left_mean_RT = mean([distractor_cross_left_RT(left_cross_RT_idx);distractor_plus_left_RT(left_plus_RT_idx)],"omitnan");
            right_mean_RT = mean([distractor_cross_right_RT(right_cross_RT_idx);distractor_plus_right_RT(right_plus_RT_idx)],"omitnan");
        
            % Calculate accuracy rate
            left_distractor_shape_accuracy_rate = (nansum(correct_perceived_left_plus_distractor(left_plus_RT_idx))+...
                nansum(correct_perceived_left_cross_distractor(left_cross_RT_idx)))/(length(correct_perceived_left_plus_distractor(left_plus_RT_idx))+...
                length(correct_perceived_left_cross_distractor(left_cross_RT_idx)));

            right_distractor_shape_accuracy_rate = (nansum(correct_perceived_right_plus_distractor(right_plus_RT_idx))+...
                nansum(correct_perceived_right_cross_distractor(right_cross_RT_idx)))/(length(correct_perceived_right_plus_distractor(right_plus_RT_idx))+...
                length(correct_perceived_right_cross_distractor(right_cross_RT_idx)));

        end

        % Test if accuracy rate is greater than chance
        
        % Parameters
        n = (length(correct_perceived_right_plus_distractor(right_plus_RT_idx))+...
                length(correct_perceived_right_cross_distractor(right_cross_RT_idx)));       % Total number of trials
        k = (nansum(correct_perceived_right_plus_distractor(right_plus_RT_idx))+...
                nansum(correct_perceived_right_cross_distractor(right_cross_RT_idx)));       % Number of correct answers
        p = 0.5;      % Probability of success under the null hypothesis
        alpha = 0.05; % Significance level
        
        % Compute the one-sided p-value
        p_value = 1 - binocdf(k - 1, n, p);
        
        % Display results
        fprintf('One-sided p-value: %.4f\n', p_value);
        
        if p_value < alpha
            fprintf('Performance is statistically significant (reject H0).\n');
        else
            fprintf('Performance is not statistically significant (fail to reject H0).\n');
        end
    
        % Save variables
        cd(output_dir)

        % Special consideration for P4 - adapted pilot separate saving
        if isequal(subID,'P4') && contains(output_dir,'OP4_adapted_Pilot')

            save 'Glare_illusion_adapted_behavioral_results.mat' distractor_cross_left_RT distractor_cross_right_RT ...
                distractor_plus_left_RT distractor_plus_right_RT distractor_cross_location_array distractor_plus_location_array ...
                perceived_left_cross_distractor perceived_right_cross_distractor left_perception_rate right_perception_rate left_mean_RT right_mean_RT ...
                left_distractor_shape_accuracy_rate right_distractor_shape_accuracy_rate false_positive_rate

        elseif isequal(subID,'P4') && contains(output_dir,'MEG')

            save 'Glare_illusion_MEG_behavioral_results.mat' distractor_cross_left_RT distractor_cross_right_RT ...
                distractor_plus_left_RT distractor_plus_right_RT distractor_cross_location_array distractor_plus_location_array ...
                perceived_left_cross_distractor perceived_right_cross_distractor left_perception_rate right_perception_rate left_mean_RT right_mean_RT ...
                left_distractor_shape_accuracy_rate right_distractor_shape_accuracy_rate false_positive_rate

        else

            save 'Glare_illusion_behavioral_results.mat' distractor_cross_left_RT distractor_cross_right_RT ...
                distractor_plus_left_RT distractor_plus_right_RT distractor_cross_location_array distractor_plus_location_array ...
                perceived_left_cross_distractor perceived_right_cross_distractor left_perception_rate right_perception_rate left_mean_RT right_mean_RT ...
                left_distractor_shape_accuracy_rate right_distractor_shape_accuracy_rate glare_brighter iso_brighter nonglare_brighter false_positive_rate

        end

        % Store control group data
        if group_type == 0

            % Store subject values in group variables
            group_left_RT = [group_left_RT; left_mean_RT];
            group_right_RT = [group_right_RT; right_mean_RT];
            
            group_left_perception_rate = [group_left_perception_rate; left_perception_rate];
            group_right_perception_rate = [group_right_perception_rate; right_perception_rate];
    
            group_left_shape_accuracy_rate = [group_left_shape_accuracy_rate; left_distractor_shape_accuracy_rate];
            group_right_shape_accuracy_rate = [group_right_shape_accuracy_rate; right_distractor_shape_accuracy_rate];

        % Store patient group data
        elseif group_type == 1

            % Right side blinded
            if ismember(subID,{'P3','P4','P6'})

                group_sighted_RT = [group_sighted_RT; left_mean_RT];
                group_blinded_RT = [group_blinded_RT; right_mean_RT];
    
                group_sighted_perception_rate = [group_sighted_perception_rate; left_perception_rate];
                group_blinded_perception_rate = [group_blinded_perception_rate; right_perception_rate];
    
                group_sighted_shape_accuracy_rate = [group_sighted_shape_accuracy_rate; left_distractor_shape_accuracy_rate];
                group_blinded_shape_accuracy_rate = [group_blinded_shape_accuracy_rate; right_distractor_shape_accuracy_rate];

            % Left side blinded
            else

                group_sighted_RT = [group_sighted_RT; right_mean_RT];
                group_blinded_RT = [group_blinded_RT; left_mean_RT];
    
                group_sighted_perception_rate = [group_sighted_perception_rate; right_perception_rate];
                group_blinded_perception_rate = [group_blinded_perception_rate; left_perception_rate];
    
                group_sighted_shape_accuracy_rate = [group_sighted_shape_accuracy_rate; right_distractor_shape_accuracy_rate];
                group_blinded_shape_accuracy_rate = [group_blinded_shape_accuracy_rate; left_distractor_shape_accuracy_rate];

            end

        end

    end
        
end