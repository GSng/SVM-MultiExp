function [statistics weights precision_avg precisions] = svm_multi_active_learn(origindir,workingDir,model_id_param,training_precisions,active_file,active_ids,...
                                                                  pool_matrix,pool_claim_ids,new_claim_mat,testset_claim_id_mat,trial_ids,claim_mat_ids,...
                                                                  train_ids,train_matrix,avg_sim_sort,base_model_file,base_precisions,print_lines2file_script_filename)

cd('E:\cygwin\bin');
                                                              
% Initialize Variables                                                     
model_start_run_time = datestr(now);
                                    
splitNum = model_id_param{1};
base_tf = model_id_param{5};
num_of_queries = model_id_param{8};
query_strategy = model_id_param{9};
query_strategy_params = model_id_param(9:10);
model_strategy = model_id_param{11};
model_strategy_params = model_id_param(11:12);
model_id = model_id_param{13};
calc_precision_loc = find(training_precisions(:,2)==model_id_param{14});
svm_type = model_id_param{15};
input_model = [];

if strcmpi(svm_type,'SOFIA')
    lambda = num2str(1/model_id_param{2});
    learner_type = model_id_param{3};
    loop_type = model_id_param{4};
    iterations = model_id_param{6};
    input_model = model_id_param{7};
    T_ = 1;
    
    if strfind(iterations,'X');
        multiplier = str2num(iterations(1:(strfind(iterations,'X')-1)));
    else
        multiplier = 0;
    end
    
elseif strcmpi(svm_type,'SVM PERF')
    C_ = model_id_param{2};
    E_ = model_id_param{3};
    L_ = model_id_param{4};
    W_ = model_id_param{6};
    T_ = model_id_param{7};
    DGSR = cell2mat(model_id_param(16:17));
end

if ~isempty(strfind(query_strategy,'knn'));
    similarity_mat = avg_sim_sort; clear avg_sim_sort;
    k = query_strategy_params{2};
    l = size(similarity_mat,1);
    sim_sort(:,:) = sort(similarity_mat(:,:))';
    sim_sort_k(:,:) = sim_sort(1:l,1:k);
    avg_sim(1:l,1) = mean(sim_sort_k(1:l,1:k)');
    avg_sim(:,2) = pool_claim_ids;
    avg_sim_sort = sortrows(avg_sim, 1);
    clear similarity_mat;
end

% workingDir = [origindir 'active_eval/workspace_split' int2str(splitNum)];
Nfeatures = size(pool_matrix,2);
n_iterations = ceil(size(pool_matrix,1)/num_of_queries)+1;
n_trials = length(trial_ids);

for sample=1:n_trials                
    [jk,loc] = ismember(testset_claim_id_mat(:,sample),claim_mat_ids);                                
    eval(['new_test_mat',int2str(sample),' = new_claim_mat(loc,:);']);
end
clear ids_modifiedTestMatrices claim_mat_ids new_claim_mat

active_query_locations_mat = zeros(n_iterations,num_of_queries);
active_query_locations_filename = strcat('E:/Projects/SVMpipeline/active_eval/random_active_query_locations_',int2str(num_of_queries),'.mat');

% Initialize Filenames
saveExperimentDir = [workingDir '/' int2str(model_id)];
mkdir(saveExperimentDir);
saveExperimentFile = [int2str(model_id) '_' datestr(now,'mm-dd-HH-MM-SS')];

train_file        = [saveExperimentDir '/train_' saveExperimentFile '.train_data'];
train_rowNum_file = [saveExperimentDir '/trainrows_' saveExperimentFile '.row_nums'];
model_file        = [saveExperimentDir '/model_' saveExperimentFile '.model'];

fopen(train_file,'w+');
fopen(train_rowNum_file,'w+');
fopen(model_file,'w+');
active_file = strrep(active_file,'E:/','/cygdrive/e/');
train_file = strrep(train_file,'E:/','/cygdrive/e/');
train_rowNum_file2 = strrep(train_rowNum_file,'E:/','/cygdrive/e/');
fclose('all');

master_arrayOfmetric = zeros(n_iterations,(length(training_precisions)+2),n_trials);

bias = 0;
W = [];

if base_tf
    if strcmpi(svm_type,'SOFIA')
        W = textread(base_model_file)';
        bias = W(1);
        W = W(2:end);
    elseif strcmpi(svm_type,'SVM PERF')
        W = zeros(Nfeatures-1,1);
        feature_score_mat = svm_read_model_file(base_model_file);               
        W(feature_score_mat(:,1)) = feature_score_mat(:,2);
        bias = 0;
    end
    copyfile(base_model_file,model_file,'f');
else
    base_precisions(:,3:end) = 0;
    
    if ~isempty(input_model) && input_model~=0 && ~strcmpi(input_model,'0')
        loc = strfind(input_model,'_');
        input_model = char(input_model);
        input_model_id = cellstr(input_model(1:loc-1));
        input_model_file = [workingDir '/' input_model_id '/' input_model ];
        copyfile(input_model_file,model_file,'f');
    end
    train_ids = [];
    train_matrix = [];
end

master_arrayOfmetric(1,:,:) = base_precisions';
    
tic
time = cell(n_iterations,2);
for iteration=2:n_iterations
    
    if(size(pool_matrix,1)<num_of_queries)                
        num_of_queries = size(pool_matrix,1);                
    end
    
    % Select Queries
    if(iteration==2 && ~strcmpi(query_strategy,'random') && ~base_tf)
        try
            load(active_query_locations_filename);
        catch
            L = length(pool_claim_ids);
            [jk,loc] = sort(rand(L,1));
            indices = 1:L;
            active_query_locations = indices(loc(1:num_of_queries));
            save(active_query_locations_filename,'active_query_locations');
            clear loc L indices jk
        end
    else
        try           
            activepool_W_scores = [];
            
            if strcmpi(svm_type,'SVM PERF') && T_~=0;               
                [tf loc] = ismember(pool_claim_ids,active_ids);
                fprintf(fopen(train_rowNum_file,'w'),'%u\n',sort(loc)); fclose('all');           
                eval(['!perl -w ',print_lines2file_script_filename,' ',active_file,' ',train_file,' ',train_rowNum_file2]);
                
                result_file = [saveExperimentDir '/result_' saveExperimentFile '.result'];                
                eval(['!E:/Users/Gaurav/IBC/shared_functions/svm_perf_classify.exe ' train_file ' ' model_file ' ' result_file]);
                activepool_W_scores = textread(result_file);
            elseif ~isempty(W)
                activepool_W_scores = pool_matrix(:,2:end)*W+bias;
            end
            
            active_query_locations = get_candidates_for_query_svm(activepool_W_scores,pool_matrix,query_strategy_params,...
                                                                  num_of_queries,saveExperimentDir,avg_sim_sort,pool_claim_ids);
           
            active_query_locations_mat(iteration,1:length(active_query_locations)) = active_query_locations;
            
        catch MException
            Mexception.message
            model_id
            iteration
            matlabpool close
            keyboard;
        end
    end
    
    % Modify avg_sim_sort 
    if ~isempty(avg_sim_sort)
        [jk,loc] = ismember(pool_claim_ids(active_query_locations),avg_sim_sort(:,2));
        avg_sim_sort_logical = true(size(avg_sim_sort,1),1);
        avg_sim_sort_logical(loc) = false;
        avg_sim_sort = avg_sim_sort(avg_sim_sort_logical,:);
    end

    % Update matrices
    try
        [train_matrix train_ids pool_matrix pool_claim_ids train_matrix_ids] = get_updated_train_matrices_svm...
            (active_query_locations,train_matrix(1:length(train_ids),:),train_ids,pool_matrix,pool_claim_ids,model_strategy_params);
    catch MException
        Mexception.message
        model_id
        iteration        
        matlabpool close
        keyboard;
    end
    time{iteration,1} = toc;
    
    % Train Model
    try

        [jk,loc] = ismember(train_matrix_ids,active_ids);
        fprintf(fopen(train_rowNum_file,'w'),'%u\n',sort(loc)); fclose('all');                   
        eval(['!perl -w ',print_lines2file_script_filename,' ',active_file,' ',train_file,' ',train_rowNum_file2]);
        
        if strcmpi(svm_type,'SOFIA')
            
            if multiplier>0 && iteration>2
                itr = int2str(multiplier*length(loc));
            elseif iteration==2 && ~base_tf
                itr = 10000000;
            else
                itr = iterations;
            end
 
            if (model_strategy~=0 || ~strcmpi(model_strategy,'0')) && ((iteration>2 && ~base_tf) || base_tf)
                model_file = sofia_run_training(origindir,Nfeatures,learner_type,loop_type,lambda,int2str(itr),train_file,model_file,model_file);
            else
                model_file = sofia_run_training(origindir,Nfeatures,learner_type,loop_type,lambda,int2str(itr),train_file,model_file);
            end
            W = textread(model_file)';
            bias = W(1);
            W = W(2:end);
        
        elseif strcmpi(svm_type,'SVM PERF')
            
            svm_perf_run_training(origindir, train_file, model_file, C_, E_, L_, W_, T_, DGSR)
            W = zeros(Nfeatures-1,1);
            bias = 0;
            
            if T_==0
                feature_score_mat = svm_read_model_file(model_file);               
                W(feature_score_mat(:,1)) = feature_score_mat(:,2);                
            else
                result_file = [saveExperimentDir '/result_' saveExperimentFile '.result'];
                
                %Test Model
                for sample=1:n_trials
                    test_file = [origindir 'workspace_split' int2str(splitNum) '/base/test_mat_1' int2str(sample) '.test_data'];
                    eval([origindir 'svm_run_multi_exp/svm_perf_classify.exe ' test_file ' ' model_file ' ' result_file]);
                    test_scores = textread(result_file);
                    eval(['test_labels = new_test_mat',int2str(sample),'(:,1);']);
                    master_arrayOfmetric(iteration,:,sample) = precision_calc(test_scores,test_labels,training_precisions);
                    clear test_scores test_labels new_test_mat
                end
                return                    
            end
        
        end

    catch MException
        Mexception.message
        model_id
        iteration
        matlabpool close
        keyboard;
    end

    %Test Model
    try
        for sample=1:n_trials                                             
            master_arrayOfmetric(iteration,1,sample) = iteration;
            master_arrayOfmetric(iteration,2,sample) = trial_ids(sample);
            eval(['new_test_mat = ','new_test_mat',int2str(sample),';']);
            test_scores = new_test_mat(:,2:end)*W+bias;
            test_labels = new_test_mat(:,1);
            master_arrayOfmetric(iteration,3:end,sample) = precision_calc(test_scores,test_labels,training_precisions);
            clear test_scores test_labels new_test_mat
        end
    catch MException
        Mexception.message
        model_id
        iteration
        matlabpool close
        keyboard;
    end
    time{iteration,2} = toc;
end
run_time = toc/(n_iterations-1);

% save output
save([saveExperimentDir '/' saveExperimentFile '.mat'],'master_arrayOfmetric');
xlswrite([saveExperimentDir '/' saveExperimentFile '.xlsx'],[{'Query' 'Eval'}; time],'Time');
xlswrite([saveExperimentDir '/' saveExperimentFile '.xlsx'],active_query_locations_mat,'Query Locations');

model_end_run_time = datestr(now);

precisions = reshape(permute(master_arrayOfmetric,[1 3 2]),[],(length(training_precisions)+2));
precision_avg = mean(master_arrayOfmetric(:,calc_precision_loc+2,:),3);
statistics = {model_id,model_start_run_time,model_end_run_time,run_time,splitNum};
weights = [bias; W];
