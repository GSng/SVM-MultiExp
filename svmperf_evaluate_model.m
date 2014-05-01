function [statistics accuracy weights scores W_] = svmperf_evaluate_model(workingdir, model_id, train_file, test_file, test_mat, n_split, training_precisions,...
                                                                          C, E, L, W, T, DGSR)
W_=[];

model_start_run_time = now;

test_mat_temp = test_mat; clear test_mat
test_claim_ids = test_mat_temp(:,1);
real_test_labels = test_mat_temp(:,2);
test_mat = test_mat_temp(:,3:end); clear test_mat_temp

model_file_name = [workingdir 'data/split' num2str(n_split) '_model_' num2str(model_id) '.model'];


%% Run SVM
tic

svm_perf_run_training(workingdir, train_file, model_file, C, E, L, W, T, DGSR)

w = zeros(size(test_mat,2),1);
if T==0
    feature_score_mat = svm_read_model_file(model_file_name);               
    w(feature_score_mat(:,1)) = feature_score_mat(:,2);                
    test_scores = test_mat*w;
else
    result_file = [workingdir 'data/split' num2str(n_split) '_result_' num2str(model_id) '.result'];
    eval(['!E:/Users/Gaurav/IBC/shared_functions/svm_perf_classify.exe ' test_file ' ' model_file ' ' result_file]);
    test_scores = textread(result_file);
end

run_time = toc;
model_end_run_time = datestr(now);

%% Calculate Accuracy

accuracy = precision_calc(test_scores,real_test_labels,training_precisions);
statistics = {model_id,datestr(model_start_run_time),datestr(model_end_run_time),run_time,n_split};
weights = w;
scores = full([test_claim_ids test_scores]);