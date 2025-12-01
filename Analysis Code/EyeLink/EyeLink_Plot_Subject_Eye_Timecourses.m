%% Glare Illusion Paradigm - Plot Individual Subject Eye Timecourses

% Written by: Sharif I. Kronemer
% Last Modified Date: 7/22/2025

% Version 1

clear all

%% Directories & Paths

% Root path
root_path = '/Users/kronemersi/Library/CloudStorage/OneDrive-NationalInstitutesofHealth/Cortical_Blindness_Study';

% Subject data directory
data_dir = fullfile(root_path,'Analysis/Subject_Analysis');

%% Subject/Group Selection

% Patient (1) or control group (0) or custom list (2)
group_type = 1; 

% Blink and saccade smoothing
blink_saccade_smoothing_span = 100;

% Define subjects to run
subject_list = {'P5','P8','P4'};

%% Parameters

% Define data types
data_list = {'pupil','blink','microsaccade'};

% Define sides
side_list = {'left','right'};

% Turn off warnings
warning('off','all')

%% Create Subject Plots

% Loop over subjects
for ID = 1:length(subject_list)

    % SubID
    subID = subject_list{ID};

    % Load data
    load(fullfile(data_dir,subID,'OP4','Glare_illusion_EyeLink_results.mat'),'glare_*_epochs','nonglare_*_epochs','white_*_epochs',...
        'iso_*_epochs','mean_ISI_glare_nonglare_white_left_right*','SEM_ISI_glare_nonglare_white_left_right*',...
        'mean_ISI_glare_nonglare_white_iso_left_right*','SEM_ISI_glare_nonglare_white_iso_left_right*');

    % Loop over data types
    for data = 1:length(data_list)
        
        % Current data
        data_type = data_list{data};

        % Loop over side types
        for type = 1:length(side_list)

            % Current side
            side_type = side_list{type};
    
            % Combine epochs
            target_epochs = eval(['[glare_',side_type,'_',data_type,'_epochs','; nonglare_',side_type,'_',data_type,'_epochs',...
                '; white_',side_type,'_',data_type,'_epochs','; iso_',side_type,'_',data_type,'_epochs]']);

            % Mean across epochs
            target_data = nanmean(target_epochs,1);
        
            % Calculate SEM - exclude nan epochs
            SEM_data = nanstd(target_epochs,1)/sqrt(size(target_epochs,1));
            
            % Smooth blink/microsaccade data
            % Note: That subject level analyses will perform the
            % same smoothing procedure on other mean trial types already
            if ismember(data_type,['microsaccade','blink'])
                
                % Mean across epochs
                target_data = movmean(target_data,blink_saccade_smoothing_span);
            
                % Calculate SEM - exclude nan epochs
                SEM_data = movmean((nanstd(target_epochs,1)/sqrt(size(target_epochs,1))),blink_saccade_smoothing_span);
            
            end

            % Rename variable 
            eval(['target_',side_type,'_data = target_data;'])
            eval(['SEM_',side_type,'_data = SEM_data;'])

        end

        % Select blank data
        blank_data = eval(['mean_ISI_glare_nonglare_white_iso_left_right_',data_type]);
        SEM_blank_data = eval(['SEM_ISI_glare_nonglare_white_iso_left_right_',data_type]);

        %% Plot Individual Subject Timecourses
        
        % Timevector
        timevector = [-9000:9000];
        
        % X-axis parameters
        xmin = -500;
        xmax = 6000;

        % Setup figure setting
        set(0,'DefaultFigureRenderer','painters')
        
        % Initialize plot
        figure
        hold on
    
        % Figure labels
        title([subID,' - ',data_type])
        
        % Set figure parameters
        if isequal(data_type,'pupil')
    
            ymin = -150;
            ymax = 150;
            yticks([-150 -75 0 75 150])

        elseif isequal(data_type,'microsaccade')
    
            ymin = 0;
            ymax = 0.16;
            yticks([0 0.04 0.08 0.12 0.16])

        elseif isequal(data_type,'blink')
        
            ymin = 0;
            ymax = 0.2;
            yticks([0 0.04 0.08 0.12 0.16 0.2])

        end

        % Axis limits
        xlim([xmin xmax])
        ylim([ymin ymax])
    
        % Axis ticks
        xticks([0:1500:6000])
    
        % Stimulus times
        plot([0 0],[ymin ymax],'k')
        plot([3000 3000],[ymin ymax],'k')
    

        % Mean
        plot(timevector, target_left_data,'b')
        plot(timevector, target_right_data,'r')
        plot(timevector, blank_data,'k')

        % SEM
        plot(timevector, target_left_data+SEM_left_data,'b')
        plot(timevector, target_left_data-SEM_left_data,'b')
        plot(timevector, target_right_data+SEM_right_data,'r')
        plot(timevector, target_right_data-SEM_right_data,'r')
        plot(timevector, blank_data+SEM_blank_data,'k')
        plot(timevector, blank_data-SEM_blank_data,'k')

    end

end
