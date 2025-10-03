%% Plot HVF Figure and Stimulus Presentation Locations

% Creates individual HVF results and group figures. 

% Written by: Tori Gobo and Sharif I. Kronemer
% Last modified: 12/6/2024

clear all

%% Parameters 

% Subjects to analyze
subject_list = {'P1'; 'P2'; 'P3'; 'P4'; 'P5'; 'P6'; 'P7'; 'P8'};

% Eyes
eye_type = {'Left', 'Right'};

% Add screen size constants (in mm)
% Note: These values were measured manually
screen_length = 530; % Behavioral session
screen_height = 298; % Behavioral session

% Subject distance from screen (in mm)
% Note: This value was measured manually 
sub_distance = 580; % Behavioral session
MEG_sub_distance = 750; % MEG session;

% Stimulus size (in mm)
% Note: The stimulus size x and y dimensions are not identical
stimulus_size = 66;
MEG_stimulus_size = 68;

% Stimulus size in degree
stimulus_size_deg = 2 * atan(stimulus_size/(2*sub_distance)) * (180/pi);
MEG_stimulus_size_deg = 2 * atan(MEG_stimulus_size/(2*MEG_sub_distance)) * (180/pi);

% Fixation cros size (in mm)
fixation_cross_size = 10;
MEG_fixation_cross_size = 5;

% Fixation size in degree
fixation_size_deg = 2 * atan(fixation_cross_size/(2*sub_distance)) * (180/pi);
MEG_fixation_size_deg = 2 * atan(MEG_fixation_cross_size/(2*MEG_sub_distance)) * (180/pi);

% Visual angle of the entire screen in degrees (* 180/pi)
% Note: The stimulus visual angle should not exceed these values
screen_y_deg = (2*atan(screen_height/(2*sub_distance))) * (180/pi);
screen_x_deg = (2*atan(screen_length/(2*sub_distance))) * (180/pi);

% MEG fixation
MEG_fixation_x = 196; 
MEG_fixation_y = 149;

%% Subject Stimulus Location

% Subject locations according to PsychoPy position input
% P1: 20.5 x 6
% P2: 14.25 x -9.5
% P3: 15.25 x 5
% P4: 12 x 5
% P5: 24 x -9.5
% P6: 18.75 x -8.25
% P7 (fixation 0 10): 24 x -11.75
% P8 (fixation 0 10): 24 x -11.75

% Center X Y coordinates of stimuli (in mm)
sub_P1_stim_loc = [458, 204];
sub_P2_stim_loc = [399, 58];
sub_P3_stim_loc = [409, 195];
sub_P4_stim_loc = [378, 195];
sub_P5_stim_loc = [491, 58];
sub_P6_stim_loc = [442, 70];
sub_P7_stim_loc = [491, 36];
sub_P8_stim_loc = [491, 36];

% MEG session P4
sub_P4_MEG_stim_loc = [328, 254];

%% Subject HVF Results

% Manually enter HVF values for the left and right eye
sub_P1_HVF_right = [Inf Inf Inf 0 6 27 27 Inf Inf Inf; Inf Inf 0 0 24 28 28 28 Inf Inf;...
    Inf 0 0 5 27 29 31 28 28 Inf; 0 0 0 5 16 29 29 28 26 Inf; 0 0 0 0 6 28 29 9 25 Inf;...
    Inf 0 0 12 17 27 28 26 23 Inf; Inf Inf 0 0 9 27 27 27 Inf Inf; Inf Inf Inf 0 22 24 24 Inf Inf Inf];
sub_P1_HVF_left = [Inf Inf Inf 0 0 27 25 Inf Inf Inf; Inf Inf 0 0 0 29 29 29 Inf Inf;...
    Inf 0 0 0 0 30 31 29 27 Inf; Inf 0 0 0 3 31 30 28 28 27; Inf 0 0 0 0 30 30 30 29 24;...
    Inf 0 0 0 0 28 27 29 27 Inf; Inf Inf 0 0 0 26 28 25 Inf Inf; Inf Inf Inf 2 4 28 29 Inf Inf Inf];

sub_P2_HVF_right = [Inf Inf Inf 30 28 31 32 Inf Inf Inf; Inf Inf 31 31 31 31 33 34 Inf Inf;...
    Inf 30 31 31 33 34 35 33 32 Inf; 21 27 29 31 33 34 34 30 31 Inf; 0 0 2 8 8 34 34 15 33 Inf;...
    Inf 6 0 1 27 33 32 32 33 Inf; Inf Inf 0 0 9 32 33 33 Inf Inf; Inf Inf Inf 20 15 31 36 Inf Inf Inf];
sub_P2_HVF_left = [Inf Inf Inf 30 30 30 28 Inf Inf Inf; Inf Inf 32 29 31 32 31 35 Inf Inf;...
    Inf 31 29 32 32 34 33 33 29 Inf; Inf 25 28 29 33 34 33 31 30 26; Inf 3 0 3 32 34 33 33 30 28;...
    Inf 0 4 0 30 34 33 33 29 Inf; Inf Inf 0 0 13 33 33 33 Inf Inf; Inf Inf Inf 5 11 33 33 Inf Inf Inf];

sub_P3_HVF_right = [Inf Inf Inf 17 15 0 0 Inf Inf Inf; Inf Inf 15 18 16 0 0 0 Inf Inf;...
    Inf 30 30 29 29 0 0 0 0 Inf; 25 29 30 31 27 0 0 0 0 0; 29 30 30 31 32 0 0 0 0 0;...
    26 30 32 30 33 0 0 0 0 0; 29 29 30 33 25 0 0 0 0 0; Inf 26 30 31 30 0 0 0 0 Inf;...
    Inf Inf 28 29 28 0 0 0 Inf Inf; Inf Inf Inf 25 12 0 0 Inf Inf Inf];
sub_P3_HVF_left = [Inf Inf Inf 25 23 0 0 Inf Inf Inf; Inf Inf 25 25 23 0 0 0 Inf Inf;...
    Inf 27 28 31 28 0 0 0 0 Inf; 15 27 31 29 30 0 0 0 0 0; 24 30 29 30 31 0 0 0 0 0;...
    27 28 0 31 31 0 0 0 0 0; 30 29 30 31 28 0 0 0 0 0; Inf 28 28 30 30 0 0 0 0 Inf;...
    Inf Inf 21 21 21 0 0 0 Inf Inf; Inf Inf Inf 14 19 20 0 Inf Inf Inf];

sub_P4_HVF_right = [Inf Inf Inf 28 24 0 0 Inf Inf Inf; Inf Inf 30 29 27 0 0 0 Inf Inf;...
    Inf 29 30 32 29 0 0 0 0 Inf; 24 27 30 33 31 0 0 0 0 Inf; 25 28 30 33 32 32 30 25 28 Inf;...
    Inf 25 30 33 32 32 33 31 32 Inf; Inf Inf 28 31 30 33 33 33 Inf Inf; Inf Inf Inf 26 29 28 29 Inf Inf Inf];
sub_P4_HVF_left = [Inf Inf Inf 27 0 0 0 Inf Inf Inf; Inf Inf 30 29 26 0 0 0 Inf Inf;...
    Inf 31 30 30 29 0 0 0 0 Inf; Inf 28 26 32 32 0 0 0 0 12;Inf 29 25 33 32 32 31 26 27 23;...
    Inf 28 30 33 31 32 32 30 27 Inf; Inf Inf 31 30 31 30 29 29 Inf Inf; Inf Inf Inf 30 30 26 28 Inf Inf Inf];

sub_P5_HVF_right = [Inf Inf Inf 6 4 0 19 Inf Inf Inf; Inf Inf 0 12 8 24 25 23 Inf Inf;...
    Inf 0 6 6 12 26 28 25 28 Inf; 0 0 5 0 0 26 29 26 25 Inf; 0 0 0 0 0 29 26 27 28 Inf;...
    Inf 0 0 0 0 28 30 0 28 Inf; Inf Inf 0 0 7 27 29 28 Inf Inf; Inf Inf Inf 0 2 19 27 Inf Inf Inf];
sub_P5_HVF_left = [Inf Inf Inf 0 0 12 20 Inf Inf Inf; Inf Inf 0 0 0 23 23 20 Inf Inf;...
    Inf 0 0 1 1 25 27 29 23 Inf; Inf 0 0 0 0 27 29 30 28 24; Inf 0 0 0 9 27 30 29 26 27;...
    Inf 3 0 0 8 31 31 30 26 Inf; Inf Inf 2 0 5 28 30 30 Inf Inf; Inf Inf Inf 0 3 25 26 Inf Inf Inf];

sub_P6_HVF_right = [Inf Inf Inf 21 27 24 14 Inf Inf Inf; Inf Inf 31 29 26 23 6 0 Inf Inf;...
    Inf 31 31 33 31 29 0 0 0 Inf; 31 31 32 35 33 29 0 0 0 Inf; 30 31 33 34 33 0 0 0 0 Inf;...
    Inf 29 32 32 32 0 0 0 0 Inf; Inf Inf 32 30 27 0 0 0 Inf Inf; Inf Inf Inf 19 28 11 0 Inf Inf Inf];
sub_P6_HVF_left = [Inf Inf Inf 29 25 2 12 Inf Inf Inf; Inf Inf 31 29 30 20 11 9 Inf Inf;...
    Inf 29 32 31 31 22 0 4 0 Inf; Inf 29 28 33 31 10 0 0 0 0; Inf 29 21 32 32 30 8 0 0 0;...
    Inf 32 31 30 31 22 0 0 0 Inf; Inf Inf 31 30 28 0 3 0 Inf Inf; Inf Inf Inf 27 25 0 0 Inf Inf Inf];

sub_P7_HVF_right = [Inf Inf Inf 21 26 15 23 Inf Inf Inf; Inf Inf 25 26 27 24 26 26 Inf Inf;...
    Inf 19 27 25 28 27 29 25 23 Inf; 23 24 28 26 29 27 30 18 29 Inf;...
    0 16 28 25 18 30 29 5 24 Inf; Inf 18 6 0 5 28 28 30 23 Inf; Inf Inf 2 4 4 27 30 30 Inf Inf; Inf Inf Inf 7 2 26 29 Inf Inf Inf];
sub_P7_HVF_left = [Inf Inf Inf 15 21 19 21 Inf Inf Inf; Inf Inf 20 20 23 25 27 24 Inf Inf;...
    Inf 14 20 24 25 24 27 27 21 Inf; Inf 19 22 25 26 26 28 26 23 23; Inf 15 12 9 8 28 30 29 26 18;...
    Inf 17 13 10 10 29 28 28 20 Inf; Inf Inf 12 13 4 27 28 26 Inf Inf; Inf Inf Inf 5 7 23 25 Inf Inf Inf];

sub_P8_HVF_right = [Inf Inf Inf 28 26 24 30 Inf Inf Inf; Inf Inf 27 30 29 30 30 33 Inf Inf;...
    Inf 31 29 31 32 32 30 31 33 Inf; 24 30 31 30 30 31 32 22 27 Inf; 15 21 29 28 0 34 33 3 27 Inf;...
    Inf 18 0 0 0 33 35 32 33 Inf; Inf Inf 0 0 0 32 31 27 Inf Inf; Inf Inf Inf 0 0 28 31 Inf Inf Inf];
sub_P8_HVF_left = [Inf Inf Inf 32 27 25 29 Inf Inf Inf; Inf Inf 29 30 30 29 29 31 Inf Inf;...
    Inf 35 28 30 32 33 33 30 27 Inf; Inf 30 26 32 33 33 31 31 28 30; Inf 22 0 28 16 32 32 32 30 35;...
    Inf 0 0 0 8 29 30 30 28 Inf; Inf Inf 2 0 11 30 30 30 Inf Inf; Inf Inf Inf 1 6 28 33 Inf Inf Inf];

%% Calculate Stimulus Visual Angle

% Initialize group variables
group_stim_x_deg = [];
group_stim_y_deg = [];
group_field_idx = [];

% Visual angle of stimuli relative to fixation
% Note: For 2 participants fixations was in the top third of the screen

% Loop over subjects
for sub = 1:length(subject_list)

    % Define fixation point (in mm)
    if ismember(subject_list(sub),{'P7', 'P8'})

        fixation_x = 265;
        fixation_y = 242;

    % All other subjects
    else

        fixation_x = 265;
        fixation_y = 147;

    end

    % Find current stimulus coordinates (in mm)
    stim_x = eval(['sub_',subject_list{sub},'_stim_loc(1)']);
    stim_y = eval(['sub_',subject_list{sub},'_stim_loc(2)']);

    % Calculate the Euclidean distance between the fixation and stimulus
    size_x = abs(stim_x - fixation_x);
    size_y = abs(stim_y - fixation_y);

    % Calculate the visual angle
    group_stim_x_deg(sub) = (2*atan(size_x/(2*sub_distance))) * (180/pi);
    group_stim_y_deg(sub) = (2*atan(size_y/(2*sub_distance))) * (180/pi);

    % MEG analysis 
    if isequal(subject_list{sub},'P4')

        % Calculate the Euclidean distance between teh fixation and stimulus
        size_x = abs(sub_P4_MEG_stim_loc(1)- MEG_fixation_x);
        size_y = abs(sub_P4_MEG_stim_loc(2)- MEG_fixation_y);
        
        % Calculate the visual angle
        sub_P4_stim_x_deg = (2*atan(size_x/(2*sub_distance))) * (180/pi);
        sub_P4_stim_y_deg = (2*atan(size_y/(2*sub_distance))) * (180/pi);

    end

    % Indicate top/bottom field index
    if (stim_y - fixation_y) < 0

        group_field_idx(sub,1) = 0;

    else

        group_field_idx(sub,1) = 1;

    end    

end

%% Plot the HVF tests

% Loop over subjects
for sub = 1:(length(subject_list))

    % Define current HVF results
    HVF_left = eval(['sub_',subject_list{sub},'_HVF_left']);
    HVF_right = eval(['sub_',subject_list{sub},'_HVF_right']);
    
    % Loop over eyes
    for eye = 1:2

        % Setup figure
        figure
        hold on
    
        % Labels
        title([subject_list{sub},' ',eye_type{eye},' Eye'])
        ylabel('Visual angle (deg)')
        xlabel('Visual angle (deg)')
    
        % Define axis
        if isequal(subject_list{sub},'P3')

            % Define axis/limits
            x_axis = [-30:6:-6,6:6:30];
            y_axis = [-30:6:-6,6:6:30];

            xlim([-33,33])
            ylim([-33,33])
        
        else

            % Define axis/limits
            x_axis = [-30:6:-6,6:6:30];
            y_axis = [-24:6:-6,6:6:24];

            xlim([-33,33])
            ylim([-27,27])
        
        end

        % Axis ticks
        xticks([-30:6:30])
        yticks([-30:6:30])
        
        % Update colorbar
        colormap(gray)
    
        % Plot HVF
        % Note: Image values need to be flipped for proper plotting due

        % Left eye
        if isequal(eye_type{eye},'Left')

            imagesc(x_axis, y_axis, flipud(HVF_left));

        % Right eye
        else

            imagesc(x_axis, y_axis, flipud(HVF_right));

        end
    
        % Plot stimulus location
        % Note: The plotted circle will match the on-screen stimulus size

        % Top half of visual field
        if isequal(group_field_idx(sub),1)

            circle(group_stim_x_deg(sub),group_stim_y_deg(sub),stimulus_size_deg/2); 
            circle(-group_stim_x_deg(sub),group_stim_y_deg(sub),stimulus_size_deg/2); 

        % Bottom half of visual field
        else

            circle(group_stim_x_deg(sub),-group_stim_y_deg(sub),stimulus_size_deg/2); 
            circle(-group_stim_x_deg(sub),-group_stim_y_deg(sub),stimulus_size_deg/2); 

        end

        % MEG locations for P4 MEG
        if isequal(subject_list{sub}, 'P4')

            circle(sub_P4_stim_x_deg,sub_P4_stim_y_deg,MEG_stimulus_size_deg/2); 
            circle(sub_P4_stim_x_deg,-sub_P4_stim_y_deg,MEG_stimulus_size_deg/2); 

        end

        % Plot reference lines
        yline(0, 'LineWidth',1, 'color', 'k');
        xline(0, 'LineWidth',1, 'color', 'k');

    end
    
end

% Plot circle function
function circle(x,y,r)

    % Define circle parameters
    th = 0:pi/50:2*pi;
    xunit = r * cos(th) + x;
    yunit = r * sin(th) + y;

    hold on

    % Plot a circle
    plot(xunit, yunit,'r')

    hold off

end