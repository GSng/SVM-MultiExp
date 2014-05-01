function [feature_score_mat b feature_score_vec] = svm_read_model_file(model_file_name)

fid = fopen(model_file_name,'r');
last_line = '';
while 1
    tline = fgetl(fid);
    if ~ischar(tline),   break,   end
    previous_line = last_line;
    last_line = tline;
    disp(tline)
end

% get the # index
p_loc = find(ismember(previous_line,'#'));
b = str2double(previous_line(1:p_loc-1));
raw_line = last_line(3:end);
raw_line(find(ismember(raw_line,[char(':') char('#')])))= ' ';
raw_vec = eval(['[' raw_line ']']);
feature_score_mat=reshape(raw_vec',2,length(raw_vec)/2)';

feature_score_vec = sparse(feature_score_mat(:,1),1,feature_score_mat(:,2));
fclose('all')