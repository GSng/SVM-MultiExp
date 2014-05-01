function output = sql_query(conn, query)


cur = exec(conn,query);

fetch_size = 10000;
cur = fetch(cur,fetch_size);
data = cur.Data;
total = 0;
while 1
    cur = fetch(cur, fetch_size);
    
    if rows(cur)==0
        break
    end
    data = cat(1, data, cur.Data);
    %disp([num2str(total+fetch_size) ' rows fetched..'])
    total = total+fetch_size;
end

output = data;
close(cur)
