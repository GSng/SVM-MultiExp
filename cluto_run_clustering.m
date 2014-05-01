function [cluster_ids cluster_summary_mat cluster_output_file] = cluto_run_clustering(claim_mat,number_of_clusters,cluster_input_file,cluster_output_file)

if ~ischar(number_of_clusters)
    number_of_clusters = int2str(number_of_clusters);
end

%write CLUTO input file
if ~ischar(claim_mat)
    mat_sparse_2_svm_sparse(claim_mat,cluster_input_file,0,0,[],0,1);
    if nargin<4
        [pathstr filename ext] = fileparts(cluster_input_file);
        cluster_output_file = [pathstr '/' filename '.clustering.' number_of_clusters];
        cluster_summary_file = [pathstr '/' filename '.summ'];
    else
    	[pathstr filename ext] = fileparts(output_filename);
        cluster_summary_file = [pathstr '/' filename '.summ'];
    end
else 
    cluster_input_file = claim_mat;
    [pathstr filename ext] = fileparts(cluster_input_file);
    cluster_output_file = [pathstr '/' filename '.clustering.' number_of_clusters];
    cluster_summary_file = [pathstr '/' filename '.summ'];
end

%run CLUTO
command=['!E:\Projects\SVMpipeline\svm_run_multi_exp\vcluster.exe -clustfile ' cluster_output_file ' ' cluster_input_file ' ' number_of_clusters ' > ' cluster_summary_file];
eval(command);

%read results
cluster_summary_mat = cluto_read_summary_file(cluster_summary_file);
cluster_ids = dlmread(cluster_output_file);

function summary_mat = cluto_read_summary_file(cluster_file_name)

summary_mat =zeros(1,6);
fid = fopen(cluster_file_name,'r');

section_found = false;
while 1
    tline = fgetl(fid);
    if ~ischar(tline),   break,   end
    
    if regexp(tline,'cid  Size  ISim  ISdev   ESim  ESdev  |')
        section_found = true;
        tline = fgetl(fid);
        break
    end
end

count = 1;
if section_found
    while 1
        tline = fgetl(fid);
        if regexp(tline,'------------------------------------------------------------------------')
            break
        else
           
        summary_mat(count,:) = str2num(tline(1:end-2));
        count = count+1;
        end
        
    end
end