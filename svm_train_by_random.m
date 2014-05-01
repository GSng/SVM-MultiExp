function [statistics accuracy weights scores W] = svm_train_by_random(conn,model_ids,training_precisions,...
                                                                      data_param_mat,model_param_mat,...
                                                                      claim_mat,test_sp_case,train_sp_case,workingdir)
%% Initialize Variables

n = length(model_ids);

n_iterations = data_param_mat(1);
train_fraction = data_param_mat(2);
sample_percent = data_param_mat(3);
test_rework_ratio = data_param_mat(4);
train_rework_ratio = data_param_mat(5);

SVM_parameters = [model_param_mat(:,1:5) model_param_mat(:,8:10)];
frequency_threshold = cell2mat(model_param_mat(:,6));
active_features = model_param_mat(:,7);

%% Seperate negative and positive samples

if nargin>5 && ~isempty(train_sp_case)
    ploc_train_sp_case = find(train_sp_case(:,2)==1);
    nloc_train_sp_case = find(train_sp_case(:,2)==-1);
else
    train_sp_case = sparse(zeros(0,size(claim_mat,2)));
    ploc_train_sp_case = []; 
    nloc_train_sp_case = [];
end

ploc_claim_mat = find(claim_mat(:,2)==1);
nloc_claim_mat = find(claim_mat(:,2)==-1);

if nargin>4 && ~isempty(test_sp_case)
    ploc_test_sp_case = find(test_sp_case(:,2)==1); 
    nloc_test_sp_case = find(test_sp_case(:,2)==-1);
else
    test_sp_case = sparse(zeros(0,size(claim_mat,2)));
    ploc_test_sp_case = []; 
    nloc_test_sp_case = [];
end

ncol_train_sp_case = size(train_sp_case,2);
ncol_claim_mat = size(claim_mat,2);
ncol_test_sp_case = size(test_sp_case,2);
n_col = max([ncol_train_sp_case ncol_claim_mat ncol_test_sp_case]);

if ncol_train_sp_case<n_col
    train_sp_case = padarray(train_sp_case,[0 (n_col-ncol_train_sp_case)],0,'post');
end
if ncol_claim_mat<n_col
    claim_mat = padarray(claim_mat,[0 (n_col-ncol_claim_mat)],0,'post');
end
if ncol_test_sp_case<n_col
    test_sp_case = padarray(test_sp_case,[0 (n_col-ncol_test_sp_case)],0,'post');
end

n_claims = size(claim_mat,1)+size(train_sp_case,1)+size(test_sp_case,1);
n_claims_pos = length(ploc_claim_mat)+length(ploc_test_sp_case)+length(ploc_train_sp_case);
n_claims_neg = length(nloc_claim_mat)+length(nloc_test_sp_case)+length(nloc_train_sp_case);

clear ncol_test_sp_case ncol_claim_mat ncol_train_sp_case n_col
%% Calculate size of test and train matrices

if train_fraction==-1
    if n_claims_pos<n_claims_neg
        test_rework_ratio = 0;
    else
        test_rework_ratio = 1;
    end
    train_fraction = 1;
end

if n_claims_pos<n_claims_neg
    max_train_fraction=abs((((n_claims_pos/n_claims)-test_rework_ratio)/(train_rework_ratio-test_rework_ratio)));
else
    max_train_fraction=abs(((n_claims_neg/n_claims)+test_rework_ratio-1)/(test_rework_ratio-train_rework_ratio));
end

status='Running';
update_train_flag=0;
if train_fraction>max_train_fraction
    train_fraction=max_train_fraction;
    status = ['Train Fraction updated to ' num2str(max_train_fraction)];
    update_train_flag = 1;
end

percent_train_pos = train_fraction*train_rework_ratio;
percent_test_pos = (1-train_fraction)*test_rework_ratio;
percent_pos = percent_train_pos+percent_test_pos;

percent_train_neg = train_fraction*(1-train_rework_ratio);
percent_test_neg = (1-train_fraction)*(1-test_rework_ratio);
percent_neg = percent_train_neg+percent_test_neg;

pos_neg_actual_ratio = round((n_claims_pos/n_claims_neg)*10^10)/10^10;
pos_neg_sample_ratio = round((percent_pos/percent_neg)*10^10)/10^10;

if pos_neg_actual_ratio >= pos_neg_sample_ratio
    n_train_negative = floor(n_claims_neg*sample_percent*percent_train_neg/percent_neg);
    n_test_negative = floor(n_claims_neg*sample_percent*percent_test_neg/percent_neg);
    n_train_positive = floor(n_train_negative*percent_train_pos/percent_train_neg);
    n_test_positive = floor(n_test_negative*percent_test_pos/percent_test_neg);
elseif pos_neg_actual_ratio < pos_neg_sample_ratio
    n_train_positive = floor(n_claims_neg*sample_percent*percent_train_pos/percent_pos);
    n_test_positive = floor(n_claims_neg*sample_percent*percent_test_pos/percent_pos);
    n_train_negative = floor(n_train_positive*percent_train_neg/percent_train_pos);
    n_test_negative = floor(n_test_positive*percent_test_neg/percent_test_pos);
end

clear percent_train_pos percent_test_pos percent_pos percent_train_neg percent_test_neg percent_neg pos_neg_actual_ratio pos_neg_sample_ratio
clear sample_percent test_rework_ratio train_rework_ratio train_fraction max_train_fraction
%% Remove unrequired features

pos_delete_col = cell(n,1);
neg_delete_col = cell(n,1);

matlabpool open
parfor i=1:n
    
%     if i~=1 && isequal(active_features{i},active_features{i-1}) && isequal(frequency_threshold(i),frequency_threshold(i-1))
%         pos_delete_col{i} = pos_delete_col{i-1};
%         neg_delete_col{i} = neg_delete_col{i-1};
%         continue;
%     end
%     
    [jk delete_vec] = svm_clean_feature_matrix([train_sp_case(:,3:end);...
                                                    claim_mat(:,3:end);...
                                                 test_sp_case(:,3:end)],...
                                              active_features{i},frequency_threshold(i),true);
    pos_delete_col{i} = find(delete_vec)+2;
    neg_delete_col{i} = find(delete_vec)+2;%clear delete_vec
%     
%     [jk delete_vec] = svm_clean_feature_matrix([train_sp_case(nloc_train_sp_case,3:end);...
%                                                              claim_mat(nloc_claim_mat,3:end);...
%                                                        test_sp_case(nloc_test_sp_case,3:end)],...
%                                               active_features{i},frequency_threshold(i),true); 
%     neg_delete_col{i} = find(delete_vec)+2; clear delete_vec
%     
%     update(conn,'training_models',{'status_cd'},{status},...
%           ['where training_models.training_model_id = ', int2str(model_ids(i))]);
%     
%     if update_train_flag
%         update(conn,'training_model_parameters',{'value'},train_fraction,...
%               ['WHERE training_model_parameters.training_model_id = ', int2str(model_ids(i))...
%                ' AND training_model_parameters.model_class_parameter_id = 36']);
%     end
      
end
clear i

%% Randomize Matrix, Run Experiment

statistics = cell(n_iterations,n);
accuracy = cell(n_iterations,n);
weights = cell(n_iterations,n);
scores = cell(n_iterations,n);
W = cell(n_iterations,n);

if n_iterations > n
    %replace with parfor
    parfor j = 1:n_iterations     
        [jk claim_positive_loc] = sort(rand(length(ploc_claim_mat),1));
        [jk claim_negative_loc] = sort(rand(length(nloc_claim_mat),1));

        pos_mat_static = [train_sp_case(ploc_train_sp_case,:);...
                          claim_mat(ploc_claim_mat(claim_positive_loc),:);...
                          test_sp_case(ploc_test_sp_case,:)];

        neg_mat_static = [train_sp_case(nloc_train_sp_case,:);
                          claim_mat(nloc_claim_mat(claim_negative_loc),:);
                          test_sp_case(nloc_test_sp_case,:)];                

        [statistics(j,:) accuracy(j,:) weights(j,:) scores(j,:) W(j,:)] = svm_create_train_test(model_ids,SVM_parameters,...
                                                                                                pos_mat_static,neg_mat_static,...
                                                                                                pos_delete_col,neg_delete_col,...
                                                                                                n_train_positive, n_train_negative,...
                                                                                                n_test_positive, n_test_negative,...
                                                                                                j,training_precisions,workingdir);
    end
else
    for j = 1:n_iterations     
        [jk claim_positive_loc] = sort(rand(length(ploc_claim_mat),1));
        [jk claim_negative_loc] = sort(rand(length(nloc_claim_mat),1));

        pos_mat_static = [train_sp_case(ploc_train_sp_case,:);...
                          claim_mat(ploc_claim_mat(claim_positive_loc),:);...
                          test_sp_case(ploc_test_sp_case,:)];

        neg_mat_static = [train_sp_case(nloc_train_sp_case,:);
                          claim_mat(nloc_claim_mat(claim_negative_loc),:);
                          test_sp_case(nloc_test_sp_case,:)];                

        [statistics(j,:) accuracy(j,:) weights(j,:) scores(j,:) W(j,:)] = svm_create_train_test(model_ids,SVM_parameters,...
                                                                                                pos_mat_static,neg_mat_static,...
                                                                                                pos_delete_col,neg_delete_col,...
                                                                                                n_train_positive, n_train_negative,...
                                                                                                n_test_positive, n_test_negative,...
                                                                                                j,training_precisions,workingdir);     
    end
end
matlabpool close
clear i j

%% Write Results to Database
try
    for j=1:n
        for i=1:n_iterations
            fastinsert(conn,'model_statistics',{'training_model_id','start_time','end_time','run_duration','n_split','file_name'},...
                        statistics{i,j});
            model_stat_id = sql_query(conn,'select max(id) from model_statistics');
            if iscell(model_stat_id)
                model_stat_id = cell2mat(model_stat_id);
            end
            fastinsert(conn,'feature_training_model_weights',{'model_statistic_id','feature_id','weight'},...
                        [repmat(model_stat_id,size(weights{i,j},1),1) weights{i,j}]);
            fastinsert(conn,'claim_scores',{'claim_id','model_statistic_id','score'},...
                        [scores{i,j}(:,1) repmat(model_stat_id,size(scores{i,j},1),1) scores{i,j}(:,2)]);
            fastinsert(conn,'model_statistic_details',{'model_training_precision_id','model_statistic_id','accuracy'},...
                        [training_precisions(:,1) repmat(model_stat_id,size(accuracy{i,j},1),1) accuracy{i,j}]);
            %w = W{i,j};
            %save(strcat('E:\Users\Gaurav\IBC\analytics_etl_process\data\W_',num2str(model_stat_id),'.mat'),'w')
            disp([int2str(model_stat_id) ' RESULTS INSERTED INTO DB!'])
        end
    end
catch MException
      save(['E:\Users\Gaurav\IBC\analytics_etl_process\data\Precisions_',datestr(now,'mm-dd-HH-MM'),'.mat'],'accuracy');
      save(['E:\Users\Gaurav\IBC\analytics_etl_process\data\Statistics_',datestr(now,'mm-dd-HH-MM'),'.mat'],'statistics');
      save(['E:\Users\Gaurav\IBC\analytics_etl_process\data\W_',datestr(now,'mm-dd-HH-MM','.mat')],'W');
      MException.message
      for s=1:size(MException.stack)
          MException.stack(s,1)
      end
      keyboard
end

%% Junk Code

% C_ = SGSVM_param_mat(:,1);
% T_ = SGSVM_param_mat(:,2);
% K_ = SGSVM_param_mat(:,3);
% StopT = SGSVM_param_mat(:,4);

%     V = cell(1,n);
%     W = cell(1,n);
%     X = cell(1,n);
%     Y = cell(1,n);
%     Z = cell(1,n);  
%     
%     for i=1:n
%         
%         [Rp Cp Vp] = find(pos_mat_static);
%         locp = logical(ismember(Cp,find(pos_delete_col{i}==0)));
%         positive_mat = spconvert([Rp(locp) Cp(locp) Vp(locp); (max(Rp)+1) length(pos_delete_col{i}) 0]);
%         positive_mat = positive_mat(find(sum(positive_mat(:,3:end),2)>0),:);        
%         
%         [Rn Cn Vn] = find(neg_mat_static);
%         locn = logical(ismember(Cn,find(neg_delete_col{i}==0)));
%         negative_mat = spconvert([Rn(locn) Cn(locn) Vn(locn); (max(Rn)+1) length(neg_delete_col{i}) 0]);
%         negative_mat = negative_mat(find(sum(negative_mat(:,3:end),2)>0),:);   
%                 
%         train_mat = [positive_mat(1:n_train_positive,:);
%                      negative_mat(1:n_train_negative,:)];
%              
%         test_mat = [positive_mat(end-n_test_positive+1:end,:);
%                     negative_mat(end-n_test_negative+1:end,:)];
%         
%          if length(find(train_mat(:,2)==1))~=n_train_positive ||...
%             length(find(train_mat(:,2)==-1))~=n_train_negative ||...
%             length(find(test_mat(:,2)==1))~=n_test_positive ||...
%             length(find(test_mat(:,2)==-1))~=n_test_negative
%              continue;
%          end
%         
%         try
%             [V{i} W{i} X{i} Y{i} Z{i}] = sgsvm_evaluate_model(model_ids(i),train_mat,test_mat,j,training_precisions,C_(i),K_(i),T_(i),StopT(i));
%         catch MException
%               MException.message
%               for s=1:size(MException.stack)
%                   MException.stack(s,1)
%               end
%               matlabpool close
%         end
%     end
%     
%     statistics(j,:) = V;
%       accuracy(j,:) = W;
%        weights(j,:) = X;
%         scores(j,:) = Y;
%              W(j,:) = Z;               