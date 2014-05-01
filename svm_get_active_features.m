function active_features=svm_get_active_features(conn,experiment_id,model_id)

setdbprefs('DataReturnFormat','numeric')

if nargin <3
    query = ['SELECT f.feature_id FROM features f JOIN '...
            '(SELECT feature_id FROM experiment_features ef WHERE experiment_id = ' num2str(experiment_id) ') '...
            'dt ON f.parent_feature_id = dt.feature_id order by f.feature_id'];
    query2 = ['SELECT f.feature_id FROM features f JOIN experiment_features ef ON f.feature_id = ef.feature_id where experiment_id = ' num2str(experiment_id)];
else
    query = ['SELECT f.feature_id FROM features f JOIN '...
            '(SELECT feature_id FROM feature_training_models WHERE training_model_id = ' num2str(model_id) ') '...
            'dt ON f.parent_feature_id = dt.feature_id ORDER BY f.feature_id'];
    query2 = ['SELECT feature_id FROM feature_training_models WHERE training_model_id = ' num2str(model_id)];
end

active_features = sql_query(conn,query);
active_features2 = sql_query(conn,query2);
active_features = union(active_features,active_features2);

if strcmp(active_features,'No Data')
    error('No features found!')
end
