function [filename c_key] = svm_condense_and_write_matrix(feature_matrix_w_claim_ids,active_features,frequency_threshold,model_id,n_split)
   
[R_tr C_tr V_tr] = find(feature_matrix_w_claim_ids);

[jk delete_vec] = svm_clean_feature_matrix(feature_matrix_w_claim_ids(:,3:end),active_features,frequency_threshold,true);    
delete_vec = find(delete_vec)+2;

clear feature_matrix_w_claim_ids

loc_tr = logical(~ismember(C_tr,delete_vec));    
C_tr_adjusted = C_tr(loc_tr);

c_key = unique(C_tr_adjusted);
n_cols = length(c_key);
new_c_key = [1:n_cols]';
feature_index = c_key(3:end)-2;

[new_loc_tr ind_loc_tr] = ismember(C_tr_adjusted,c_key);        

new_mat = spconvert([R_tr(loc_tr) new_c_key(ind_loc_tr) V_tr(loc_tr); (max(R_tr)+1) n_cols 0]);
new_mat = new_mat(find(sum(new_mat(:,3:end),2)>0),:);      

mkdir([workingdir 'data/' num2str(model_id)]);
filename = [workingdir 'data/' num2str(model_id) '/split' num2str(n_split) '_train' num2str(n) '_' datestr(now,'HHMMSS-mmddyy') '.train_data'];

fopen(filename,'w+');

mat_sparse_2_svm_sparse(new_mat(:,2:end),filename,false,true,new_mat(:,1));