function [output_mat claim_ids] = svm_fetch_claim_level_matrix_scaled(conn,train_or_classify,flag,start_condition,label_column)

if nargin<5
    label_column = 'is_rework';
else
    if iscell(label_column)
        label_column = char(label_column);
    end
end

if strcmp(train_or_classify,'train')
    claim_condition_query = ['SELECT DISTINCT claim_id FROM claim_labels WHERE ' label_column ' IS NOT NULL'];
else
    if nargin==4 && ~isempty(flag) && ~isempty(start_condition)
        claim_condition_query = ['select claim_id from claims where claims.' flag ' = ''' start_condition ''' order by claim_id'];
    else
        claim_condition_query = train_or_classify;
    end
end

query = ['SELECT DISTINCT claim_features.claim_id, claim_features.feature_id, value FROM '...
        ' (' claim_condition_query ')dt JOIN claim_features ON claim_features.claim_id = dt.claim_id'...
        ' JOIN features ON (claim_features.feature_id = features.feature_id)'...
        ' WHERE features.use_level LIKE (''%claim%'') '];

raw_data = sql_query_w_count(conn,query,3,'numeric');

%scaled the value
query = 'SELECT feature_id,max_range,min_range FROM features WHERE feature_type = ''continuous'' AND max_range<>min_range';
setdbprefs('DataReturnFormat','numeric')
feature_ranges = sql_query(conn,query);
[tf loc] = ismember(raw_data(:,2),feature_ranges(:,1));
loc = loc(loc>0);
update_feature_index=logical(tf);
raw_data(update_feature_index,3)= (raw_data(update_feature_index,3)-feature_ranges(loc,3))./(feature_ranges(loc,2)-feature_ranges(loc,3));

%make the features with same min and max range to 1
query = 'select feature_id from features where feature_type = ''continuous'' and max_range=min_range';
setdbprefs('DataReturnFormat','numeric')
same_max_min_feature_ids = sql_query(conn,query);

if ~iscell(same_max_min_feature_ids)
    if ~isempty(same_max_min_feature_ids)
        [tf loc]= ismember(raw_data(:,2),same_max_min_feature_ids);
        raw_data(logical(tf),3) = 1;
    end
else
    if ~ischar(same_max_min_feature_ids{1})
        same_max_min_feature_ids = cell2mat(same_max_min_feature_ids);
        [tf loc]= ismember(raw_data(:,2),same_max_min_feature_ids);
        raw_data(logical(tf),3) = 1;
    end
end

[u,loc] = unique(raw_data(:,1:2),'rows');
raw_data = raw_data(loc,:);    
[claim_ids jk claim_index] = unique(raw_data(:,1));
output_mat = spconvert([claim_index raw_data(:,2) raw_data(:,3)]);

is_rework_column = sql_query(conn,['SELECT feature_id FROM features WHERE name = ''' label_column '''']);
if size(output_mat,2)<is_rework_column
    output_mat = [output_mat zeros(size(output_mat,1),(is_rework_column-size(output_mat,2)))];
end
is_rework_labels = output_mat(:,is_rework_column);
output_mat(:,is_rework_column) = 0;
is_rework_labels(is_rework_labels==0) = -1;
output_mat = [is_rework_labels output_mat];