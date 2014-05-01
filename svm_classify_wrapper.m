function claim_id_score_mat = svm_classify_wrapper(classfication_model_id,model_statistic_id,flag,start_condition,end_condition,conn)



while 1
    if isempty(classfication_model_id)
        claim_id_score_mat = svm_classify_claims_with_training_model_statistics(conn,model_statistic_id,flag,start_condition,end_condition);
    else
        claim_id_score_mat = svm_classify_claims_with_multiple_models(conn,classfication_model_id,condition);
    end
end