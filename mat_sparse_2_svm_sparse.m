function new_output_file = mat_sparse_2_svm_sparse(mat_sparse,output_file,shrink,regular_sparse,claim_ids,output_mat_format,output_cluto,incremental,sizeOfOldFile)

%keyboard
label_column = mat_sparse(:,1);
feature_matrix = mat_sparse(:,2:end);
[r c v] = find(feature_matrix);
new_output_file = output_file;

if nargin<8
    sizeOfOldFile = 0;
end
if nargin<7
    incremental = 0;
end
if nargin<6
    output_mat_format = 0;
end

if ((nargin == 2 || shrink) && output_cluto==false)
    c_key = sort(unique(c));
    new_c_key = 1:length(c_key);
    
    [tf loc] = ismember(c,c_key);
    new_c = new_c_key(loc)';
    save(output_file,'c_key')
    write_file (r,new_c,v,label_column,[output_file '.shrink'])
    new_output_file = [output_file '.shrink'];
end

if nargin <4 || (nargin>=4 && regular_sparse && ~incremental)
    write_file(r,c,v,label_column,output_file)
end

claim_data.matrix = mat_sparse;
if nargin == 5
    claim_data.claim_ids = claim_ids;
end
if (nargin>=4 && output_mat_format)
    save([output_file '.mat'],'claim_data')
    new_output_file = [output_file '.mat'];
end
if (nargin>=7 && output_cluto) %&& ~exist('incremental','var'))
    c_key = sort(unique(c));
    new_c_key = 1:length(c_key);
    
    [tf loc] = ismember(c,c_key);
    new_c = new_c_key(loc)';
    %save(output_file,'c_key')
    write_cluto_file(r,new_c,v,label_column,[output_file '.cluto'])
    new_output_file = [output_file '.cluto'];
end
if(nargin>=8 && incremental && ~output_cluto)
    c_key = sort(unique(c));
    new_c_key = 1:length(c_key);
    
    [tf loc] = ismember(c,c_key);
    new_c = new_c_key(loc)';
    %save(output_file,'c_key')
    write_inc_file (r,new_c,v,label_column,output_file,sizeOfOldFile+1);
end
if(nargin>=8 && incremental && output_cluto)
    c_key = sort(unique(c));
    new_c_key = 1:length(c_key);
    
    [tf loc] = ismember(c,c_key);
    new_c = new_c_key(loc)';
    %save(output_file,'c_key')
    write_cluto_inc_file(r,new_c,v,label_column,[output_file '.cluto'],sizeOfOldFile+1)
    new_output_file = [output_file '.cluto'];
end

end

function write_file(r,c,v,label_column,output_file)

r_c_v = [r c v];

[jk sort_index] = sort(r_c_v(:,2),'ascend');
r_c_v = r_c_v(sort_index,:);

[jk sort_index] = sort(r_c_v(:,1),'ascend');
r_c_v = r_c_v(sort_index,:);

[jk start_loc] = unique(r_c_v(:,1),'first');
[jk end_loc] = unique(r_c_v(:,1),'last');

fid = fopen(output_file,'w+');

h = waitbar(0,'Writing SVM Sparse File');
n_rows = length(start_loc);

for i=1:n_rows
    t_data = r_c_v(start_loc(i):end_loc(i),:);
    n_data = size(t_data,1);
    output_str=char(cellstr([num2str(t_data(:,2)) char(repmat(':',n_data,1)) char(num2str(t_data(:,3))) char(repmat('_',n_data,1))]))';
    output_str = [num2str(label_column(i)) '_' output_str(:)' '\n'];
    output_str = output_str(isspace(output_str)==0);
    output_str(ismember(output_str,'_')==1) = char(32);
    fprintf(fid,output_str);
    waitbar(i/n_rows,h,['Writing SVM Sparse Files: ' round(num2str(i/n_rows*100)) '% complete']);
end
close(h)
fclose(fid)
end

function write_inc_file(r,c,v,label_column,output_file,start_index)

r_c_v = [r c v];

[jk sort_index] = sort(r_c_v(:,2),'ascend');
r_c_v = r_c_v(sort_index,:);

[jk sort_index] = sort(r_c_v(:,1),'ascend');
r_c_v = r_c_v(sort_index,:);

[jk start_loc] = unique(r_c_v(:,1),'first');
[jk end_loc] = unique(r_c_v(:,1),'last');

fid = fopen(output_file,'a');

h = waitbar(0,'Writing SVM Sparse File');
n_rows = length(start_loc);

%for i=1:n_rows
for i=start_index:n_rows
    t_data = r_c_v(start_loc(i):end_loc(i),:);
    n_data = size(t_data,1);
    output_str = char(cellstr([num2str(t_data(:,2)) char(repmat(':',n_data,1)) char(num2str(t_data(:,3))) char(repmat('_',n_data,1))]))';
    output_str = [num2str(label_column(i)) '_' output_str(:)' '\n'];
    output_str = output_str(isspace(output_str)==0);
    output_str(ismember(output_str,'_')==1) = char(32);
    fprintf(fid,output_str);
    waitbar(i/n_rows,h,['Writing SVM Sparse Files: ' round(num2str(i/n_rows*100)) '% complete']);
end
fprintf(fid,'\n');
close(h)
fclose(fid)
end

function write_cluto_file(r,c,v,label_column,output_file)
%keyboard
r_c_v = [r c v];

[jk sort_index] = sort(r_c_v(:,2),'ascend');
r_c_v = r_c_v(sort_index,:);

[jk sort_index] = sort(r_c_v(:,1),'ascend');
r_c_v = r_c_v(sort_index,:);

[jk start_loc] = unique(r_c_v(:,1),'first');
[jk end_loc] = unique(r_c_v(:,1),'last');

fid = fopen(output_file,'w');

h = waitbar(0,'Writing SVM Sparse File');
n_rows = length(start_loc);
num_of_columns=length(unique(c));
output_str=[num2str(n_rows) ' ' num2str(num_of_columns) ' ' num2str(length(r)) '\n'];
fprintf(fid,output_str);

for i=1:n_rows
    %keyboard
    t_data = r_c_v(start_loc(i):end_loc(i),:);
    n_data = size(t_data,1);
    output_str = char(cellstr([num2str(t_data(:,2)) char(repmat('_',n_data,1)) char(num2str(t_data(:,3))) char(repmat('_',n_data,1))]))';
    %output_str = [num2str(label_column(i)) '_' output_str(:)' '\n'];
    output_str = [output_str(:)' '\n'];
    output_str = output_str(isspace(output_str)==0);
    output_str(ismember(output_str,'_')==1) = char(32);
    fprintf(fid,output_str);
    waitbar(i/n_rows,h,['Writing SVM Sparse Files: ' round(num2str(i/n_rows*100)) '% complete']);
end
close(h)
fclose(fid)
end

function write_cluto_inc_file(r,c,v,label_column,output_file,start_index)
r_c_v = [r c v];

[jk sort_index] = sort(r_c_v(:,2),'ascend');
r_c_v = r_c_v(sort_index,:);

[jk sort_index] = sort(r_c_v(:,1),'ascend');
r_c_v = r_c_v(sort_index,:);

[jk start_loc] = unique(r_c_v(:,1),'first');
[jk end_loc] = unique(r_c_v(:,1),'last');

fid = fopen(output_file,'w');

h = waitbar(0,'Writing SVM Sparse File');
n_rows = length(start_loc);
num_of_columns=length(unique(c));
output_str=[num2str(n_rows) ' ' num2str(num_of_columns) ' ' num2str(length(r)) '\n'];
fprintf(fid,output_str);

for i=start_index:n_rows
    %keyboard
    t_data = r_c_v(start_loc(i):end_loc(i),:);
    n_data = size(t_data,1);
    output_str=char(cellstr([num2str(t_data(:,2)) char(repmat('_',n_data,1)) char(num2str(t_data(:,3))) char(repmat('_',n_data,1))]))';
    %output_str = [num2str(label_column(i)) '_' output_str(:)' '\n'];
    output_str = [output_str(:)' '\n'];
    output_str = output_str(isspace(output_str)==0);
    output_str(ismember(output_str,'_')==1) = char(32);
    fprintf(fid,output_str);
    waitbar(i/n_rows,h,['Writing SVM Sparse Files: ' round(num2str(i/n_rows*100)) '% complete']);
end
close(h)
fclose(fid)
end
