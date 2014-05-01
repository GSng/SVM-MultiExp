function run_clustering_predict_eob(conn,cluster_instance_id,workingdir)

cd E:\Projects\SVMpipeline\svm_run_multi_exp

if nargin < 3
    workingdir = 'E:/Projects/SVMpipeline/';
end

%% fetch data

% fetch parameters
setdbprefs('DataReturnFormat','numeric');
avg_entities_in_cluster = sql_query(conn,['SELECT DISTINCT avg_entities_in_cluster FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]);
model_statistic_id = sql_query(conn,['SELECT DISTINCT model_statistic_id FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]);
N_top_scored_claims = sql_query(conn,['SELECT DISTINCT N_top_scored_claims FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]);
N_top_eob_codes = sql_query(conn,['SELECT DISTINCT N_top_eob_codes FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]); 
N_nn = sql_query(conn,['SELECT DISTINCT N_nn FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]);

setdbprefs('DataReturnFormat','cellarray');
train_start_date = char(sql_query(conn,['SELECT DISTINCT train_start_date FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]));
train_end_date = char(sql_query(conn,['SELECT DISTINCT train_end_date FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]));
score_start_date = char(sql_query(conn,['SELECT DISTINCT score_start_date FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]));
score_end_date = char(sql_query(conn,['SELECT DISTINCT score_end_date FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]));
claim_selection_query = char(sql_query(conn,['SELECT DISTINCT claim_selection_query FROM cluster_instances WHERE id=' int2str(cluster_instance_id)]));

%determine label
model_id = sql_query(conn,['SELECT training_model_id FROM model_statistics WHERE id=' int2str(model_statistic_id)]);
label_type = char(svm_get_model_param(conn,model_id{1,1},'label_type',false));

if strcmpi(label_type,'is_not_underpay')
    label_type='is_overpay';
    label_type_fetch = 'is_rework';
elseif strcmpi(label_type,'is_not_overpay')
    label_type='is_underpay';
    label_type_fetch = 'is_rework';
else
    label_type_fetch = label_type;
end

% fetch labeled claims
query = ['SELECT DISTINCT claim_labels.claim_id FROM claim_labels JOIN ETL_CLAIM_HEADERS ON (ETL_CLAIM_HEADERS.claim_id = claim_labels.claim_id) WHERE ' label_type_fetch ' IS NOT NULL'];
if ~isempty(train_start_date)
    query = [query ' AND clm_paid_date>=''',train_start_date,''''];
end
if ~isempty(train_end_date)
    query = [query ' AND clm_paid_date<=''',train_end_date,''''];
end
setdbprefs('DataReturnFormat','numeric');
[labeled_claim_mat labeled_claim_ids] = svm_fetch_claim_level_matrix_scaled(conn,query,[],[],label_type);

% fetch unlabeled claims
query = ['SELECT DISTINCT TOP ' int2str(N_top_scored_claims) ' claim_id FROM (SELECT DISTINCT TOP 1000000 claim_scores.claim_id, claim_scores.score '...
         'FROM claim_scores JOIN ETL_CLAIM_HEADERS ON (ETL_CLAIM_HEADERS.claim_id = claim_scores.claim_id) '...
         'JOIN claims ON (claims.claim_id=claim_scores.claim_ID) '...
         'WHERE is_max_version=1 AND model_statistic_id=' int2str(model_statistic_id)... 
         ' AND claims.claim_id NOT IN(SELECT DISTINCT claim_id FROM claim_labels)'];
if ~isempty(train_start_date)
    query = [query ' AND clm_paid_date>=''',score_start_date,''''];
end
if ~isempty(train_end_date)
    query = [query ' AND clm_paid_date<=''',score_end_date,''''];
end     
query_unlabeled = [query ' ORDER BY SCORE DESC)dt'];    
if ~isempty(claim_selection_query) && ~strcmpi(claim_selection_query,'')
    query_unlabeled = claim_selection_query;
end

setdbprefs('DataReturnFormat','numeric');
[unlabeled_claim_mat unlabeled_claim_ids] = svm_fetch_claim_level_matrix_scaled(conn,query_unlabeled,[],[],label_type);

% calculated values
number_of_queries = size(unlabeled_claim_ids,1);
number_of_claims = number_of_queries+size(labeled_claim_ids,1);
moniker = ['CID' int2str(cluster_instance_id) '_MSID' int2str(model_statistic_id) '_' datestr(now,'yyyymmdd-HHMM')];

% fetch weight vector for model_stat_id
query = ['SELECT feature_id,weight FROM feature_training_model_weights WHERE model_statistic_id=',int2str(model_statistic_id),' ORDER BY feature_id ASC'];
setdbprefs('DataReturnFormat','numeric');
feature_weights = sql_query(conn,query);

%% calculate scores if empty
if isempty(unlabeled_claim_ids)
	FLAG = input('Please enter value for which ''flag'' column in ''claims'' you desire to use: ','s');
    FLAG = ['flag' FLAG];
    
    whereclause = ['WHERE ' FLAG ' IS NOT NULL'];
    setdbprefs('NullNumberWrite','NaN');
    update(conn,'claims',{FLAG},{'NaN'},whereclause);
    
    whereclause = ['WHERE claim_id IN (SELECT claims.claim_id FROM claims JOIN ETL_claim_headers '...
                   'ON (claims.claim_id=ETL_claim_headers.claim_id) '...
                   'WHERE clm_paid_date>=''' score_start_date ''' AND clm_paid_date<=''' score_end_date ''' '...
                   'EXCEPT (SELECT claim_id FROM claim_labels))'];
    updatevalue = ['unclassified_model_' int2str(model_statistic_id)];
    update(conn,'claims',{FLAG},{updatevalue},whereclause);
    n_claims_to_be_scored = sql_query(conn,['SELECT COUNT(DISTINCT claim_id) FROM claims WHERE ' FLAG '=''' updatevalue '''']);
    
    query = ['SELECT feature_id,weight FROM feature_training_model_weights WHERE model_statistic_id=',int2str(model_statistic_id),' ORDER BY feature_id ASC'];
    setdbprefs('DataReturnFormat','numeric');
    feature_weights = sql_query(conn,query);
    
    start_condition = updatevalue;
    end_condition = ['classified_model_' int2str(model_statistic_id)];
    for i=1:ceil(n_claims_to_be_scored/150000);
        svm_classify_claims_with_training_model_statistics(conn,model_statistic_id,FLAG,start_condition,end_condition,feature_weights);
        disp([int2str(i*150000) ' claims scored'])
    end
    
    setdbprefs('DataReturnFormat','numeric');
    [unlabeled_claim_mat unlabeled_claim_ids] = svm_fetch_claim_level_matrix_scaled(conn,query_unlabeled,[],[],label_type);
    number_of_queries = size(unlabeled_claim_ids,1);
    clear start_condition end_condition update_value where_clause FLAG query_unlabeled
end

clear score_end_date score_start_date train_end_date train_start_date query
%% create and write files
if (~isempty(avg_entities_in_cluster) && avg_entities_in_cluster~=0) || (~isempty(N_nn) && N_nn~=0)
    % merge unlabeled and labeled matrices
    w_labeled   = size(labeled_claim_mat,2);
    w_unlabeled = size(unlabeled_claim_mat,2); 
    if w_labeled<w_unlabeled
        claim_mat = [unlabeled_claim_mat;labeled_claim_mat zeros(size(labeled_claim_mat,1),(w_unlabeled-w_labeled))];
    elseif w_labeled>w_unlabeled
        claim_mat = [unlabeled_claim_mat zeros(size(unlabeled_claim_mat,1),(w_labeled-w_unlabeled));labeled_claim_mat];
    else    
        claim_mat = [unlabeled_claim_mat;labeled_claim_mat];
    end
    claim_level_claim_ids = [unlabeled_claim_ids;labeled_claim_ids];
    clear claim_mat_unlabeled claim_mat_labeled unlabeled_claim_ids labeled_claim_ids w_labeled w_unlabeled

    % shrink claim_mat to accomodate weight_vector
    matrix = claim_mat(:,2:end);
    [feature_vec_for_mat feature_vec_i] = intersect(feature_weights(:,1),[1:1:size(matrix,2)]);
    claim_mat_new = [claim_mat(:,1) matrix(:,feature_vec_for_mat)]; 
    clear matrix claim_mat;

    % write files
    cluster_input_file = [workingdir 'data/cluster_' int2str(cluster_instance_id)];
    mkdir(cluster_input_file);
    cluster_input_file = [cluster_input_file '/' moniker '.mat'];
    cluto_write_file = mat_sparse_2_svm_sparse(claim_mat_new,cluster_input_file,0,0,[],0,1);
end

%% run clustering
if ~isempty(avg_entities_in_cluster) && avg_entities_in_cluster~=0
    number_of_clusters = floor(number_of_queries/avg_entities_in_cluster);
    [cluster_ids cluster_summary_mat] = cluto_run_clustering(cluto_write_file,number_of_clusters);

    % insert results into DB
    cluster_summary_mat = [repmat(cluster_instance_id,size(cluster_summary_mat,1),1) cluster_summary_mat];
    fastinsert(conn,'cluster_details',{'cluster_instance_id','cluster_id','size','ISim','ISdev','ESim','ESdev'},cluster_summary_mat);

    setdbprefs('DataReturnFormat','numeric');
    cluster_details = sql_query(conn,['select id,cluster_id from cluster_details where cluster_instance_id = ' num2str(cluster_instance_id)]);

    [tf loc] = ismember(cluster_ids,cluster_details(:,2));
    claim_ids_with_cluster_ids=[claim_level_claim_ids cluster_details(loc,1) cluster_ids];
    
    fastinsert(conn,'claim_cluster_details',{'claim_id','cluster_detail_id','cluster_id'},claim_ids_with_cluster_ids)
    runstoredprocedure(conn,'UPDATE_CLUSTER_DETAIL_STATS')
end

%% Predict EOBs
if ~isempty(N_nn) && N_nn~=0
    % run nearest neighbor
    nn_mat = nn_run_knn(cluto_write_file,N_nn,number_of_queries,(size(claim_mat_new,1)));
    nn_mat_claim_ids=full([claim_level_claim_ids(1:number_of_queries) nn_mat]); clear nn_mat;
    
    %fetch EOB
    query = 'SELECT DISTINCT ETL_claims.claim_id,[CLCL_EOB_EXCD_ID] FROM mk_final_labels JOIN ETL_claims ON ETL_claims.raw_claim_id=mk_final_labels.CLCL_ID WHERE is_rework IS NOT NULL ORDER BY claim_id';
    setdbprefs('DataReturnFormat','cellarray');
    claim_id_eob_code = sql_query(conn,query);
    
    %fetch unique EOBs from UI_adjustment_reasons
    query = 'SELECT DISTINCT id, eob FROM UI_adjustment_reasons WHERE id>=1960';
    setdbprefs('DataReturnFormat','cellarray');
    ui_id_eob_code = sql_query(conn,query);    
    
    %index EOB codes with ui_id_eob_code ID
    %eob_code_uniq_ids = unique(claim_id_eob_code(:,2));
    [tf loc] = ismember(claim_id_eob_code(:,2),ui_id_eob_code(:,2));  
    claim_id_eob_code_num = [cell2mat(claim_id_eob_code(:,1)) cell2mat(ui_id_eob_code(loc,1))]; % claim_id EOB

    %toggle matrices
    correct_count = 0;
    k = N_top_eob_codes;
    claim_id_topk_eob_codes = cell(size(nn_mat_claim_ids,1),3);
    claim_top_nn_eob_code_counts = zeros(number_of_queries,length(unique(loc)));
    nearest_neighbours = nn_mat_claim_ids(:,(3:2:size(nn_mat_claim_ids,2)));
    claim_id_code_db_insert = zeros(0,3);

%Future optimizations
%     flat_nearest_neighbors = nearest_neighbours';
%     flat_nearest_neighbors = flat_nearest_neighbors(:);    
%     [tf_eobCode_flat loc_eobCode_flat] = ismember(flat_nearest_neighbors,claim_id_eob_code_num(:,1));
%     loc_eobCode_mat = reshape(loc_eobCode_flat,size(nearest_neighbours,1),size(nearest_neighbours,2));
    
    %determine predicted EOBs
    for row=1:size(nn_mat_claim_ids,1)

        tf_eobCode = ismember(claim_id_eob_code_num(:,1),claim_level_claim_ids(nearest_neighbours(row,:)));

        %relevant codes are: claim_id_eob_code_num(tf_eobCode,2)
        sort_claim_id_eob_code_num = sort(claim_id_eob_code_num(tf_eobCode,2));
        [bl  il] = unique(sort_claim_id_eob_code_num,'first');
        [bl il2] = unique(sort_claim_id_eob_code_num,'last');
        count_codes = il2-il+1;

        claim_top_nn_eob_code_counts(row,bl)=count_codes;
        [sorted_val sorted_index]=sort(count_codes,'descend');

        if(k<size(sorted_index,1))
            top_k = k;
        else
            top_k = size(sorted_index,1);
        end
        top_k_nearest_neighbours = bl(sorted_index(1:top_k)); %top k index
        top_k_nearest_neighbours_score = count_codes(sorted_index(1:top_k))/100; %top k scores   
               
        claim_id_code_db_insert = [claim_id_code_db_insert; repmat(nn_mat_claim_ids(row,1),top_k,1) top_k_nearest_neighbours top_k_nearest_neighbours_score];

        %         claim_id_topk_eob_codes{row,1} = nn_mat_claim_ids(row,1);
%         claim_id_topk_eob_codes{row,2} = top_k_nearest_neighbours;
%         claim_id_topk_eob_codes{row,3} = top_k_nearest_neighbours_score;        
%         [tf loc] = ismember(claim_id_eob_code_num(row,2),top_k_nearest_neighbours);
%         if(tf)
%             correct_count=correct_count+1;
%         end
        clear tf_eobCode bl il il2 sort_claim_id_eob_code_num top_k_nearest_neighbours_score top_k_nearest_neighbours top_k sorted_val sorted_index claim_top_nn_eob_code_counts count_codes
    end
    
    %insert into database
    save([workingdir 'data/cluster_' int2str(cluster_instance_id) '/eobinsert.mat'],'claim_id_code_db_insert');
    claim_id_code_db_insert = [claim_id_code_db_insert repmat(cluster_instance_id,size(claim_id_code_db_insert,1),1)];
    for k=1:ceil(length(claim_id_code_db_insert)/20000)
        if k<ceil(length(claim_id_code_db_insert)/20000)
            end_i = k*20000;
        else
            end_i = length(claim_id_code_db_insert);
        end
        fastinsert(conn,'UI_claim_adjustment_reasons',{'claim_id','reason_id','score','cluster_instance_id'},claim_id_code_db_insert((1+(k-1)*10000):end_i,:));    
    end    
end
