function svm_classify_flagged_claims(conn,model_statistic_id,flag_num)

setdbprefs('DataReturnFormat','numeric');
FLAG = ['flag' int2str(flag_num)];

updatevalue = ['unclassified_model_' int2str(model_statistic_id)];
n_claims_to_be_scored = sql_query(conn,['SELECT COUNT(DISTINCT claim_id) FROM claims WHERE ' FLAG '=''' updatevalue '''']);

query = ['SELECT feature_id,weight FROM feature_training_model_weights WHERE model_statistic_id=',int2str(model_statistic_id),' ORDER BY feature_id ASC'];
feature_weights = sql_query(conn,query);

start_condition = updatevalue;
end_condition = ['classified_model_' int2str(model_statistic_id)];

for i=1:ceil(n_claims_to_be_scored/150000);
    svm_classify_claims_with_training_model_statistics(conn,model_statistic_id,FLAG,start_condition,end_condition,feature_weights);
    disp([int2str(i*150000) ' claims scored'])
end