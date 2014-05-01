function [train_matrix train_ids activepool_matrix activepool_ids train_matrix_ids] = get_updated_train_matrices_svm(active_query_locations, train_matrix, train_ids, activepool_matrix, activepool_claim_ids, strategy,k)
%keyboard
if nargin<6
    strategem=0;
else
    strategem = strategy{1};
end



activepool_logical = false(size(activepool_matrix,1),1);
activepool_logical(active_query_locations) = true;

% get the claims from the matrix that are selected as the query claims
active_queries_matrix = activepool_matrix(activepool_logical,:); 
active_queries_id = activepool_claim_ids(activepool_logical,:); 

% merge these matrix & ids with the original Train matrix - to be returned
%MK - ACTIVE trial just keeping the active sample examples : didn't work
%TOO well as the weight vector is retrained to just fit the current sample
%train_matrix = [active_queries_matrix];
%train_ids=[active_queries_id];
switch strategem
    case -1
        train_matrix = active_queries_matrix;
        train_ids = active_queries_id;
        train_matrix_ids = train_ids;
    case 0
        train_matrix = [train_matrix; active_queries_matrix];
        train_ids = [train_ids; active_queries_id];
        train_matrix_ids = train_ids;
    otherwise        
        new_old_ratio = strategem;
        if nargin==7
            n = max(1,floor(size(train_matrix,1)*k*(new_old_ratio)/size(active_queries_matrix,1)));
        else
            n = max(1,floor(size(train_matrix,1)*(new_old_ratio)/size(active_queries_matrix,1)));
        end        
        train_matrix_ids = [train_ids; repmat(active_queries_id,n,1)];
        train_matrix = [train_matrix; repmat(active_queries_matrix,n,1)];
        train_ids = [train_ids; active_queries_id];        
end


% remove the active queries from the activepool
activepool_logical = true(size(activepool_matrix,1),1);
activepool_logical(active_query_locations) = false;

activepool_matrix = activepool_matrix(activepool_logical,:);
activepool_ids = activepool_claim_ids(activepool_logical,:);


