function [statistics weights precisions] = sofia_active_learn(origindir,model_id_param,training_precisions,active_file,active_ids,...
                                                              activepool_matrix,activepool_claim_ids,ids_modifiedTestMatrices,claim_mat_claim_ids,...
                                                              ids_base_train_claim,matrix_base_train,avg_sim_sort,base_model_file,base_precisions,print_lines2file_script_filename)
                                                         
% Initialize Variables                                                     
model_start_run_time = datestr(now);
                                    
splitNum = model_id_param{1};
base_tf = model_id_param{5};
num_of_queries = model_id_param{8};
query_strategy = model_id_param{9};
query_strategy_params = model_id_param(9:10);
model_strategy_params = model_id_param(11:12);
model_id = model_id_param{13};
calc_precision_loc = find(training_precisions(:,2)==model_id_param{14});
svm_type = model_param_mat{15};

if strcmpi(svm_type,'SOFIA')
    lambda = 1/model_id_param{2};
    learner_type = model_id_param{3};
    loop_type = model_id_param{4};
    iterations = model_id_param{6};
    input_model = model_id_param{7};
    T_ = 1;
elseif strcmpi(svm_type,'SVM PERF')
    C_ = model_id_param{2};
    E_ = model_id_param{3};
    L_ = model_id_param{4};
    W_ = model_id_param{6};
    T_ = model_id_param{7};
    if T_ ~= 0
        DGSR = cell2mat(model_id_param(16:17));
    end
end

if strfind(query_strategy,'knn');
    similarity_mat = avg_sim_sort; clear avg_sim_sort;
    k = query_strategy_params{2};
    l = size(similarity_mat,1);
    sim_sort(:,:) = sort(similarity_mat(:,:))';
    sim_sort_k(:,:) = sim_sort(1:l,1:k);
    avg_sim(1:l,1) = mean(sim_sort_k(1:l,1:k)');
    avg_sim(:,2) = activepool_claim_ids;
    avg_sim_sort = sortrows(avg_sim, 1);
    clear similarity_mat;
end


if strfind(iterations,'X');
    multiplier = str2num(iterations(1:(strfind(iterations,'X')-1)));
else
    multiplier = 0;
end

workingDir = [origindir 'workspace_split' int2str(splitNum)];
Nfeatures = size(activepool_matrix,2);
num_of_trials = ceil(size(activepool_matrix,1)/num_of_queries)+1;
num_of_test_iterations = size(ids_modifiedTestMatrices,3);

for sample=1:num_of_test_iterations                
    [jk,loc] = ismember(ids_modifiedTestMatrices(:,:,sample),claim_mat_claim_ids);                                
    eval(['new_test_mat',int2str(sample),' = new_claim_mat(loc,:);']);
end
clear ids_modifiedTestMatrices claim_mat_claim_ids

active_query_locations_mat = zeros(num_of_trials,num_of_queries);
active_query_locations_filename = strcat(workingDir,'/base/random_active_query_locations_',int2str(num_of_queries),'.mat');

% Initialize Filenames
saveExperimentDir = [workingDir '/' int2str(model_id)];
saveExperimentFile = [int2str(model_id) '_' datestr(now,'mm-dd-HH-MM-SS')];

train_file        = [saveExperimentDir '/train_' saveExperimentFile '.train_data'];
train_rowNum_file = [saveExperimentDir '/trainrows_' saveExperimentFile '.row_nums'];
model_file        = [saveExperimentDir '/model_' saveExperimentFile '.model'];

fopen(train_file,'w');
fopen(train_rowNum_file,'w');
fopen(model_file_name,'w');
active_file = strrep(active_file,'E:/','/cygdrive/e/');
train_file = strrep(train_file,'E:/','/cygdrive/e/');
train_rowNum_file2 = strrep(train_rowNum_file,'E:/','/cygdrive/e/');
fclose('all');

master_arrayOfmetric = zeros(num_of_trials,length(training_precisions),num_of_test_iterations);
master_arrayOfmetric(1,:,:) = base_precisions;
train_matrix = matrix_base_train;
train_ids = ids_base_train_claim;
bias = 0;
W = [];

if base_tf
    W = textread(base_model_file)';
    bias = W(1);
    copyfile(base_model_file,model_file,'f');  
elseif ~isempty(input_model) || input_model~=0
    loc = strfind(input_model,'_');
    input_model = char(input_model);
    input_model_id = cellstr(input_model(1:loc-1));
    input_model_file = [workingDir '/' input_model_id '/' input_model ];
    copyfile(input_model_file,model_file,'f');  
end 

tic
time = cell(num_of_trials,2);
for trial=2:num_of_trials
    
    if(size(activepool_matrix,1)<num_of_queries)                
        num_of_queries = size(activepool_matrix,1);                
    end
    
    % Select Queries
    if(trial==2 && ~strcmpi(query_strategy,'random') && ~base_tf)
        try
            load(active_query_locations_filename);
        catch
            L = length(activepool_claim_ids);
            [jk,loc] = sort(rand(L,1));
            indices = 1:L;
            active_query_locations = indices(loc(1:num_of_queries));
            save(active_query_locations_filename,'active_query_locations');
            clear loc L indices jk
        end
    else
        try           
            if strcmpi(svm_type,'SVM PERF') && T_~=0;               
                [tf loc] = ismember(activepool_claim_ids,active_ids);
                fprintf(fopen(train_rowNum_file,'w'),'%u\n',sort(loc)); fclose('all');           
                eval(['!perl -w ',print_lines2file_script_filename,' ',active_file,' ',train_file,' ',train_rowNum_file2]);
                
                result_file = [saveExperimentDir '/result_' saveExperimentFile '.result'];                
                eval(['!E:/Users/Gaurav/IBC/shared_functions/svm_perf_classify.exe ' train_file ' ' model_file ' ' result_file]);
                activepool_W_scores = textread(result_file);
            else
                activepool_W_scores = activepool_matrix(:,2:end)*W+bias;
            end
            
            active_query_locations = get_candidates_for_query_svm(activepool_W_scores,activepool_matrix,query_strategy_params,...
                                                                  num_of_queries,saveExperimentDir,avg_sim_sort,...
                                                                  activepool_claim_ids,trial);           
            active_query_locations_mat(trial,1:length(active_query_locations)) = active_query_locations;
            
        catch MException
            trial
            keyboard;
        end
    end
    
    % Modify avg_sim_sort 
    if ~isempty(avg_sim_sort)
        [jk,loc] = ismember(activepool_claim_ids(active_query_locations),avg_sim_sort(:,2));
        avg_sim_sort_logical = true(size(avg_sim_sort,1),1);
        avg_sim_sort_logical(loc) = false;
        avg_sim_sort = avg_sim_sort(avg_sim_sort_logical,:);
    end

    % Update matrices
    try
        [train_matrix train_ids activepool_matrix activepool_claim_ids train_matrix_ids] = get_updated_train_matrices_svm...
            (active_query_locations,train_matrix(1:length(train_ids),:),train_ids,activepool_matrix,activepool_claim_ids,model_strategy_params);
    catch MException
        trial
        keyboard;
    end
    time{trial,1} = toc;
    
    % Train Model
    try
        if multiplier>0 && trial>2
            itr = int2str(multiplier*length(loc));
        elseif trial==2 && ~base_tf
            itr = '10000000';
        else
            itr = iterations;
        end

        [jk,loc] = ismember(train_matrix_ids,active_ids);
        fprintf(fopen(train_rowNum_file,'w'),'%u\n',sort(loc)); fclose('all');                   
        eval(['!perl -w ',print_lines2file_script_filename,' ',active_file,' ',train_file,' ',train_rowNum_file2]);
        
        if strcmpi(svm_type,'SOFIA')
 
            if (model_strategy~=0 || ~strcmpi(model_strategy,'0')) && ((trial>2 && ~base_tf) || base_tf)
                model_file = sofia_run_training(origindir,Nfeatures,learner_type,loop_type,lambda,itr,train_file,model_file,model_file);
            else
                model_file = sofia_run_training(origindir,Nfeatures,learner_type,loop_type,lambda,itr,train_file,model_file);
            end
            W = textread(model_file_name)';
            bias = W(1);
            W = W(2:end);
        
        elseif strcmpi(svm_type,'SVM PERF')
            
            svm_perf_run_training(origindir, train_file, model_file, C_, E_, L_, W_, T_, DGSR)
            W = zeros(size(new_test_mat,2),1);
            
            if T_==0
                feature_score_mat = svm_read_model_file(model_file_name);               
                W(feature_score_mat(:,1)) = feature_score_mat(:,2);                
            else
                result_file = [saveExperimentDir '/result_' saveExperimentFile '.result'];
                
                %Test Model
                for sample=1:num_of_test_iterations
                    test_file = [origindir 'workspace_split' int2str(splitNum) '/base/test_mat_1' int2str(sample) '.test_data'];
                    eval(['!E:/Users/Gaurav/IBC/shared_functions/svm_perf_classify.exe ' test_file ' ' model_file ' ' result_file]);
                    test_scores = textread(result_file);
                    eval(['test_labels = new_test_mat',int2str(sample),'(:,1);']);
                    master_arrayOfmetric(trial,:,sample) = precision_calc(test_scores,test_labels,training_precisions);
                    clear test_scores test_labels new_test_mat
                end
                return                    
            end
        
        end

    catch MException
        trial                
        keyboard;
    end

    %Test Model
    for sample=1:num_of_test_iterations                                             
        eval(['new_test_mat = ','new_test_mat',int2str(sample),';']);
        test_scores = new_test_mat(:,2:end)*W+bias;
        test_labels = new_test_mat(:,1);
        master_arrayOfmetric(trial,:,sample) = precision_calc(test_scores,test_labels,training_precisions);
        clear test_scores test_labels new_test_mat
    end
    
    time{trial,2} = toc;
end
run_time = toc/(num_of_trials-1);

% save output
save([saveExperimentDir '/' saveExperimentFile '.mat'],'master_arrayOfmetric');
xlswrite([saveExperimentDir '/' saveExperimentFile '.xlsx'],[{'Query' 'Eval'}; run_time],'Time');
xlswrite([saveExperimentDir '/' saveExperimentFile '.xlsx'],active_query_locations_mat,'Query Locations');

model_end_run_time = datestr(now);

precisions = mean(master_arrayOfmetric(:,calc_precision_loc,:),3);
statistics = {model_id,model_start_run_time,model_end_run_time,run_time,splitNum};
weights = [bias; W];








