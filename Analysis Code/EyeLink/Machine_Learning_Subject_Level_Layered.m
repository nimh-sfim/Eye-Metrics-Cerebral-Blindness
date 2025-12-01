%% Classification of Sighted and Blinded Field

% Trains a model on pupil, blink, and microsaccade data and train/test a
% two-layered model to assess the eye metric dynamics

% Written by: Sharif I. Kronemer
% Last Modified Date: 7/20/2025

clear all

%% Directories

% Root directory
root_dir = '/Users/kronemersi/Library/CloudStorage/OneDrive-NationalInstitutesofHealth/Cortical_Blindness_Study/Analysis';

% Output directory
output_dir = fullfile(root_dir,'Group_Analysis','Classification_Results');

% Check output dir
if isempty(dir(output_dir))

    mkdir(output_dir)

end 

%% Parameters

% Patient (1) or control group (0) or custom list (2)
group_type = 1; 

% Define subjects to run
if group_type == 1

    % Patients
    subject_list = {'P1','P2','P3','P4','P5','P6','P7','P8'};

    % Group name
    group_name = 'Patients';

    % Stimulus side
    % Note: That for all subjects either the left or right is
    % blinded/sighted; the approach is to analyze the left and right
    % seperately and those store the result corresponding with the sighted
    % versus blinded category according to each participant.
    side_types = {'left','right'};

elseif group_type == 0

    % Controls
    subject_list = {'C1','C2','C3','C4','C5','C6','C7','C8'};

    % Group name
    group_name = 'Controls';

    % Stimulus side
    side_types = {'left','right'};

end

% Create visualization (yes = 'y'; no = 'no')
create_visualization = 'n';

% Query interval
query_interval = [9001:13000];
query_interval_name = '9001_13000';

% Eye data type
% Note: Selects which eye data to include as features for the classifier
eye_type = {'pupil','blink','microsaccade'};

% Stimuli types
stimulus_comp = {{'distractor','ISI_distractor'},{'Glare_nonglare_white_iso','ISI_glare_nonglare_white_iso'}};
stimulus_comp_name = {'Distractor_vs_ISI Distractor','Glare_Nonglare_White_Iso_vs_ISI'};

%% Start Modeling

% Loop over comparison
for comp = 1:length(stimulus_comp)

    % Current comp
    current_comp = stimulus_comp{comp};
    current_comp_name = stimulus_comp_name{comp};

    disp(['Running ',group_name, ' ',current_comp_name,'...'])

    % Controls group variables
    if isequal(group_type,0)
        
        group_PPV_left = [];
        group_NPV_left = [];
        group_PPV_right = [];
        group_NPV_right = [];

        group_predicted_scores_left = {};
        group_predicted_scores_right = {};
        group_predicted_labels_left = {};
        group_predicted_labels_right = {};

        group_true_labels_left = {};
        group_true_labels_right = {};

        group_ROC_AUC_left = [];
        group_ROC_AUC_right = [];

        group_accuracy_left = [];
        group_accuracy_right = [];
        group_chance_left = [];
        group_chance_right = [];
    
    % Patients group variables
    elseif isequal(group_type,1)

        group_PPV_sighted = [];
        group_NPV_sighted = [];
        group_PPV_blind = [];
        group_NPV_blind = [];
    
        group_predicted_scores_sighted = {};
        group_predicted_scores_blind = {};
        group_predicted_labels_sighted = {};
        group_predicted_labels_blind = {};

        group_true_labels_sighted = {};
        group_true_labels_blind = {};

        group_ROC_AUC_sighted = [];
        group_ROC_AUC_blind = [];
    
        group_accuracy_sighted = [];
        group_accuracy_blind = [];
        group_chance_sighted = [];
        group_chance_blind = [];

        blind_aware_accuracy_blind = [];
        blind_unaware_accuracy_blind = [];
        blind_aware_AUC_blind = [];
        blind_unaware_AUC_blind = [];
        blind_aware_chance = [];
        blind_unaware_chance = [];

    end

    % Loop over subjects
    for sub = 1:length(subject_list)
    
        % Define current subject
        subID = subject_list{sub};
    
        disp(['Adding ',subID,'...'])
    
        % Load data
        load(fullfile(root_dir,'Subject_Analysis',subID,'OP4','Glare_illusion_EyeLink_results.mat'));

        % Loop over stimulus side
        for side = 1:length(side_types)
        
            % Define current side
            current_side = side_types{side};

            % Initial variables
            all_eye_predicted_scores = [];
            glare_data = [];
            nonglare_data = [];
            white_data = [];
            iso_data = [];
            
            ISI_glare_data = [];
            ISI_nonglare_data = [];
            ISI_white_data = [];
            ISI_iso_data = [];

            target_data = [];
            ISI_target_data = [];
            
            eye_type_idx = [];

            disp(['Running ',current_side,' visual field...'])
        
            % Loop over data type
            for eye = 1:length(eye_type)
        
                % Current type
                current_type = eye_type{eye};
    
                disp(['Adding ',current_type,' data...'])

                % Glare_Nonglare_White_Iso
                if isequal(current_comp_name,'Glare_Nonglare_White_vs_ISI') || ...
                    isequal(current_comp_name,'Glare_Nonglare_White_Iso_vs_ISI') || ...
                    isequal(current_comp_name,'Glare_Nonglare_vs_ISI')

                    % Add data
                    glare_data = [glare_data, eval(['glare_',current_side,'_',current_type,'_epochs(:,query_interval)'])];
                    nonglare_data = [nonglare_data, eval(['nonglare_',current_side,'_',current_type,'_epochs(:,query_interval)'])];
                    white_data = [white_data, eval(['white_',current_side,'_',current_type,'_epochs(:,query_interval)'])];
                    iso_data = [iso_data, eval(['iso_',current_side,'_',current_type,'_epochs(:,query_interval)'])];

                    ISI_glare_data = [ISI_glare_data, eval(['ISI_glare_',current_side,'_',current_type,'_epochs(:,query_interval)'])];
                    ISI_nonglare_data = [ISI_nonglare_data, eval(['ISI_nonglare_',current_side,'_',current_type,'_epochs(:,query_interval)'])];
                    ISI_white_data = [ISI_white_data, eval(['ISI_white_',current_side,'_',current_type,'_epochs(:,query_interval)'])];
                    ISI_iso_data = [ISI_iso_data, eval(['ISI_iso_',current_side,'_',current_type,'_epochs(:,query_interval)'])];

                    % Update idx
                    eye_type_idx = [eye_type_idx,zeros(1,length(query_interval))+eye];

                    % Check data
                    if ~isequal(length(eye_type_idx),size(glare_data,2))

                        disp('Data and eye type idx column mismatch!')

                    end

                % Binary class
                else
            
                    target_data = [target_data, eval([current_comp{1},'_',current_side,'_',current_type,'_epochs(:,query_interval)'])];
                    ISI_target_data = [ISI_target_data, eval([current_comp{2},'_',current_side,'_',current_type,'_epochs(:,query_interval)'])];
                    
                    % Update idx
                    eye_type_idx = [eye_type_idx,zeros(1,length(query_interval))+eye];

                    % Check data
                    if ~isequal(length(eye_type_idx),size(target_data,2))

                        disp('Data and eye type idx column mismatch!')

                    end

                end

            end

            %% Organize Data
    
            % Glare, nonglare, white, and iso
            if isequal(current_comp_name,'Glare_Nonglare_White_Iso_vs_ISI')
                
                % Training data - combined stimulus data epochs
                training_data = [glare_data; nonglare_data; white_data; iso_data; ISI_glare_data; ISI_nonglare_data; ISI_white_data; ISI_iso_data];

                % Create labels
                glare_labels = ones(size(glare_data,1),1); % Class 1
                nonglare_labels = ones(size(nonglare_data,1),1); % Class 1
                white_labels = ones(size(white_data,1),1); % Class 1
                iso_labels = ones(size(iso_data,1),1); % Class 1

                ISI_glare_labels = ones(size(ISI_glare_data,1),1)+1; % Class 2
                ISI_nonglare_labels = ones(size(ISI_nonglare_data,1),1)+1; % Class 2
                ISI_white_labels = ones(size(ISI_white_data,1),1)+1; % Class 2
                ISI_iso_labels = ones(size(ISI_iso_data,1),1)+1; % Class 2

                % True labels - combine target and control labels
                % Note: Label order must match training data
                true_labels = [glare_labels; nonglare_labels; white_labels; iso_labels; ISI_glare_labels; ISI_nonglare_labels; ISI_white_labels; ISI_iso_labels];

            % Binary class
            else 

                % Training data - combine target and control data epochs
                training_data = [target_data; ISI_target_data];
                
                % Create target and control labels
                target_labels = ones(size(target_data,1),1); % Class 1
                ISI_target_labels = ones(size(ISI_target_data,1),1)+1; % Class 2
    
                % True labels - combine target and control labels
                true_labels = [target_labels; ISI_target_labels];
            
            end

            % Find NaN
            % Note: In eye metric epoch processes some epochs are NaNed
            if any(any(isnan(training_data)))

                % Create row index of NaNs
                nan_row = isnan(sum(training_data,2));

                % Remove NaN data/labels
                % Note: This approach removes trials that may have values in
                % one eye data type but not others; therefore, all data types
                % must be present for a trial to be included in the
                % classification procedure.
                training_data(nan_row,:) = [];
                true_labels(nan_row,:) = [];

            end

            % Check labels and data are the same size
            if ~isequal(size(training_data,1),size(true_labels,1))
            
                error('Training and test data sizes mistmatch!')
            
            end

            %% Classification

            % Setup k-fold partitions
            lay_cv = cvpartition(true_labels, 'KFold', 10);

            % Initialize matrix to store Layer 0 predictions
            num_samples = size(training_data,1);
            num_eye_types = max(eye_type_idx);
            lay0_scores = zeros(num_samples, num_eye_types);
            
            % Loop over folds
            for fold = 1:lay_cv.NumTestSets

                % Find the training/test indices
                train_idx = lay_cv.training(fold);
                test_idx = lay_cv.test(fold);
                
                % Loop over eye type
                for eye = 1:num_eye_types

                    % Train on train set for this eye type
                    train_fold = training_data(train_idx, eye_type_idx == eye);
                    train_labels = true_labels(train_idx);
                    
                    % SVM
                    model = fitcsvm(train_fold, train_labels, 'Standardize', true, 'KernelFunction', 'linear');

                    % Predict on test set
                    test_fold = training_data(test_idx, eye_type_idx == eye);
                    [~, scores] = predict(model, test_fold);
                    
                    % Store only the class 1 score
                    lay0_scores(test_idx, eye) = scores(:,1);

                end

            end
                        
            % Train layer 1 using layer 0 scores
            model1 = fitcsvm(lay0_scores, true_labels, 'KernelFunction', 'linear');

            % Cross validation and class prediction
            CV_model1 = crossval(model1, 'cvpartition', lay_cv);
            [predicted_labels, predicted_scores] = kfoldPredict(CV_model1);
            
            % Accuracy
            accuracy = length(find(predicted_labels == true_labels))/length(true_labels);

            % Find the chance level accuracy
            chance_level = length(find(true_labels == 1))/length(true_labels);
            
            % PPV and NPV
            PPV = length(find(predicted_labels == true_labels & predicted_labels == 1))/length(find(predicted_labels == 1));
            NPV = length(find(predicted_labels == true_labels & predicted_labels == 2))/length(find(predicted_labels == 2));

            % ROC AUC
            [ROC_x,ROC_y,ROC_T,ROC_AUC,OPTROCPT] = perfcurve(true_labels,predicted_scores(:,1),1);
            
            %% Store Group Data
    
            % Patient
            if isequal(group_type,1)

                % Patients - Blinded field
                if ismember(subID,{'P3','P4','P6'}) && isequal(current_side,'right') || ...
                        ismember(subID,{'P1','P2','P5','P7','P8','115'}) && isequal(current_side,'left')

                    % Add subject data
                    group_PPV_blind = [group_PPV_blind; PPV];
                    group_NPV_blind = [group_NPV_blind; NPV];
                    group_ROC_AUC_blind = [group_ROC_AUC_blind; ROC_AUC];
                    group_accuracy_blind = [group_accuracy_blind; accuracy];
                    group_chance_blind = [group_chance_blind; chance_level];

                    group_predicted_scores_blind = [group_predicted_scores_blind, predicted_scores(:,1)];
                    group_predicted_labels_blind = [group_predicted_labels_blind, predicted_labels(:,1)];
                    group_true_labels_blind = [group_true_labels_blind, true_labels];

                    % Blind aware participants
                    if ismember(subID,{'P2','P4','P7','P8'})

                        blind_aware_accuracy_blind = [blind_aware_accuracy_blind; accuracy];
                        blind_aware_AUC_blind = [blind_aware_AUC_blind; ROC_AUC];
                        blind_aware_chance = [blind_aware_chance; chance_level];

                    % Blind unaware participants
                    else

                        blind_unaware_accuracy_blind = [blind_unaware_accuracy_blind; accuracy];
                        blind_unaware_AUC_blind = [blind_unaware_AUC_blind; ROC_AUC];
                        blind_unaware_chance = [blind_unaware_chance; chance_level];

                    end
                    
                % Patients - Sighted field
                elseif ismember(subID,{'P3','P4','P6'}) && isequal(current_side,'left') || ...
                        ismember(subID,{'P1','P2','P5','P7','P8','115'}) && isequal(current_side,'right')
    
                    % Add subject data
                    group_PPV_sighted = [group_PPV_sighted; PPV];
                    group_NPV_sighted = [group_NPV_sighted; NPV];
                    group_ROC_AUC_sighted = [group_ROC_AUC_sighted; ROC_AUC];
                    group_accuracy_sighted = [group_accuracy_sighted; accuracy];
                    group_chance_sighted = [group_chance_sighted; chance_level];

                    group_predicted_scores_sighted = [group_predicted_scores_sighted, predicted_scores(:,1)];
                    group_predicted_labels_sighted = [group_predicted_labels_sighted, predicted_labels(:,1)];
                    group_true_labels_sighted = [group_true_labels_sighted, true_labels];

                end

            % Controls
            elseif isequal(group_type,0)

                % Controls - Left side
                if isequal(current_side,'left') 

                    % Add subject results
                    group_PPV_left = [group_PPV_left; PPV];
                    group_NPV_left = [group_NPV_left; NPV];
                    group_ROC_AUC_left = [group_ROC_AUC_left; ROC_AUC];

                    group_predicted_scores_left = [group_predicted_scores_left, predicted_scores(:,1)];
                    group_predicted_labels_left = [group_predicted_labels_left, predicted_labels(:,1)];
                    group_true_labels_left = [group_true_labels_left, true_labels];

                    group_accuracy_left = [group_accuracy_left; accuracy];
                    group_chance_left = [group_chance_left; chance_level];

                % Controls - Right side
                elseif isequal(current_side,'right')

                    % Add subject results
                    group_PPV_right = [group_PPV_right; PPV];
                    group_NPV_right = [group_NPV_right; NPV];
                    group_ROC_AUC_right = [group_ROC_AUC_right; ROC_AUC];
                  
                    group_predicted_scores_right = [group_predicted_scores_right, predicted_scores(:,1)];
                    group_predicted_labels_right = [group_predicted_labels_right, predicted_labels(:,1)];
                    group_true_labels_right = [group_true_labels_right, true_labels];

                    group_accuracy_right = [group_accuracy_right; accuracy];
                    group_chance_right = [group_chance_right; chance_level];

                end

            end

        end

    end

    %% Save group data
    cd(output_dir)

    if isequal(group_type,1)

        save([group_name,'_',current_comp_name,'_',query_interval_name,'_Layered_Classification_Resuls.mat'],'group*','subject_list','blind_aware*','blind_unaware*')

    else

        save([group_name,'_',current_comp_name,'_',query_interval_name,'_Layered_Classification_Resuls.mat'],'group*','subject_list')

    end

    %% Group Visualization

    % Setup figure
    ROC_fig = figure
    hold on

    title([group_name,' - ',current_comp_name, ' - ' query_interval_name],'Interpreter','none')

    xlabel('1-Specificity')
    ylabel('Sensitivity')
    xlim([0 1])
    ylim([0 1])
    
    xticks([0:0.2:1])
    yticks([0:0.2:1])

    % Plot 45deg line
    plot([0 1],[0 1],'k')

    % Loop over subjects
    for sub = 1:length(subject_list)

        % Controls
        if isequal(group_type, 0)
                
            % Find the ROC values
            [ROC_x,ROC_y,ROC_T,ROC_AUC,OPTROCPT] = perfcurve(group_true_labels_left{1,sub},group_predicted_scores_left{1,sub},1);
    
            % Plot ROC values
            plot(ROC_x,ROC_y,'g')
    
            [ROC_x,ROC_y,ROC_T,ROC_AUC,OPTROCPT] = perfcurve(group_true_labels_right{1,sub},group_predicted_scores_right{1,sub},1);
    
            % Plot ROC values
            plot(ROC_x,ROC_y,'r')

        % Patients
        elseif isequal(group_type, 1)

             % Find the ROC values
            [ROC_x,ROC_y,ROC_T,ROC_AUC,OPTROCPT] = perfcurve(group_true_labels_sighted{1,sub},group_predicted_scores_sighted{1,sub},1);
    
            % Plot ROC values
            if ismember(sub,[2,4,7,8])
                
                plot(ROC_x,ROC_y,'--r')

            else

                plot(ROC_x,ROC_y,'r')

            end
    
            [ROC_x,ROC_y,ROC_T,ROC_AUC,OPTROCPT] = perfcurve(group_true_labels_blind{1,sub},group_predicted_scores_blind{1,sub},1);
    
            % Plot ROC values
            if ismember(sub,[2,4,7,8])
                
                plot(ROC_x,ROC_y,'--b')

            else
                
                plot(ROC_x,ROC_y,'b')

            end
        end

    end    

    % Save figure
    cd(output_dir)
    savefig(ROC_fig,['ROC_',group_name,'_',query_interval_name,'_',current_comp_name,'.fig'])

end