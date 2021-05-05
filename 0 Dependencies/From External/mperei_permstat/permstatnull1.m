function [ tperm_min,tperm_max ] = permstatnull1( var,nrand,pclust,output)
%permstatnull1 Estimates the null distribution of differences between var and
%zero
%   Input variables:
%       * var: the variable to be compared (should be NxK1xK2,
%       where N is the number of subjects or trials and K2 could be 1)
%       * nrand: the number of permutations (default: 1000)
%       * pclust: the p-value threshold for clustering
%       * output: set to 0 to remove anoying progress bar
%   Output variables:
%       * tmin: the null distribution of minimum values
%       * tmax: the null distribution of maximum values


if (nargin < 4)
    output = 1;
end
if (nargin < 3) || isempty(pclust)
    pclust = 0.05;
end
if (nargin < 2 ) || isempty(nrand)
    nrand = 1000;
end

tperm_min = zeros(1,nrand);
tperm_max = zeros(1,nrand);

[nsamp1,n1a,n1b] = size(var);

if output
    fprintf('BOOTSTRAP: #c1=%d, #c2=none - n= [%dx%d] - repeat: %d)',nsamp1,n1a,n1b,nrand);
    fprintf('completed: |          |');%fprintf('\b\b\b\b\b\b\b\b\b\b\b\b');
end
for r=1:nrand
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

    sign = round(rand(1,nsamp1))*2-1;
    newfactor = bsxfun(@times,var,sign.');
    [~,p_,~,stat_] = ttest(newfactor,[]);
    
    tpermsum = permstatclust( squeeze(stat_.tstat),squeeze(p_),pclust );
    if ~isempty(tpermsum)
        tperm_min(r) = min(tpermsum);
        tperm_max(r) = max(tpermsum);
    else
        tperm_min(r) = min(stat_.tstat(:)); % we could put also 0 or NaN... 
        tperm_max(r) = max(stat_.tstat(:)); % we could put also 0 or NaN... 
    end
    
     
end

%tmin = quantile(tsampmin,bpthr/2);
%tmax = quantile(tsampmax,1-bpthr/2);
%stat.tsampmin = tsampmin;
%stat.tsampmax = tsampmax;
if output
    fprintf('\n');
end
end

