function model_out = sofia_run_training(workingdir,dimensionality,learner_type, loop_type, lambda, iterations, training_file, model_out, model_in)

buffer_mb = '256';
if isnumeric(dimensionality)
    dimensionality = num2str(dimensionality);
end

currendirectory = pwd;
cd('E:\cygwin\bin');
training_file = strrep(training_file,'E:/','/cygdrive/e/');

if nargin<9
    model_out2 = strrep(model_out,'E:/','/cygdrive/e/');
    
    eval(['!' workingdir 'svm_run_multi_exp/sofia-ml.exe'...
          ' --training_file ' training_file...
          ' --model_out ' model_out2...
          ' --buffer_mb ' char(buffer_mb)...
          ' --dimensionality ' char(dimensionality)...
          ' --learner_type ' char(learner_type)...
          ' --loop_type ' char(loop_type)...
          ' --lambda ' char(lambda)...
          ' --iterations ' char(iterations)]);    
else
    FLAG=0;
    if strcmpi(model_out,model_in)
        [pathstr name ext] = fileparts(model_out);
        model_out = strcat(pathstr,'/',name,'_2',ext);
        FLAG=1;
    end        
    model_out2 = strrep(model_out,'E:/','/cygdrive/e/');
    model_in2 = strrep(model_in,'E:/','/cygdrive/e/');

    eval(['!' workingdir 'svm_run_multi_exp/sofia-ml.exe'...
          ' --training_file ' training_file...
          ' --model_in ' model_in2...
          ' --model_out ' model_out2...
          ' --buffer_mb ' char(buffer_mb)...
          ' --dimensionality ' char(dimensionality)...
          ' --learner_type ' char(learner_type)...
          ' --loop_type ' char(loop_type)...
          ' --lambda ' char(lambda)...
          ' --eta_type constant'...
          ' --iterations ' char(iterations)]);
     
      if FLAG
         copyfile(model_out,model_in,'f');
         model_out = model_in;
      end
end

cd(currendirectory);