% 1 dimension

clear 
nrep = 1000; 
pthr = 0.05;
pclust = 0.05;
nsubj = 26;
n = 1000;
figure(1); clf;
signal = zeros(1,n);
signal(101:200) = 0.5;

% We create surrogate data by smoothing 2d maps with a gaussian kernel for
% each of the subjects
h_ = fspecial('gaussian',[101,101],5);
h = h_(:,51);
for s=1:nsubj
    X1(s,:) = filter(h,1,randn(1,n));
    X2(s,:) = filter(h,1,randn(1,n));
end
%% Two variables

% First we use a signal with a subject-wise bias but no signal
X1p = bsxfun(@plus,X1,linspace(-5,5,nsubj).');
X2p = bsxfun(@plus,X2,linspace(-5,5,nsubj).');

subplot(3,2,1); hold on;
[ signifA,fposA ] = permstattest( {X1p,X2p},nrep,pthr,pclust,'ttest',0,2);
dif = squeeze(mean(X1p-X2p,1));
stdplot(X1p-X2p,'k');
dif(~fposA) = NaN;
plot(dif,'r.-','LineWidth',2);
dif = squeeze(mean(X1p-X2p,1));
dif(~signifA) = NaN;
plot(dif,'g-','LineWidth',2);
title('Paired T-test with no signal','FontSize',14);
pause(0.1);

% Now we add the signal
X2ps = bsxfun(@plus,X2p,signal);

subplot(3,2,2); hold on;
[ signifB,fposB ] = permstattest( {X1p,X2ps},nrep,pthr,pclust,'ttest',0,2);
dif = squeeze(mean(X1p-X2ps,1));
stdplot(X1p-X2ps,'k');
dif(~fposB) = NaN;
plot(dif,'r.-','LineWidth',2);
dif = squeeze(mean(X1p-X2ps));
dif(~signifB) = NaN;
plot(dif,'g-','LineWidth',2);
title('Paired T-test with signal','FontSize',14);
pause(0.1);

%% One variable 

% we compare the first variable to zero, should be nothing
subplot(3,2,3); hold on;
[ signifB,fposB ] = permstattest( X1p,nrep,pthr,pclust,'ttest',0,2);
dif = squeeze(mean(X1p,1));
stdplot(X1p,'k');
dif(~fposB) = NaN;
plot(dif,'r.-','LineWidth',2);
dif = squeeze(mean(X1p,1));
dif(~signifB) = NaN;
plot(dif,'g-','LineWidth',2);
title('One-sample T-test with no signal','FontSize',14);
pause(0.1);

% now we use the signal without the subject bias
X2s = bsxfun(@plus,X2,signal);
subplot(3,2,4); hold on;
[ signifB,fposB ] = permstattest( X2s,nrep,pthr,pclust,'ttest',0,2);
dif = squeeze(mean(X2s,1));
stdplot(X2s,'k');
dif(~fposB) = NaN;
plot(dif,'r.-','LineWidth',2);
dif = squeeze(mean(X2s,1));
dif(~signifB) = NaN;
plot(dif,'g-','LineWidth',2);
title('One-sample T-test with signal','FontSize',14);

%% Two-sampled 

% we try with a two-sample t-test, we shouldn't see anything
subplot(3,2,5); hold on;
[ signifB,fposB ] = permstattest( {X1p,X2ps},nrep,pthr,pclust,'ttest2');
dif = squeeze(mean(X1p-X2ps,1));
stdplot(X1p-X2ps,'k');
dif(~fposB) = NaN;
plot(dif,'r.-','LineWidth',2);
dif = squeeze(mean(X1p-X2ps,1));
dif(~signifB) = NaN;
plot(dif,'g-','LineWidth',2);
title('Two-sample T-test with *paired* signal','FontSize',14);
pause(0.1);



subplot(3,2,6); hold on;
[ signifB,fposB ] = permstattest( {X1,X2s},nrep,pthr,pclust,'ttest2');
dif = squeeze(mean(X1-X2s,1));
stdplot(X1-X2s,'k');
dif(~fposB) = NaN;
plot(dif,'r.-','LineWidth',2);
dif = squeeze(mean(X1-X2s,1));
dif(~signifB) = NaN;
plot(dif,'g-','LineWidth',2);
title('Two-sample T-test with signal','FontSize',14);

% 2 dimension
% X1 = randn([26,100,100]);
% X2 = randn([26,100,100]);
