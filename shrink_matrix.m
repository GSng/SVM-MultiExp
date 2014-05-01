function shrunk_matrix=shrink_matrix(input_matrix)
[r c v]=find(input_matrix);
c_key = sort(unique(c));
new_c_key = 1:length(c_key);
[tf loc] = ismember(c,c_key);
new_c = new_c_key(loc)';
shrunk_matrix=spconvert([r new_c v]);