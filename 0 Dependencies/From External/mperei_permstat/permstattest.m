function [ signif,fpos,nsignif ] = permstattest( variables,nrep,pthr,pclust,testtype,tail,output)
%permstattest Outputs significance maps, corrected for multiple comparisons
%using Maris and Oostenveld (2007), Nonparametric statistical testing of EEG- and MEG-data, Journal of Neuroscience Methods 
%   The function estimates a null distribution by permuting the data (for
%   two variables) or permuting the sign (for one variable) and compares
%   the clusters in the data to to the null distribution
%   Input arguments
%       * variables: input variable(s) to test. If a 2 item cell array is supplied, a
%       cluster-based permutation test will be done by shuffling the
%       classes from both cells. If a matrix is supplied, the function will do a 
%       sign-permutation cluster test. As for the ttest function, the first
%       dimension should be the trials or subjects. Example for time frequency
%       maps of size 256x30, 26 subjects and 2 conditions, a cell of two
%       26x256x30 matrices would be provided. If there is only one
%       condition, one matrix of 26x256x30 should be provided.
%       * nrep: the number of repetitions to estimate the null distribution
%       (default: 1000).
%       * pthr: the threshold of significance (default: 0.05).
%       * pclust: the threshold for defining the cluster (default: 0.05,
%       but must not necessarily be < 0.05 ... if you're good at convincing
%       reviewers).
%       * testtype: can be 'ttest','ttest2' (for single-subject
%       analysis) or 'ranksum' for nonparametric testing.
%       * tail: default is 0, can be set to -1 or 1 for one-tail tests (if
%       you have a strong a-priory reason of doing that). Set to -1 to test
%       var1 < 0 or var1 < var2 and to 1 to test var1 > 0 or var1 > var2.
%       * output: set to 0 for no output, to 1 to only have the kickass
%       progress bar, to 2 to display the cluster that are kept, to 3 to
%       also display the clusters that are not significant
%   Output arguments
%       * signif: a binary map of significance.
%       * fpos: a binary map of (pclust) significance without the
%       correction.
%       * nsignif: the number of significant clusters
%      
if nargin < 7
    output = 2;
end
if nargin < 6
   tail = 0; 
end
if nargin < 5
   testtype = 'ttest'; 
end
if ~any(strcmp(testtype,{'ttest','ttest2','ranksum'}))
   error('Test type should be either ttest or ttest2');
end
if strcmp(testtype,'ttest2') && ~iscell(variables)
   error('I cannot apply a two-sample ttest on one variable');
end
if nargin < 4
    pclust = 0.05;    
end
if nargin < 3
    pthr = 0.05;
end
if nargin < 2
    nrep = 1000;
end
fprintf('Repeating %d permutations, p(cluster)=%.3f, p(adjusted)=%.3f\n',nrep,pclust,pthr);

% Get test statistics
if iscell(variables)
    if strcmp(testtype,'ttest')
        [~,p,~,stat_] = ttest(variables{1},variables{2});
    elseif strcmp(testtype,'ttest2')
        [~,p,~,stat_] = ttest2(variables{1},variables{2});
    elseif strcmp(testtype,'ranksum')
        p = NaN(1,size(variables{1},2));
        stat = p;
        parfor i = 1:size(variables{1},2)
        [p(i),~,stx] = ranksum(variables{1}(:,i),variables{2}(:,i));
        stat(i) = stx.ranksum;
        end
        stat_.tstat = stat;
    end
else
    [~,p,~,stat_] = ttest(variables);
end

% Cluster the data (works also for 1D)
[ tsum,clusters ] = permstatclust( squeeze(stat_.tstat),squeeze(p),pclust );

% Estimate the null distribution
if iscell(variables)
    [ tperm_min,tperm_max ] = permstatnull2(variables{1},variables{2},nrep,pclust,testtype,output);    
else
    [ tperm_min,tperm_max ] = permstatnull1(variables,nrep,output);
end

if iscell(variables)
    % pre-allocate significance mask
    signif = false(size(variables{1},2),size(variables{1},3));
    % and also false positives
    fpos = false(size(variables{1},2),size(variables{1},3));
else
    % pre-allocate significance mask
    signif = false(size(variables,2),size(variables,3));
    % and also false positives
    fpos = false(size(variables,2),size(variables,3));
end

if tail==0
    % two-tailed
    qmax = 1-pthr/2;
    qmin = pthr/2;  
elseif tail == -1
    % one tailed < 
    qmax = 1;
    qmin = pthr;    
elseif tail == 1
    % one tailed >
    qmax = 1-pthr;
    qmin = 0;      
end
nsignif = 0;
% Loop through the clusters
for cl=1:length(clusters)
    if (tsum(cl) > quantile(tperm_max,qmax)) || (tsum(cl) < quantile(tperm_min,qmin))
        % clusters significantly different from the null distribution
        signif(clusters{cl}.idx) = 1;
        nsignif = nsignif+1;
        if output >= 2
            fprintf('=== KEEP Cluster %d: tsum=%.1f [%.1f,%.1f],\n',cl,tsum(cl),quantile(tperm_max,1-pthr),quantile(tperm_min,pthr));
            fprintf('\n');
        end
    else
            % false positive clusters
        fpos(clusters{cl}.idx) = 1;
        if output >= 3
            fprintf('--- DEL Cluster %d: tsum=%.1f [%.1f,%.1f],\n',cl,tsum(cl),quantile(tperm_max,1-pthr),quantile(tperm_min,pthr));
            fprintf('\n');
        end
    end
end

end

