% 2 dimension

clear 
nrep = 1000; 
pthr = 0.05;
pclust = 0.05;
nsubj = 26;
n1 = 30;
n2 = 100;

figure(1); clf;
signal = zeros(1,n1,n2);
signal(1,4:8,11:20) = 1;

% We create surrogate data by smoothing 2d maps with a gaussian kernel for
% each of the subjects
h = fspecial('gaussian',[15,15],3);
for s=1:nsubj
    X1(s,:,:) = imfilter(randn([n1,n2]),h,'replicate');
    X2(s,:,:) = imfilter(randn([n1,n2]),h,'replicate');
end
%% Two variables


[ signifA,fposA ] = permstattest( {X1,X2},nrep,pthr,pclust,'ttest',0,2);
dif = squeeze(mean(X1-X2,1));
subplot(2,2,1); hold on;
imagesc(dif);
contour(squeeze(fposA),'r-','LineWidth',1);
contour(squeeze(signifA),'g-','LineWidth',1);
title('Paired T-test with no signal','FontSize',14);
caxis([-0.1,0.1])
pause(0.1);

% Now we add the signal
X2s = bsxfun(@plus,X2,signal);
[ signifA,fposA ] = permstattest( {X1,X2s},nrep,pthr,pclust,'ttest',0,2);
dif = squeeze(mean(X1-X2s,1));
subplot(2,2,2); hold on;
imagesc(dif);
contour(squeeze(fposA),'r-','LineWidth',1);
contour(squeeze(signifA),'g-','LineWidth',1);
title('Paired T-test with signal','FontSize',14);
pause(0.1);

% One-sample ttest without signal
[ signifA,fposA ] = permstattest( X1,nrep,pthr,pclust,'ttest',0,2);
dif = squeeze(mean(X1,1));
subplot(2,2,3); hold on;
imagesc(dif);
contour(squeeze(fposA),'r-','LineWidth',1);
contour(squeeze(signifA),'g-','LineWidth',1);
title('One sample T-test with no signal','FontSize',14);
pause(0.1);

% One-sample ttest with signal
[ signifA,fposA ] = permstattest( X2s,nrep,pthr,pclust,'ttest',0,2);
dif = squeeze(mean(X2s,1));
subplot(2,2,4); hold on;
imagesc(dif);
contour(squeeze(fposA),'r-','LineWidth',1);
contour(squeeze(signifA),'g-','LineWidth',1);
title('One sample T-test with no signal','FontSize',14);
pause(0.1);