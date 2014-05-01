function [statistics accuracy weights scores W_] = sgsvm_evaluate_model(model_id,train_mat,test_mat,n_split,training_precisions,C,K,T,StopT,w0)

model_start_run_time = now;

test_mat_temp = test_mat; clear test_mat
train_mat_temp = train_mat; clear train_mat

test_claim_ids = test_mat_temp(:,1);
real_test_labels = test_mat_temp(:,2);
test_mat = test_mat_temp(:,3:end); clear test_mat_temp

%train_claim_ids = train_mat_temp(:,1);
train_labels = train_mat_temp(:,2);
train_mat = train_mat_temp(:,3:end); clear train_mat_temp

n = length(train_labels);

if nargin<10
    w0=0;
end
if nargin<9
    StopT = 18000;
end
if nargin<8
    T = abs(10^(floor(log10(n))-n_split));
end
if nargin<7 || K==-1
    K = floor(100000/T);
end
if nargin<6
    C=100;
end

%% Run SVM
tic

% [r c v] = find(train_mat);
% [c_key jk c_loc_j] = unique(c);
% new_c_key = [1:length(c_key)]';    
% new_train_mat = spconvert([r new_c_key(c_loc_j) v]);

C = C*n;
K = floor(K*n);

c_key = [1:length(train_mat)]';
if w0(1,1)~=0
    W0 = rand(length(c_key),1)-1/2;
    W0 = (W0/norm(W0))/(2*sqrt(1/C));
    [common_val c_key_i w0_i] = intersect(c_key,w0(:,1));
    W0(c_key_i) = w0(w0_i,2); clear common_val;
else
    W0 = 0;
end

[w W_] = SGSVM(train_mat',train_labels, W0, C, T, K, StopT);%remember to change back
test_scores = test_mat*w;

run_time = toc;
model_end_run_time = datestr(now);

%% Calculate Accuracy

accuracy = precision_calc(test_scores,real_test_labels,training_precisions);
statistics = {model_id,datestr(model_start_run_time),datestr(model_end_run_time),run_time,n_split};
weights = w;
scores = full([test_claim_ids test_scores]);

% accuracy = zeros(length(training_precisions(:,1)),1);
% [sorted_test_scores sorted_index] = sort(test_scores,'descend');
% sorted_real_labels = real_test_labels(sorted_index);
% n_test = length(sorted_real_labels);
% 
% for k=1:size(training_precisions,1)
%     precision = training_precisions(k,2)/100;
%     numerator_count = ceil((1-precision)*n_test);
%     accuracy(k) = length(find(sorted_real_labels(1:numerator_count)==1))/numerator_count;   
% end
