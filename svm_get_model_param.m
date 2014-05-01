function [value flag] = svm_get_model_param(conn,model_ids,param_name,is_numeric)

setdbprefs('DataReturnFormat','cellarray');
n = length(model_ids);

for i=1:n
    query = ['select t.value, m.flag_label from training_model_parameters t '...
            'join model_class_parameters m on t.model_class_parameter_id = m.id '...
            'where program_name = ''' param_name ''' and training_model_id =' num2str(model_ids(i))];

    t_value = sql_query(conn,query);

    if strcmp(t_value,'No Data')
        error(['Error retrieving parameter. Param: ' param_name ' for model: ' num2str(model_ids(i)) ' was not found']) 
    end

    if nargin ==3 
        value{i} = char(t_value(1));
    elseif is_numeric
        value(i) = str2double(t_value{1,1});
    else
        value{i} = char(t_value(1));
    end

    flag{i} = char(t_value(2));
end
    
    