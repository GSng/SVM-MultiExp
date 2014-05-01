function [statistics accuracy weights scores] = liblinear_evaluate_model(workingdir, model_id, train_mat, test_mat, n_split, training_precisions, C, S, E, B)
                                                                     
model_start_run_time = datestr(now);

%Claim_mat format is: column 1 = claim_id; column 2=label; rest: features

test_claim_ids = test_mat(:,1);
real_test_labels = test_mat(:,2);
test_mat_features = test_mat(:,3:end); 
clear test_mat

train_claim_ids = train_mat(:,1);
real_train_labels = train_mat(:,2);
train_mat_features = train_mat(:,3:end); 
clear train_mat

mkdir([workingdir 'data/' num2str(model_id)]);

%% Run SVM
tic

%train a model
train_options = ['-s ' num2str(S) ' -c ' num2str(C) ' -e ' num2str(E)];
model = train(real_train_labels,train_mat_features,train_options);

%predict – decision_values is the predicted score
predict_options = ['-b ' num2str(B)];
[predicted_label accuracy test_scores] = predict(real_test_labels,test_mat_features,model,predict_options);

run_time = toc;
model_end_run_time = datestr(now);

%% Calculate Accuracy

accuracy = precision_calc(test_scores,real_test_labels,training_precisions);
statistics = {model_id,model_start_run_time,model_end_run_time,run_time,n_split,[]};
weights = model;
scores = full([test_claim_ids test_scores]);

