function [ tsum,clusters ] = permstatclust( tstat,p,pthr )
%CLUSTERTSTAT2D Clusters statistics based on the corresponding p-value
%   Input variables:
%       * tstat: the test statistic (can be 1D or 2D)
%       * p: the corresponding p-values (I'm not going to compute them!)
%       * pthr: the p-value threshold for clustering
%   Output variables:
%       * tsum: a vector of sum of test statistics corresponding to each
%       cluster
%       * clusters: a cell array of structs for each cluster containing the
%       significant indices and the sum of test statistics

% Clustering (p<0.05)
permclust = bwconncomp(p < pthr);

% Pre-allocate
clusters = cell(permclust.NumObjects,1);
tsum = zeros(1,permclust.NumObjects);
%tsize = zeros(1,permclust.NumObjects);

for c = 1:permclust.NumObjects
    % For every cluster, sum up t-test statistic for every pixel
    tsum(c) = sum(tstat(permclust.PixelIdxList{c}));
    % Store the indices
    clusters{c}.idx = permclust.PixelIdxList{c};
    % Store the size also (just because we can)
    % tsize(c) = length(permclust.PixelIdxList{c});
    clusters{c}.tsum = tsum(c);
end
end

