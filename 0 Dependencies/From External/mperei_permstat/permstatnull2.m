function [ tperm_min,tperm_max] = permstatnull2( var1,var2,nrand,pclust,testtype,output)
%permstatnull2 Estimates the null distribution of differences between var1 and
%var2
%   Input variables:
%       * var1,var2: the two variables to be compared (should be NxK1xK2,
%       where N is the number of subjects or trials and K2 could be 1)
%       * nrand: the number of permutations (default: 1000)
%       * pclust: the p-value threshold for clustering
%       * testtype: whether to apply paired (ttest) or two-sample (ttest2)
%       or Wilcoxon-ranksum (ranksum)
%       * output: set to 0 to remove anoying progress bar
%   Output variables:
%       * tmin: the null distribution of minimum values
%       * tmax: the null distribution of maximum values
if (nargin < 6)
    output = 1;
end
if (nargin < 5) || isempty(testtype);
    testtype = 'ttest';
end
if (nargin < 4 ) || isempty(pclust)
    pclust = 0.05;
end
if (nargin < 3 ) || isempty(nrand)
    nrand = 1000;
end

[nsamp1,n1a,n1b] = size(var1);
[nsamp2,n2a,n2b] = size(var2);

if (n1a ~= n2a) || (n1b ~= n2b)
    error('2nd and 3rd dimension should be identical between the two variables');
end
if (nsamp1 ~= nsamp2) && strcmp(testtype,'ttest')
    error('When using paired ttest, you need the same number of trials/subjects in each condition');
end

if output
    fprintf('BOOTSTRAP: #c1=%d, #c2=%d - n= [%dx%d] - repeat: %d)',nsamp1,nsamp2,n1a,n1b,nrand);
    fprintf('completed: |          |');%fprintf('\b\b\b\b\b\b\b\b\b\b\b\b');
end
tperm_min = zeros(1,nrand);
tperm_max = zeros(1,nrand);

for r=1:nrand
    % smart-ass fancy output
    if (mod(r,nrand/10)==1) && output
        rperc = ceil(r/nrand*10);
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('|');
        for j=1:10
            if j<=rperc
                fprintf('=');
            else
                fprintf(' ');
            end
        end
        fprintf('|');
    end
    
    
    perm = randperm(nsamp1+nsamp2);
    alldata = [var1 ; var2];
    lab = [zeros(1,nsamp1) ones(1,nsamp2)];
    lab = lab(perm);
    if strcmp(testtype,'ttest')
        % paired ttest
        [~,p_,~,stat_] = ttest(alldata(lab==0,:,:),alldata(lab==1,:,:));
    elseif strcmp(testtype,'ttest2')
        % two-sample ttest
        [~,p_,~,stat_] = ttest2(alldata(lab==0,:,:),alldata(lab==1,:,:));
    elseif strcmp(testtype,'ranksum')
        % Wilcoxon rank sum test
        p_ = NaN(1,size(alldata,2));
        stat = p_;
        parfor i = 1:size(alldata,2)
            [p_(i),~,stx] = ranksum(alldata(lab==0,i,:),alldata(lab==1,i,:));
            stat(i) = stx.ranksum;
        end
        stat_.tstat = stat;
    else
        error('Test type can only be ttest, ttest2 or ranksum, or you implement it');
    end
    
    tpermsum = permstatclust( squeeze(stat_.tstat),squeeze(p_),pclust );
    if ~isempty(tpermsum)
        tperm_min(r) = min(tpermsum);
        tperm_max(r) = max(tpermsum);
    else
        tperm_min(r) = min(stat_.tstat(:)); % we could put also 0 or NaN...
        tperm_max(r) = max(stat_.tstat(:)); % we could put also 0 or NaN...
    end
    
    
end
if output
    fprintf('\n');
end
end

