function [statistics accuracy weights scores] = svm_create_test_run_exp(model_ids,SVM_parameters,train_files,test_set_mat,c_key,n_split,training_precisions,workingdir) 

n = length(model_ids);

statistics = cell(1,n);
accuracy = cell(1,n);
weights = cell(1,n);
scores = cell(1,n);
W = cell(1,n);

[R_ts C_ts V_ts] = find(test_set_mat);

parfor i=1:n
    
    loc_ts = logical(ismember(C_ts,c_key{i}));
    
    C_ts_adjusted = C_ts(loc_ts);
    
    n_cols = length(c_key{i});
    new_c_key = [1:n_cols]';
    feature_index = c_key(3:end)-2;
            
    [new_loc_ts ind_loc_ts] = ismember(C_ts_adjusted,c_key{i});
        
    test_mat = spconvert([R_ts(loc_ts) new_c_key(ind_loc_ts) V_ts(loc_ts); (max(R_ts)+1) n_cols 0]);
    test_mat = test_mat(find(sum(test_mat(:,3:end),2)>0),:); 
    
    mkdir([workingdir 'data/' num2str(model_id)]);
    test_file =  [workingdir 'data/' num2str(model_id) '/split' num2str(n_split) '_test'  num2str(n) '_' datestr(now,'HHMMSS-mmddyy') '.test_data'];
    
    train_file = train_files{i};
    
    a = cell(1,5);
    b = zeros(size(training_precisions,1),1);
    c = zeros(size(test_mat,2)-1,1);
    d = zeros(size(test_mat,1),1);
    
    try
        switch SVM_parameters{i,6}
            case 'SOFIA'
                [a b c d] = sofia_evaluate_model(workingdir,model_ids(i),train_file,test_mat,n_split,training_precisions,...
                                                   SVM_parameters{i,1},SVM_parameters{i,2},SVM_parameters{i,3},SVM_parameters{i,4},SVM_parameters{i,5});
                weights{i} = [[0;feature_index] c];
            case 'SGSVM'
                [a b c d] = sgsvm_evaluate_model(model_ids(i),train_mat,test_mat,n_split,training_precisions,...
                                                   SVM_parameters{i,1},SVM_parameters{i,3},SVM_parameters{i,2},SVM_parameters{i,4},SVM_parameters{i,5});
                weights{i} = [feature_index c];
            case 'SVM PERF'                    
                fopen(test_file,'w+');
                fclose('all');
                mat_sparse_2_svm_sparse(test_mat(:,2:end),test_file,false,true,test_mat(:,1));
                
                [a b c d] = svmperf_evaluate_model(workingdir,model_ids(i),train_file,test_file,test_mat,n_split,training_precisions,...
                                                     SVM_parameters{i,1},SVM_parameters{i,3},SVM_parameters{i,2},SVM_parameters{i,4},SVM_parameters{i,5},cell2mat(SVM_parameters(i,9:10)));
                weights{i} = [feature_index c];
        end
        
    catch MException
          MException.message
          for s=1:size(MException.stack)
              MException.stack(s,1)
          end
          matlabpool close
    end
    
    statistics{i} = a;
    accuracy{i} = b;
    scores{i} = d;

end


