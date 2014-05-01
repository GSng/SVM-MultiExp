function model_file = svm_perf_run_training(workingdir, train_file, model_file, c_value, e_value, l_value, w_value, t_value, DGSR)

if nargin<8
    t_value = 0;
end

if isnumeric(c_value)
    c_value = num2str(c_value);
end
if isnumeric(e_value)
    e_value = num2str(e_value);
end
if isnumeric(l_value)
    l_value = num2str(l_value);
end
if isnumeric(w_value)
    w_value = num2str(w_value);
end

currendirectory = pwd;

cd('E:\cygwin\bin');
train_file = strrep(train_file,'E:/','/cygdrive/e/');
model_file = strrep(model_file,'E:/','/cygdrive/e/');

switch t_value
    case 0
        eval_str = ['!' workingdir 'svm_run_multi_exp/svm_perf_learn.exe -v 0 -c ' (c_value) ' -e ' (e_value) ' -l ' (l_value) ' -w ' (w_value)...
                    ' ' train_file ' ' model_file];    
    case 1
        eval_str = ['!' workingdir 'svm_run_multi_exp/svm_perf_learn.exe -v 0 -c ' (c_value) ' -e ' (e_value) ' -l ' (l_value) ' -w ' (w_value)...
                    ' --t 1 --b 0 --k 500 -d ' num2str(DGSR(1)) ' ' train_file ' ' model_file];                   
    case 2
        eval_str = ['!' workingdir 'svm_run_multi_exp/svm_perf_learn.exe -v 0 -c ' (c_value) ' -e ' (e_value) ' -l ' (l_value) ' -w ' (w_value)...
                    ' --t 1 --b 0 --k 500 --i 2 -g ' num2str(DGSR(1)) ' ' train_file ' ' model_file];
    case 3
        eval_str = ['!' workingdir 'svm_run_multi_exp/svm_perf_learn.exe -v 0 -c ' (c_value) ' -e ' (e_value) ' -l ' (l_value) ' -w ' (w_value)...
                    ' --t 1 --b 0 --k 500 -s ' num2str(DGSR(1)) ' -r ' num2str(DGSR(2)) ' ' train_file ' ' model_file];
end

eval(eval_str)

cd(currendirectory);
        
        
        
