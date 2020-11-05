function [] = ERP_Plots(trials, trialavg, plotx, clusterpos)
%ERP_PLOTS - Plots results of the ERP analysis
% Specifically:
% - Voltage plot for all channels and channel mean
% - Topoplots of voltage changes around scalp mean in the illusion condition
% - Topoplots of voltage changes around scalp mean in the control condition
% - Topoplots of voltage contrast between the illusion and control condition
%
% Syntax:  [] = ERP_Plots(trials, trialavg, plotx, clusterpos, signif)
%
% Inputs:
%    trials (struct) - contains the ERP trials from ERP_Run.m
%    trialavg (struct) - contains the subject-averaged ERP trials from ERP_Run.m
%    plotx (array [subjects x channels x time points]) - trials in array
%                                                        structure
%    clusterpos (array [n x 2]) - start and end sample of significant
%                                 clusters
%
% Outputs:
%    none
%
% Example: 
%    [] = ERP_Plots(trials, trialavg, plotx, clusterpos)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Christoph Schneider
% Acute Neurorehabilitation Unit (LRNA)
% Division of Neurology, Department of Clinical Neurosciences
% Centre Hospitalier Universitaire Vaudois (CHUV)
% Rue du Bugnon 46, CH-1011 Lausanne, Switzerland
%
% email: christoph.schneider.phd@gmail.com 
% November 2020
%------------- BEGIN CODE --------------

%% plot grand average ERPs with topographic channel arrangement

% set plotting parameters
plotpos = [3,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
elpos = {'Fz', 'FC3', 'FC2', 'FCz', 'FC2', 'FC4', 'C3', 'C1', 'Cz', 'C2' ,'C4', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4'};
time = trials(1).illusion.time + 1;
yl = [-12, 12];     % y-axis figure limits

figure;

% plot single channels
cmap = colormap('lines');
for ch =  1:16
    subplot(5,5,plotpos(ch))
    boundedline(time,squeeze(mean(plotx.illusion(:,ch,:),1)),squeeze(std(plotx.illusion(:,ch,:),[],1))/sqrt(numel(trialavg)) ,'alpha', 'cmap', cmap(1,:));
    hold on;
    boundedline(time,squeeze(mean(plotx.control(:,ch,:),1)),squeeze(std(plotx.control(:,ch,:),[],1))/sqrt(numel(trialavg)) ,'alpha', 'cmap', cmap(2,:));
    vline(0,'k');
    vline(1,'k:');
    vline(2,'k:');
    vline(3,'k');
    title(elpos(ch))
    xlim([time(1), time(end)])
    ylim(yl)
    set(gca, 'YDir','reverse')
    if ch == 1
        xlabel('Time [s]')
        ylabel('Amplitude [µV]')
    else
        xticklabels({})
        yticklabels({})
    end
end

% plot legend
subplot(4,5,1)
p_1 = plot(1,1);
hold on;
p_2 = plot(1,1);
plot(1,1,'Color',[1,1,1]);
legend([p_1, p_2],{'illusion','control'})
axis off

% plot channel mean
subplot(5,5,22:24)
boundedline(time,squeeze(mean(mean(plotx.illusion,2),1)),squeeze(std(mean(plotx.illusion,2),[],1))/sqrt(numel(trialavg)) ,'alpha', 'cmap', cmap(1,:));
hold on;
boundedline(time,squeeze(mean(mean(plotx.control,2),1)),squeeze(std(mean(plotx.control,2),[],1))/sqrt(numel(trialavg)) ,'alpha', 'cmap', cmap(2,:));
vline(0,'k');
vline(1,'k:');
vline(2,'k:');
vline(3,'k');
xlabel('Time [s]')
ylabel('Amplitude [µV]')
title('channel mean')
xlim([time(1), time(end)])
ylim(yl)
set(gca, 'YDir','reverse')
% draw gray rectangel to highlight the significant cluster permutation part
for cl = 1:size(clusterpos,1)
    rectangle('Position',[time(clusterpos(cl,1)),yl(1),time(clusterpos(cl,2)) - time(clusterpos(cl,1)),yl(2)-yl(1)],...
        'FaceColor', [0, 0, 0, 0.1], ...
        'EdgeColor', [0, 0, 0, 0.1]);
end

%% topoplots

% subtract mean activity from all channels to see topological differences
% over time up to 1 second post vibration start (encompassing significant window)
E.i = mean( plotx.illusion - repmat(mean(plotx.illusion,2),1,16,1), 1);
E.c = mean( plotx.control - repmat(mean(plotx.control,2),1,16,1), 1);

% set parameters for topoplot
cfg = [];
cfg.marker       = 'on';
cfg.elec          = 'standard_1020.elc';
cfg.comment = 'no';
tmp = trialavg(1).illusion;
tmp.time = time;
tmp = rmfield(tmp,'dof');
tmpcfg = keepfields(cfg, {'layout', 'rows', 'columns', 'commentpos', 'scalepos', 'elec', 'grad', 'opto', 'showcallinfo'});
cfg.layout = ft_prepare_layout(tmpcfg, tmp);
cfg.layout.pos = cfg.layout.pos * 0.8;


% topoplot for illusion condition
figure;
tmp.avg = E.i;
xlimits = [-0.5,0:0.1:0.8;0:0.1:0.9];
for k = 1:10
    subplot(2,5,k)
    cfg.xlim = xlimits(:,k)';
    cfg.zlim = [-1.5, 1.5];
    cfg.style              = 'straight';
    ft_topoplotER(cfg, tmp); title([num2str(xlimits(1,k)),' - ',num2str(xlimits(2,k)),' s']);
    colormap(redblue)
    if k == 1
        c = colorbar('south');
        c.Ruler.TickLabelFormat='%g uV';
    end
end
suptitle('Voltage distribution around mean: illusion condition');
colormap(redblue)

% topoplot for control condition
figure;
tmp.avg = E.c;
xlimits = [-0.5,0:0.1:0.8;0:0.1:0.9];
for k = 1:10
    subplot(2,5,k)
    cfg.xlim = xlimits(:,k)';
    cfg.zlim = [-1.5, 1.5];
    cfg.style              = 'straight';
    ft_topoplotER(cfg, tmp); title([num2str(xlimits(1,k)),' - ',num2str(xlimits(2,k)),' s']);
    colormap(redblue)
    if k == 1
        c = colorbar('south');
        c.Ruler.TickLabelFormat='%g uV';
    end
end
suptitle('Voltage distribution around mean: control condition');
colormap(redblue)

% topoplot for contrast between conditions; note different z-axis!
figure;
tmp.avg = E.i - E.c;
xlimits = [-0.5,0:0.1:0.8;0:0.1:0.9];
for k = 1:10
    subplot(2,5,k)
    cfg.xlim = xlimits(:,k)';
    cfg.zlim = [-0.5, 0.5];
    cfg.style              = 'straight';
    ft_topoplotER(cfg, tmp); title([num2str(xlimits(1,k)),' - ',num2str(xlimits(2,k)),' s']);
    colormap(redblue)
    if k == 1
        c = colorbar('south');
        c.Ruler.TickLabelFormat='%g uV';
    end
end
suptitle('Voltage distribution around mean: contrast between conditions');
colormap(redblue)

