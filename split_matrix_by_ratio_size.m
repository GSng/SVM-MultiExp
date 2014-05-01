function [ID_MAT INDEX_MAT] = split_matrix_by_ratio_size(claim_mat,rework_ratio,desired_matrix_size)
%% randomize matrix
ploc_claim_mat = find(claim_mat(:,2)==1);
nloc_claim_mat = find(claim_mat(:,2)==-1);

claim_positive_loc = randperm(length(ploc_claim_mat));
claim_negative_loc = randperm(length(nloc_claim_mat));

ploc_claim_mat = ploc_claim_mat(claim_positive_loc);
nloc_claim_mat = nloc_claim_mat(claim_negative_loc);

pos_mat_ID = claim_mat(ploc_claim_mat,1);
neg_mat_ID = claim_mat(nloc_claim_mat,1); 

%% Calculate Number of pos/neg, matrix size
n_claims_pos = length(ploc_claim_mat);
n_claims_neg = length(nloc_claim_mat);

percent_pos = rework_ratio;
percent_neg = (1-rework_ratio);

pos_neg_actual_ratio = n_claims_pos/n_claims_neg;
pos_neg_sample_ratio = percent_pos/percent_neg;

if nargin<3 || desired_matrix_size==0 || isempty(desired_matrix_size)
    if pos_neg_actual_ratio >= pos_neg_sample_ratio
        n_negative = n_claims_neg;
        n_positive = n_negative*percent_pos/percent_neg;
    elseif pos_neg_actual_ratio < pos_neg_sample_ratio
        n_positive = n_claims_pos;
        n_negative = n_positive*percent_neg/percent_pos;
    end
    desired_matrix_size = n_negative+n_positive;
end

%% create matrices
if pos_neg_actual_ratio > pos_neg_sample_ratio

    n_negative = floor(desired_matrix_size*percent_neg);
    n_positive = floor(n_negative*percent_pos/percent_neg);
    num_of_matrices=floor(n_claims_pos/n_positive);
    
    for(i=1:num_of_matrices)
        start_ind = ((i-1)*n_positive)+1;
        end_ind = i*n_positive;
                
        r = randperm(n_claims_neg);
        r = r(randperm(n_negative));
        
        ID_MAT(:,i) = [pos_mat_ID(start_ind:end_ind,:); neg_mat_ID(r,:)];
        INDEX_MAT(:,i) = [ploc_claim_mat(start_ind:end_ind,:); nloc_claim_mat(r,:)];
    end
    
elseif pos_neg_actual_ratio < pos_neg_sample_ratio

    n_positive = floor(desired_matrix_size*percent_pos);
    n_negative = floor(n_positive*percent_neg/percent_pos);   
    num_of_matrices=floor(n_claims_neg/n_negative);
    
    for(i=1:num_of_matrices)
        start_ind = ((i-1)*n_negative)+1;
        end_ind = i*n_negative;
        
        r = randperm(n_claims_pos);
        r = r(randperm(n_positive));
                
        ID_MAT(:,i) = [pos_mat_ID(r,:);neg_mat_ID(start_ind:end_ind,:)];
        INDEX_MAT(:,i) = [ploc_claim_mat(r,:);nloc_claim_mat(start_ind:end_ind,:)];
    end
        
end
