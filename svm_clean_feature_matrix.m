function [new_feature_matrix col_delete_vec row_delete_vec] = svm_clean_feature_matrix(feature_matrix,active_features,frequency_threshold,no_output_flag)

if isscalar(active_features) && ~isscalar(frequency_threshold)
    conn = feature_matrix; clear feature_matrix
    model_id = active_features; clear active_features
    feature_matrix = frequency_threshold; clear frequency_threshold
    active_features = svm_get_active_features(conn,0,model_id);
    frequency_threshold = svm_get_model_param(conn,model_id,'feature_min_frequency_threshold',true);
end

if isempty(active_features)
    n_active_features = size(feature_matrix,2);
else
    n_active_features = length(active_features);
end

if nargin<4
    active_features = active_features+2;
end

%initialize delete_cols
delete_cols = [];
n_features_in_matrix = size(feature_matrix,2);
cols = [1:n_features_in_matrix];

if n_active_features < n_features_in_matrix
    delete_cols = setdiff(cols,active_features)';
    %feature_matrix(:,delete_cols) = zeros(size(feature_matrix,1),size(delete_cols,1));
end

[R C V] = find(feature_matrix);

%check the frequency requirements
if nargin >2
    feature_frequency_count = sum(sparse(R,C,1),1); 
    %check how experiments were running beforehand, theorized code: below_freq_cols =find(find(feature_frequency_count>frequency_threshold))';
    below_freq_cols = find(feature_frequency_count<frequency_threshold)';    
    delete_cols = union(delete_cols,below_freq_cols)';
end

col_delete_vec = zeros(n_features_in_matrix,1);
col_delete_vec(delete_cols) = 1;   
col_delete_vec = logical(col_delete_vec);

row_delete_vec = zeros(size(feature_matrix,1),1);
clear feature_matrix;

loc = logical(~ismember(C,cols(col_delete_vec')));
new_feature_matrix = spconvert([R(loc) C(loc) V(loc); (max(R)+1) length(col_delete_vec) 0]);
row_delete_loc = find(sum(new_feature_matrix(1:(end-1),2:end),2)==0);
row_delete_vec(row_delete_loc) = 1;

%correct for ALL instances-->in the advent that rows are deleted, this will
%fail as there does not exist a match on claim_id
if nargin<4

%     V(find(ismember(C,find(delete_vec)))) = 0;
%     new_feature_matrix = spconvert([R C V]);
%     row_delete_vec = find(sum(new_feature_matrix(2:end),2)==0);
    new_feature_matrix = new_feature_matrix(find(sum(new_feature_matrix(:,2:end),2)>0),:);
else
    new_feature_matrix = 0;
end




