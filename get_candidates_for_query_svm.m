function [active_query_indices] = get_candidates_for_query_svm(pred,activepool_matrix,query_params,num_of_queries,workingDir,avg_sim_sort,activepool_claim_ids)

active_query_indices=zeros(num_of_queries,1);

method = query_params{1};
param1 = query_params {2};

if strcmp(method,'random')
    
    L = length(activepool_claim_ids);
    [jk loc] = sort(rand(L,1));
    indices = 1:L;
    active_query_indices = indices(loc(1:num_of_queries));
    
%     for i=1:num_of_queries
%         active_query_indices(i) = ceil(rand(1,1)*size(activepool_matrix,1));
%         if(i>1)
%             while(ismember(active_query_indices(i), active_query_indices(1:i-1)))
%                 active_query_indices(i) = ceil(rand(1,1)*size(activepool_matrix,1));
%             end
%         end
%     end
    
elseif strcmp(method,'uncertainty')

	%pred = activepool_matrix(:,2:end)*W;
    [temp1 index] = sort(abs(pred(:,1)), 'ascend');
    active_query_indices = index(1:num_of_queries);
 
elseif strcmp (method, 'densitycosine') || strcmp (method, 'densitycosineknn')
        
    active_query_claim_ids = avg_sim_sort(1:num_of_queries,2);
    [tf active_query_indices] = ismember(active_query_claim_ids,activepool_claim_ids);
        
elseif strcmp (method, 'densityeuclid') || strcmp (method, 'densityeuclidknn')
    
    active_query_claim_ids = avg_sim_sort(1:num_of_queries,2);
    [tf active_query_indices] = ismember(active_query_claim_ids,activepool_claim_ids);
    
elseif strcmp (method, 'uncerdenscos') || strcmp (method, 'uncerdenscosknn')
    
    uncertainty = abs(pred);
    [tf avg_sim_sort_i] = ismember(activepool_claim_ids,avg_sim_sort(:,2));

    avg_uncertainty_sort = avg_sim_sort(avg_sim_sort_i(avg_sim_sort_i>0),:);
    avg_uncertainty_sort(:,1) = avg_uncertainty_sort(:,1).* uncertainty;

    [avg_uncertainty_sort(:,1) sort_i] = sort(avg_uncertainty_sort(:,1),1,'ascend');
    avg_uncertainty_sort(:,2) = avg_uncertainty_sort(sort_i,2);
    
    %L = size(avg_sim_sort,1);
    active_query_claim_ids = avg_uncertainty_sort(1:num_of_queries,2);
    [tf active_query_indices] = ismember(active_query_claim_ids,activepool_claim_ids);
         
elseif strcmp(method,'confidence')

	%pred = activepool_matrix(:,2:end)*W;
    [temp1 index] = sort(pred(:,1), 'ascend');
    active_query_indices(1:(num_of_queries/2),1) = index(1:(num_of_queries/2));
    active_query_indices((num_of_queries/2)+1:num_of_queries,1) = index((length(index)-(num_of_queries/2)+1):length(index));
    
elseif strcmp(method,'clusteruncer')
    
    clusters = avg_sim_sort(:,1:2);
    avg_sim_sort = avg_sim_sort(:,[3 2]);
    
    uncertainty = abs(pred);
    index=1;
    clusters(:,3)=uncertainty;
    max_cluster=0;
    
    try
    for i=1:max(clusters(:,1))
        
        cluster_i= clusters(clusters(:,1)==i,:);
        [cluster_i_sort(:,3) sort_i]=sort(cluster_i(:,3));
        cluster_i_sort(:,1:2) = cluster_i(sort_i,1:2);
        num_per_cluster = ceil((num_of_queries*sum(clusters(:,1)==i))/size(activepool_matrix,1));
        
        if (index+num_per_cluster-1 <= num_of_queries)
            active_query_claim_ids (index:(index+num_per_cluster-1),1) = cluster_i_sort(1:num_per_cluster,2);
            index=index+num_per_cluster;
        end
        if num_per_cluster>max_cluster
            max_cluster = num_per_cluster;
            max_i=i;
        end
        clear cluster_i cluster_i_sort num_per_cluster; 
    end
    
    if size(active_query_claim_ids,1)<num_of_queries
        clear cluster_i cluster_i_sort num_per_cluster; 
        cluster_i= clusters(clusters(:,1)==max_i,:);
        [cluster_i_sort(:,3) sort_i]=sort(cluster_i(:,3));
        cluster_i_sort(:,1:2) = cluster_i(sort_i,1:2);
        active_query_claim_ids (size(active_query_claim_ids,1)+1:num_of_queries,1) = cluster_i_sort(max_cluster+1:max_cluster+num_of_queries-size(active_query_claim_ids,1),2);
    end
    
    [tf active_query_indices] = ismember(active_query_claim_ids,activepool_claim_ids);
    
    catch
        keyboard;
    end
    
    
elseif strcmp(method,'clusteruncerdens')
    
    clusters = avg_sim_sort(:,1:2);
    avg_sim_sort = avg_sim_sort(:,[3 2]);
        
    uncertainty = abs(pred);
    [tf avg_sim_sort_i] = ismember(activepool_claim_ids,avg_sim_sort(:,2));

    avg_uncertainty_sort = avg_sim_sort(avg_sim_sort_i(avg_sim_sort_i>0),:);
    avg_uncertainty_sort(:,1) = avg_uncertainty_sort(:,1).* uncertainty;
    
    index=1;
    clusters(:,3)=avg_uncertainty_sort(:,1);
    max_cluster=0;
    
    try
    for i=1:max(clusters(:,1))
       
        cluster_i= clusters(clusters(:,1)==i,:);
        [cluster_i_sort(:,3) sort_i]=sort(cluster_i(:,3));
        cluster_i_sort(:,1:2) = cluster_i(sort_i,1:2);
        num_per_cluster = ceil((num_of_queries*sum(clusters(:,1)==i))/size(activepool_matrix,1));
        
        if (index+num_per_cluster-1 <= num_of_queries)
            active_query_claim_ids (index:(index+num_per_cluster-1),1) = cluster_i_sort(1:num_per_cluster,2);
            index=index+num_per_cluster;
        end
        if num_per_cluster>max_cluster
            max_cluster = num_per_cluster;
            max_i=i;
        end
        clear cluster_i cluster_i_sort num_per_cluster; 
    end
    
    if length(active_query_claim_ids)<num_of_queries
              clear cluster_i cluster_i_sort num_per_cluster; 
        cluster_i= clusters(clusters(:,1)==max_i,:);
        [cluster_i_sort(:,3) sort_i]=sort(cluster_i(:,3));
        cluster_i_sort(:,1:2) = cluster_i(sort_i,1:2);
        active_query_claim_ids (size(active_query_claim_ids,1)+1:num_of_queries,1) = cluster_i_sort(max_cluster+1:max_cluster+num_of_queries-size(active_query_claim_ids,1),2);
    end
    
    [tf active_query_indices] = ismember(active_query_claim_ids,activepool_claim_ids);
    
    catch
        keyboard;
    end


elseif strcmp(method,'clusteruniuncer')
        
    clusters = avg_sim_sort(:,1:2);
    avg_sim_sort = avg_sim_sort(:,[3 2]);
    
    uncertainty = abs(pred);
    index=1;
    clusters(:,3)=uncertainty;
       
    try
        cluster_index=ones(max(clusters(:,1)),1);
        num_per_cluster=round(num_of_queries/max(clusters(:,1)));
        for i=1:max(clusters(:,1))
            
            cluster_i= clusters(clusters(:,1)==i,:);
            if size(cluster_i,1)>0
                [cluster_i_sort(:,3) sort_i]=sort(cluster_i(:,3));
                cluster_i_sort(:,1:2) = cluster_i(sort_i,1:2);
                if size(cluster_i,1)>=num_per_cluster   
                    active_query_claim_ids (index:(index+num_per_cluster-1),1) = cluster_i_sort(1:num_per_cluster,2);
                    index=index+num_per_cluster;
                    cluster_index(i)=num_per_cluster+1;    
                else
                    active_query_claim_ids (index:(index+size(cluster_i,1)-cluster_index(i)),1) = cluster_i_sort(cluster_index(i):size(cluster_i,1),2);
                    index=index+size(cluster_i,1)-cluster_index(i)+1;
                    cluster_index(i)=size(cluster_i,1);  
                end
                clear cluster_i cluster_i_sort;
            end  
        end
       
        i=1;
        while size(active_query_claim_ids,1)<num_of_queries                   
            cluster_i= clusters(clusters(:,1)==i,:);
            if size(cluster_i,1)>0
                [cluster_i_sort(:,3) sort_i]=sort(cluster_i(:,3));
                cluster_i_sort(:,1:2) = cluster_i(sort_i,1:2);
                num_per_cluster=round(num_of_queries/max(clusters(:,1)));
                if (size(cluster_i,1)-cluster_index(i)+1)>=num_per_cluster 
                    active_query_claim_ids (index:(index+num_per_cluster-1),1) = cluster_i_sort(cluster_index(i):cluster_index(i)+num_per_cluster-1,2);
                    index=index+num_per_cluster;
                    cluster_index(i)=cluster_index(i)+num_per_cluster;
                else
                    active_query_claim_ids (index:(index+size(cluster_i,1)-cluster_index(i)),1) = cluster_i_sort(cluster_index(i):size(cluster_i,1),2);
                    index=index+size(cluster_i,1)-cluster_index(i)+1;    
                end
                clear cluster_i cluster_i_sort ;
            end
            if i<max(clusters(:,1))
                i=i+1;
            else
                i=1;
            end
            if ( size(active_query_claim_ids,1) > num_of_queries && size(active_query_claim_ids,1) ~= size(unique (active_query_claim_ids))) 
                active_query_claim_ids = unique (active_query_claim_ids);
                index= size(active_query_claim_ids,1)+1;
            end
        end
               
    [tf active_query_indices] = ismember(active_query_claim_ids(1:num_of_queries,1),activepool_claim_ids);
    
    catch
        keyboard;
    end
    

elseif strcmp(method,'clusteruniuncerdens')
    
    clusters = avg_sim_sort(:,1:2);
    avg_sim_sort = avg_sim_sort(:,[3 2]);
    
    uncertainty = abs(pred);
    [tf avg_sim_sort_i] = ismember(activepool_claim_ids,avg_sim_sort(:,2));

    avg_uncertainty_sort = avg_sim_sort(avg_sim_sort_i(avg_sim_sort_i>0),:);
    avg_uncertainty_sort(:,1) = avg_uncertainty_sort(:,1).* uncertainty;
    
    index=1;
    clusters(:,3)=avg_uncertainty_sort(:,1);
        
    try
        cluster_index=ones(max(clusters(:,1)),1);
        num_per_cluster=round(num_of_queries/max(clusters(:,1)));
        for i=1:max(clusters(:,1))
            
                cluster_i= clusters(clusters(:,1)==i,:);
                if size(cluster_i,1)>0
                    [cluster_i_sort(:,3) sort_i]=sort(cluster_i(:,3));
                    cluster_i_sort(:,1:2) = cluster_i(sort_i,1:2);
                    if size(cluster_i,1)>=num_per_cluster
                        
                            active_query_claim_ids (index:(index+num_per_cluster-1),1) = cluster_i_sort(1:num_per_cluster,2);
                            index=index+num_per_cluster;
                            cluster_index(i)=num_per_cluster+1;
                        
                    else
                        
                            active_query_claim_ids (index:(index+size(cluster_i,1)-cluster_index(i)),1) = cluster_i_sort(cluster_index(i):size(cluster_i,1),2);
                            index=index+size(cluster_i,1)-cluster_index(i)+1;
                            cluster_index(i)=size(cluster_i,1);
                        
                    end
                    clear cluster_i cluster_i_sort;
                end  
        end
       
        i=1;
        while size(active_query_claim_ids,1)<num_of_queries       
                        cluster_i= clusters(clusters(:,1)==i,:);
                        if size(cluster_i,1)>0
                            [cluster_i_sort(:,3) sort_i]=sort(cluster_i(:,3));
                            cluster_i_sort(:,1:2) = cluster_i(sort_i,1:2);
                            num_per_cluster=round(num_of_queries/max(clusters(:,1)));
                            if (size(cluster_i,1)-cluster_index(i)+1)>=num_per_cluster 
                                
                                    active_query_claim_ids (index:(index+num_per_cluster-1),1) = cluster_i_sort(cluster_index(i):cluster_index(i)+num_per_cluster-1,2);
                                    index=index+num_per_cluster;
                                    cluster_index(i)=cluster_index(i)+num_per_cluster;
                                
                            
                            else
                                
                                    active_query_claim_ids (index:(index+size(cluster_i,1)-cluster_index(i)),1) = cluster_i_sort(cluster_index(i):size(cluster_i,1),2);
                                    index=index+size(cluster_i,1)-cluster_index(i)+1;
                                
                            end
                            clear cluster_i cluster_i_sort ;
                        end

                        if i<max(clusters(:,1))
                            i=i+1;
                        else
                            i=1;
                        end
        end
               
    [tf active_query_indices] = ismember(active_query_claim_ids(1:num_of_queries,1),activepool_claim_ids);
    
    catch
        keyboard;
    end
    
    
elseif strcmp(method,'manual')
    
    try
        load('E:\Zahra\IBC\active_eval\flase100dcosine-manual.txt');
        active_query_claim_ids= flase100dcosine_manual;
        num_of_queries=116;
        [tf active_query_indices] = ismember(active_query_claim_ids,activepool_claim_ids);
    
    catch
        keyboard;
    end
    
elseif strcmp(method,'cluster')
    
    % write out matrix file
    %%MK activepool_file=[workingDir '/activepool_cluster.mat'];
    %activepool_srink_file=[workingDir '/activepool_cluster.mat.shrink'];
    activepool_srink_file=strcat(workingDir, '/activepool_cluster.mat','.shrink');
	mat_sparse_2_svm_sparse_mk(activepool_matrix,activepool_srink_file,true,false,'',false,true);
    % convert it to cluto format - wud b better to directly write out cluto
    % format
    cluster_cluto_activepool_file=[activepool_srink_file '.cluto'];
    %command=['!C:\Perl64\bin\perl.exe "E:\My Programs\cluto-2.1.1\convert_svm_matrix_2_CLUTO_matrix.pl" ' activepool_srink_file ' ' cluster_cluto_activepool_file];
    %eval(command);

    %run the clustering
    %number_of_clusters=floor(size(activepool_matrix,1)/20);
    number_of_clusters=num_of_queries;
    cluster_output_file=[cluster_cluto_activepool_file '.clustering.' num2str(number_of_clusters)];
    cluster_summary_file=[cluster_output_file '.summ'];
    %command=['!"E:\My Programs\cluto-2.1.1\Win32\vcluster.exe" -clustfile ' cluster_output_file ' ' cluster_cluto_activepool_file ' ' num2str(number_of_clusters) ' > ' cluster_summary_file];
    %command=['!"E:\My Programs\cluto-2.1.1\Win32\vcluster.exe" -zscore -clmethod=rbr -sim=cos -clustfile ' cluster_output_file ' ' cluster_cluto_activepool_file ' ' num2str(number_of_clusters) ' > ' cluster_summary_file];
    command=['!"E:\My Programs\cluto-2.1.2\MSWIN-x86_64\vcluster.exe" -zscore -clmethod=rbr -sim=cos -clustfile ' cluster_output_file ' ' cluster_cluto_activepool_file ' ' num2str(number_of_clusters) ' > ' cluster_summary_file];
    eval(command);

    %%%read the cluster file
    %cluster_ids=dlmread(cluster_output_file);
        
    %%%% read as text
    %keyboard
    [X Y Z]=textread(cluster_output_file,'%s %s %s');
    
%     Y(strmatch('-1.#IND',Y))={'-1000000'};
%     Z(strmatch('-1.#IND',Z))={'-1000000'};
%     
%     Y(strmatch('1.#INF',Y))={'1000000'};
%     Z(strmatch('1.#INF',Z))={'1000000'};
    
    X_num = cellfun(@str2double,X,'ErrorHandler',@errorfun,'UniformOutput',true);
    Y_num = cellfun(@str2double,Y,'ErrorHandler',@errorfun,'UniformOutput',true);
    Z_num = cellfun(@str2double,Z,'ErrorHandler',@errorfun,'UniformOutput',true);
    
    cluster_ids=[X_num Y_num Z_num];
    
    %transform matrix to have abs values
    [B sort_i] = sortrows(abs(cluster_ids),[1 2 -3]);
    [junk start_loc] = unique(B(:,1),'first');
    active_query_indices=sort_i(start_loc);
    
%     number_of_queries_per_cluster=ceil(num_of_queries/number_of_clusters);
%     local_active_query_indices=[];
%     %keyboard
%     for i=1:number_of_clusters
%         %working_cluster_number=floor(num_of_queries/number_of_queries_per_cluster); %starts with 0
%         working_cluster_number=i-1;
%         %get a claim id randomly from this working_cluster_id
%         working_claim_index=getClaimIDIndicesRandomlyFromCluster(working_cluster_number,cluster_ids,number_of_queries_per_cluster);
%         %while(ismember(working_claim_index, active_query_indices(1:i-1)))
%         %    working_claim_index=getClaimIDIndicesRandomlyFromCluster(working_cluster_number,cluster_ids,1);
%         %end
%         local_active_query_indices=[local_active_query_indices;working_claim_index];
%     end
%     %keyboard
%     active_query_indices=local_active_query_indices(1:num_of_queries);
end


