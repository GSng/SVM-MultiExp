function calculate_nn_and_save(conn)

[claim_mat_labelled claim_mat_claim_ids_labelled] = svm_fetch_claim_level_training_matrix_scaled(conn,'train');
claim_mat_labelled=[claim_mat_claim_ids_labelled claim_mat_labelled];

%query_for_1_day_scored_claims=['select distinct claim_id from ETL_claim_headers where clm_receive_date=''2010-02-25'''];
%MKquery_for_1_day_scored_claims=['SELECT claim_id FROM claims WHERE raw_claim_no IN (SELECT distinct CLCL_ID FROM [rework_wlp].[dbo].[AMSPRD_CLM_HDR] WHERE CLCL_RECD_DT=''2010-02-25'') EXCEPT(SELECT claim_id FROM claim_labels)'];
query_for_1_day_scored_claims=['select top 100 claims.claim_id from claim_scores join claims on claims.claim_id=claim_scores.claim_id where model_statistic_id=70 and claims.flag1 is not null order by score desc'];


[claim_mat_query claim_mat_claim_ids_query]=svm_fetch_claim_level_matrix_scaled(conn,query_for_1_day_scored_claims);
claim_mat_query=[claim_mat_claim_ids_query claim_mat_query];
n_number_of_queries=size(claim_mat_query,1);

if(size(claim_mat_query,2)>size(claim_mat_labelled,2))
    claim_mat_labelled(1,size(claim_mat_query,2))=0; % to extend the smaller sparse matrix to be equal to the larger sparse matrix
elseif (size(claim_mat_query,2)<size(claim_mat_labelled,2))
    claim_mat_query(1,size(claim_mat_labelled,2))=0;
end
    
claim_mat=[claim_mat_query;claim_mat_labelled]; % merge the query claims & the labelled claims

active_features = svm_get_active_features(conn,0,12);
%set the none active features to zero
frequency_threshold=0;
%MKclaim_mat_feats=svm_clean_feature_matrix_proposed_mk(claim_mat(:,3:end),active_features,frequency_threshold);
%claim_mat_feats=svm_clean_feature_matrix(claim_mat(:,3:end),active_features,frequency_threshold);
%claim_mat=[claim_mat(:,1:2) claim_mat_feats];
claim_mat=svm_clean_feature_matrix(claim_mat,active_features,frequency_threshold); %% V IMP note: by sending in 3 params we are forcing the function to expect a full claim matrix with claim ids & labels

% 
% 
% file_cluto_claim_mat_pfx='wlp_claim_mat_1_day_top100'; % actual filename will be file_cluto_claim_mat'.cluto'
% mat_sparse_2_svm_sparse_mk(claim_mat,file_cluto_claim_mat_pfx,0,0,[],0,1);
% 
% k=100;
% n=size(claim_mat,1);
% file_cluto_claim_mat=[file_cluto_claim_mat_pfx '.cluto'];
% file_nn=[file_cluto_claim_mat_pfx '_nn_k' num2str(k) '.csv'];
% %% run nearest neighbour
% %MK wlp-day1eval_str=['nn.exe in ' file_cluto_claim_mat ' num_rows ' num2str(n) ' out ' file_nn ' n ' num2str(n) ' k ' num2str(k)];
eval_str=['!nn_final.exe in ' file_cluto_claim_mat ' num_rows ' num2str(n) ' out ' file_nn ' n ' num2str(n_number_of_queries) ' k ' num2str(k) ' strictQuery 1'];
eval(eval_str);

nn_mat=csvread(file_nn,1,0); % reads te neareset neighbour matrix with format
%point_num,1_index,1_dist,2_index,2_dist,3_index,3_dist
%append claim ids
%MKnn_mat_claim_ids=[claim_mat_claim_ids nn_mat];
nn_mat_claim_ids=full([claim_mat_query(:,1) nn_mat]);

query = 'select distinct claim_id,[CLCL_EOB_EXCD_ID] from mk_final_labels join ETL_claims on ETL_claims.raw_claim_id=mk_final_labels.CLCL_ID where is_rework is not null order by claim_id';
setdbprefs('DataReturnFormat','cellarray');
claim_id_eob_code = sql_query(conn,query);

eob_code_uniq_ids=unique(claim_id_eob_code(:,2));

[tf loc]=ismember(claim_id_eob_code(:,2),eob_code_uniq_ids);
claim_id_eob_code_num=[cell2mat(claim_id_eob_code(:,1)) loc]; % claim_id EOB

%[tf loc]=ismember(claim_mat(:,1),cell2num(claim_id_eob_code(:,1)));
claim_top_nn_eob_code_counts=zeros(size(claim_mat_query,1), size(eob_code_uniq_ids,1));

correct_count=0;
k=3; % consider top k reasons to match
claim_id_topk_eob_codes=cell(size(nn_mat_claim_ids,1),1);
col=3:2:size(nn_mat_claim_ids,2);
for row=1:size(nn_mat_claim_ids,1)
    nearest_neighbours=nn_mat_claim_ids(row,col);
    
    [tf_eobCode loc_eobCode]=ismember(claim_id_eob_code_num(:,1),claim_mat(nearest_neighbours,1));
    
    %relevant codes are: claim_id_eob_code_num(tf_eobCode,2)
    [bl il]=unique(sort(claim_id_eob_code_num(tf_eobCode,2)),'first');
    [bl il2]=unique(sort(claim_id_eob_code_num(tf_eobCode,2)),'last');
    count_codes=il2-il+1;
    
    claim_top_nn_eob_code_counts(row,bl)=count_codes;
    
    
    [sorted_val sorted_index]=sort(count_codes,'descend');
    
    if(k<size(sorted_index,1))
        top_k=k;
    else
        top_k=size(sorted_index,1);
    end
    top_k_nearest_neighbours=bl(sorted_index(1:top_k)); %top k index
    top_k_nearest_neighbours_score=count_codes(sorted_index(1:top_k))/100; %top k scores
    
    %claim_id_topk_eob_codes(row)=struct('claim_id',nn_mat_claim_ids(row,1),'eob_code',top_k_nearest_neighbours,'score',top_k_nearest_neighbours_score);
%     [tf loc]=ismember(claim_id_eob_code_num(row,2),top_k_nearest_neighbours);
%     if(tf)
%         correct_count=correct_count+1;
%     end
end

% percentage_correct=correct_count/size(nn_mat_claim_ids,1)

save('nearest_neighbours_day_1_top100');



