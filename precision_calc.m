%function [PrecAt1 PrecAt2 PrecAt5 PrecAt10 PrecAt20] = calc_precision_metric(predictions, test_matrix)
function Prec = precision_calc(test_scores, test_labels, training_precisions)

[sorted_test_scores sorted_index] = sort(test_scores,'descend');                
sorted_real_labels = test_labels(sorted_index);
sorted_real_labels_logical = logical(sorted_real_labels > 0);

n_test = length(sorted_real_labels);          
numerator_count = ceil((1-(training_precisions(:,2)/100))*n_test);                
cumm_sorted_real_labels_logical = cumsum(sorted_real_labels_logical);

Prec = cumm_sorted_real_labels_logical(numerator_count,1)./numerator_count;

