function svm_score_claims_on_model(conn,query,model_statistic_id,claim_mat)

if ~isempty(query)
    [claim_mat claim_ids] = svm_fetch_claim_level_matrix_scaled(conn,query);
elseif ~isempty(claim_mat)
    claim_ids = claim_mat(:,1);
    claim_mat_features = claim_mat(:,2:end);
end

%load weights
query = ['SELECT feature_id,weight FROM feature_training_model_weights WHERE model_statistic_id=',int2str(model_statistic_id),' ORDER BY feature_id ASC'];
setdbprefs('DataReturnFormat','numeric');
feature_weights = sql_query(conn,query);

if feature_weights(1,1)==0
    bias = feature_weights(1,2);
    features = feature_weights(2:end,1);
    weights = feature_weights(2:end,2);
else
    bias=0;
    features = feature_weights(:,1);
    weights = feature_weights(:,2);
end





test_scores = test_mat*W+bias;


run_time = toc;
model_end_run_time = datestr(now);

%% Calculate Accuracy

accuracy = precision_calc(test_scores,real_test_labels,training_precisions);
statistics = {model_id,model_start_run_time,model_end_run_time,run_time,n_split};
weights = [bias; W];
scores = full([test_claim_ids test_scores]);


%condition = ' status_cd is null ';
condition = 'claim_type = ''classified''';
%condition = ' status_cd is null and fdos>''2008-01-01''';

while 1
    if isempty(classfication_model_id)
        claim_id_score_mat=svm_perf_classify_claims_with_training_model_statistics(conn,model_statistic_id,flag,start_condition,end_condition);
    else
        svm_classify_claims_with_multiple_models(conn,classfication_model_id,condition)
    end
end