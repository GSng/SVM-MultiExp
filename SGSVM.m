function [w W] = SGSVM(X, y, w, C, eN, k, maxTime)
% PEGASOS: primal estimated subgradient solver for SVM
% by Shalev-Shwarz, Singer, Srebro

%%% size(X) = (nfeats, ntrain)
%%% size(y) = (ntrain, 1)   - elements equal to -1 or 1

% SVM in primal
% min  lambda/2 * w'*w  + hingeloss(X,y)

% lambda  regularization parameter (1/C)
% T number of iterations
% k size of subgradient sampling sets

m = size(X,1);
n = size(X,2);

if nargin<6
    maxTime = 4000;
end

if k<=1
    sample_rate = 10/10^(round(log10(k)));
    k = ceil(k*n);
else
    sample_rate = 10^round(log10(10/(k/n)));
end

if C<n
    C=C*n;
end

lambda = 1/C;
if length(w)~=m
    w = rand(m,1)-1/2;
    w = w/norm(w);
    w = w/(2 * sqrt(lambda));
end

if isscalar(eN) && eN>4
    stop_condition=1;    
    I = eN; clear eN;
else
    stop_condition=2;
    eCount = 0;
    e = eN(1);
    L = length(e);
    
    n_window = 10;
    if L>1
        n_window = eN(2);
    end
    
    n_steady_state = 10;
    if L>2
        n_steady_state = eN(3);
    end
    
    if L>3
        sample_rate = eN(4);
    end
    clear eN;
end

STOP = 0;
s=0;
W = zeros(1,2+m);

i = 1;
j = 2;
tic
while STOP==0
   
    %RANDOM SUBSET OF TRAINING POINTS FOR COMPUTING THE STOCHASTIC SUBGRADIENT
    
    A = floor(rand(k,1) * n) + 1;
    
    nu = 1/(lambda * (i+1));
    X1 = X(:,A);
    y1 = y(A);
    ind = logical(y1.* (w'* X1)'  < 1);
    if (max(ind) == false) continue, end
    
    w2 = (1 - nu * lambda) * w + nu/k *( X1(:, ind) * y1(ind));
    
    %PROJECTING THE CURRENT SOLUTION ON TO A BALL
    
    wn = 1/(norm(w2)*sqrt(lambda));
   
    if (1 < wn)
        w = w2;
    else
        w = wn * w2;
    end     
    
    switch stop_condition
        case 1
            STOP = (i>I);
            if i==1 || mod(i,sample_rate)==0       
                W(j,:) = [i toc w'];
                j=j+1;
            end
        case 2
            if i==1 || mod(i,sample_rate)==0                
                W(j,:) = [i toc w'];
                s(j,1) = norm(w,2); %(W(j,2:end)'-W(j-1,2:end)'),1);                
                if  j > n_window
                    sdiff = diff(s((j-n_window):j),1);
                    stopf = abs(std(sdiff)/mean(sdiff));             
                    eCount = (eCount+(stopf<e))*(stopf<e);
                    STOP = eCount > n_steady_state;
                end
                j=j+1;
            end
    end
    
    if (toc > maxTime)
        STOP=1;
        W(j+1,:) = [i toc w'];
    end
    i=i+1; 
end
clear i

W = W(2:end,:);

try
    x=X';
    numerator_count = ceil(0.1*n);
    for i = 1:size(W,1);
        test_scores = x*W(i,3:end)';
        [sorted_test_scores sorted_index] = sort(test_scores,'descend');
        sorted_real_labels = y(sorted_index);
        accuracy(i,1) = 100*length(find(sorted_real_labels(1:numerator_count)==1))/numerator_count;    
        clear test_scores sorted_test_scores sorted_index sorted_real_labels
    end
    [jk W_i] = max(accuracy);
    w = W(W_i,3:end)';
catch
    keyboard;
end