function claim_id_score_mat = svm_classify_claims_with_training_model_statistics(conn,model_statistic_id,flag,start_condition,end_condition,feature_weights)

disp 'Classification run start'
model_level = 'claim';

%Fetch Claim Features for defined population
[claim_level_matrix claim_level_claim_ids] = svm_fetch_claim_level_training_matrix_scaled(conn,'classify',flag,start_condition);

%load weights
if nargin<6
    query = ['SELECT feature_id,weight FROM feature_training_model_weights WHERE model_statistic_id=',int2str(model_statistic_id),' ORDER BY feature_id ASC'];
    setdbprefs('DataReturnFormat','numeric');
    feature_weights = sql_query(conn,query);
end

if nargin<7
    setdbprefs('DataReturnFormat','numeric');
    model_id = sql_query(conn,['select training_model_id from model_statistics where id = ' num2str(model_statistic_id)]);
    model_level = svm_get_model_param(conn,model_id,'model_level');
end

if feature_weights(1,1)==0
    b = feature_weights(1,2);
    feature_vec = feature_weights(2:end,1);
    weights = feature_weights(2:end,2);
else
    b = 0;
    feature_vec = feature_weights(:,1);
    weights = feature_weights(:,2);
end

if strcmp(model_level,'claim')
    matrix = claim_level_matrix(:,2:end);
else
    matrix = line_level_matrix(:,2:end);
end

% max_feature = max(feature_vec);
% if size(matrix,2) < max_feature
%     matrix(1,max_feature)=0;
% elseif size(matrix,2) > max_feature
%     matrix = matrix(:,1:max_feature);
% end

[feature_vec_for_mat feature_vec_i] = intersect(feature_vec,[1:1:size(matrix,2)]);
feature_vec_i=feature_vec_i';
matrix = matrix(:,feature_vec_for_mat);
t_claim_score =  matrix*weights(feature_vec_i)+b;

%insert the score into the table
claim_id_score_mat = [claim_level_claim_ids t_claim_score];
n_t_claim = size(claim_id_score_mat,1);
disp(['Inserting claim score into claim_scores with model_statistic_id: ' num2str(model_statistic_id) ' for ' num2str(n_t_claim) ' claims..']);
insert(conn,'claim_scores',{'claim_id','score','model_statistic_id'},[claim_id_score_mat repmat(model_statistic_id,n_t_claim,1)]);
disp 'Insertion Complete'

disp 'Updating claim status_cd...'
query = ['UPDATE CLAIMS SET ' flag '  = ''' end_condition ''' WHERE CLAIM_ID in (select top 150000 claim_id from claims where claims.' flag ' = ''' start_condition ''' order by claim_id) '];
exec(conn,query);
disp 'Update complete.'





