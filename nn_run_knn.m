function [nn_mat output_file] = nn_run_knn(claim_mat,N_nn,number_of_queries,input_file,output_file)

if ~ischar(N_nn)
    N_nn = int2str(N_nn);
end
if ~ischar(number_of_queries)
    number_of_queries = int2str(number_of_queries);
end
if ~ischar(input_file)
    input_file = int2str(input_file);
end

%write CLUTO input file
if ~ischar(claim_mat)
    mat_sparse_2_svm_sparse(claim_mat,input_file,0,0,[],0,1);
    if nargin<5
        [pathstr filename ext] = fileparts(cluster_input_file);
        output_file = [pathstr '/' filename '_nn_k' N_nn '.csv'];
    end
    N_rows = num2str(size(claim_mat,1));
else
    N_rows = input_file;
    input_file = claim_mat;
    [pathstr filename ext] = fileparts(input_file);
    output_file = [pathstr '/' filename '_nn_k' N_nn '.csv'];        
end

%run KNN
eval_str=['!E:/Projects/SVMpipeline/svm_run_multi_exp/nn_final.exe in ' input_file ' num_rows ' N_rows ' out ' output_file ' n ' number_of_queries ' k ' N_nn ' strictQuery 1'];
eval(eval_str);

%read results
nn_mat = csvread(output_file,1,0);