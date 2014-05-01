function raw_data = sql_query_w_count(conn,base_query,n_col,data_type)

count_query = ['select count(*) from ( ' base_query ')dt'];
setdbprefs('DataReturnFormat','numeric')
row_count = sql_query(conn,count_query);

% Retrieve the data
if strcmp(data_type,'numeric')
    raw_data = zeros(row_count,n_col);
else
    raw_data = cell(row_count,n_col);
end
setdbprefs('DataReturnFormat',data_type);
query = base_query;
cur = exec(conn,query);
fetch_size = 100000;
start_loc = 1;
h = waitbar(0,'Fetching data..');
while 1
    cur = fetch(cur, fetch_size);
    if rows(cur)==0
        break
    end
    n_data = size(cur.Data,1);
    raw_data(start_loc:start_loc+n_data-1,:) = cur.Data;
    start_loc = start_loc + n_data;
    waitbar(start_loc/row_count,h,['Fetching Data: ' num2str(start_loc/row_count*100) '% complete.'])
end
close(h)