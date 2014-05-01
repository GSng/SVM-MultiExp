function [scores precisions] = svm_compute_scores(test_matrix,models,training_precisions,test_claim_ids)

if nargin==4
    real_test_labels = test_matrix(:,1);
    matrix = test_matrix(:,2:end);
else
    test_claim_ids = test_matrix(:,1);
    real_test_labels = test_matrix(:,2);
    matrix = test_matrix(:,3:end);
end

col_matrix = [1:1:size(matrix,2)];
n=size(models,2);
precisions = cell(n,1);
scores = cell(n,1);

parfor i = 1:n
    
    feature_weights = models{i};
    
    if feature_weights(1,1)==0
        b = feature_weights(1,2);
        feature_vec = feature_weights(2:end,1);
        weights = feature_weights(2:end,2);
    else
        b = 0;
        feature_vec = feature_weights(:,1);
        weights = feature_weights(:,2);
    end

    [feature_vec_for_mat feature_vec_i] = intersect(feature_vec,col_matrix);
    feature_vec_i=feature_vec_i';
    matrix_test = matrix(:,feature_vec_for_mat);
    test_scores =  matrix_test*weights(feature_vec_i)+b;
    
    precisions{i} = precision_calc(test_scores,real_test_labels,training_precisions);
    scores{i} = full([test_claim_ids test_scores]);
end