function [] = PSD_Plots(spect, time, freqvec)
%PSD_PLOTS - Displays results of time-frequency analysis in plots
% Specifically:
% - Time-frequency plot of illusion condition
% - Time-frequency plot of control condition
% - Time-frequency plot of contrast (illusion - control)
% - Contrast topoplots of alpha and beta band averaged across trial duration
% - Contrast topoplots of alpha band windowed across trial duration
% - Contrast topoplots of beta band windowed across trial duration
%
% Syntax:  [] = PSD_Plots(spect, time, freqvec)
%
% Inputs:
%    spect (struct) - contains the PSD values from PSD_Run.m
%    time (vector) - time points corresponding to the PSD values
%    freqvec (vector) - frequency points corresponding to the PSD values
%
% Outputs:
%    none
%
% Example:
%    [] = PSD_Plots(spect, time, freqvec);
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
% May 2021
%------------- BEGIN CODE --------------

bsltime = time <= 0;

%% compute ERD/ERS values for illusion (MI) and control (MC)
clear A R
for k = 1:numel(spect)
    A = spect(k).illusion.powspctrm;
    R = repmat( mean(spect(k).illusion.powspctrm(:,:,bsltime),3,'omitnan'), [1,1,size(A,3)]);
    MI(k,:,:,:) = (A - R) ./ R * 100;  %#ok<*AGROW>
end

clear A R
for k = 1:numel(spect)
    A = spect(k).control.powspctrm;
    R = repmat( mean(spect(k).control.powspctrm(:,:,bsltime),3,'omitnan'), [1,1,size(A,3)]);
    MC(k,:,:,:) = (A - R) ./ R * 100;
end

%% plot ERD/ERS for MI and MC
plotpos = [3,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
elpos = {'Fz', 'FC3', 'FC2', 'FCz', 'FC2', 'FC4', 'C3', 'C1', 'Cz', 'C2' ,'C4', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4'};
z1 = min( min(min(min(squeeze(mean(MI,1,'omitnan'))))), min(min(min(squeeze(mean(MC,1,'omitnan'))))) );
z2 = max( max(max(max(squeeze(mean(MI,1,'omitnan'))))), max(max(max(squeeze(mean(MC,1,'omitnan'))))) );
z = max(abs(z1), abs(z2));

figure('Units','normalized','Position',[0 0 1 1])
tiledlayout(4,5, 'Padding', 'none','TileSpacing','compact');
for ch =  1:16
    nexttile(plotpos(ch))
    s = pcolor(squeeze(mean(mean(MI(:,ch,:,:),2,'omitnan'),1,'omitnan'))); set(gca,'YDir','normal'); s.FaceColor = 'interp';set(s, 'EdgeColor', 'none');
    caxis([-z, z])
    set(gca,'ytick',10:10:length(freqvec),'yticklabels',{});
    set(gca,'xtick',11:20:length(time),'xticklabels',{});
    xline(find(time==0),'k','LineWidth',2);
    xline(find(time==1),'k:','LineWidth',2);
    xline(find(time==2),'k:','LineWidth',2);
    xline(find(time==3),'k','LineWidth',2);
    yline(7.5,'k-.','LineWidth',1.5)
    yline(12.5,'k-.','LineWidth',1.5)
    yline(30,'k-.','LineWidth',1.5)
    hold on;
    colormap(redblue)
    
    if ch == 1
        title('ERD/ERS illusion')
    else
        xticklabels({})
        yticklabels({})
    end
    text(3,11,'\alpha','FontSize',30,'FontWeight','bold')
    text(3,20,'\beta','FontSize',30,'FontWeight','bold')
    set(gca,'FontSize',30)
    
    %     cluster permutation to find significantly different frequency-time pairs
    [signif,~,~] = permstattest(squeeze(MI(:,ch,:,:)),1000,0.05,0.05,'ttest',0,3);
    contour(signif,1,'k','LineWidth',2)
end

figure
colormap(redblue)
ax = axes;
caxis([-z, z])
c = colorbar(ax,'Location','Southoutside');
c.Ruler.TickLabelFormat='%g%%';
ax.Visible = 'off';
set(gca,'FontSize',30)
%%
% --- for control trials only
figure('Units','normalized','Position',[0 0 1 1])
tiledlayout(4,5, 'Padding', 'none','TileSpacing','compact');
for ch =  1:16
    nexttile(plotpos(ch))
    s = pcolor(squeeze(mean(mean(MC(:,ch,:,:),2,'omitnan'),1,'omitnan'))); set(gca,'YDir','normal'); s.FaceColor = 'interp';set(s, 'EdgeColor', 'none');
    caxis([-z, z])
    set(gca,'ytick',10:10:length(freqvec),'yticklabels',{});
    set(gca,'xtick',11:20:length(time),'xticklabels',{});
    xline(find(time==0),'k','LineWidth',2);
    xline(find(time==1),'k:','LineWidth',2);
    xline(find(time==2),'k:','LineWidth',2);
    xline(find(time==3),'k','LineWidth',2);
    yline(7.5,'k-.','LineWidth',1.5)
    yline(12.5,'k-.','LineWidth',1.5)
    yline(30,'k-.','LineWidth',1.5)
    hold on;
    colormap(redblue)
    
    if ch == 1
        title('ERD/ERS control')
    else
        xticklabels({})
        yticklabels({})
    end
    text(3,11,'\alpha','FontSize',30,'FontWeight','bold')
    text(3,20,'\beta','FontSize',30,'FontWeight','bold')
    set(gca,'FontSize',30)
    
    % cluster permutation
    [signif,~,~] = permstattest(squeeze(MC(:,ch,:,:)),1000,0.05,0.05,'ttest',0,3);
    contour(signif,1,'k','LineWidth',2)
end

figure
colormap(redblue)
ax = axes;
caxis([-z, z])
c = colorbar(ax);
c.Ruler.TickLabelFormat='%g%%';
ax.Visible = 'off';
set(gca,'FontSize',30)

%% compute ERD/ERS contrast (MR) between illusion (MI) and control (MC)
MR = (MI - MC);
z1 = min(min(min(squeeze(mean(MR,1,'omitnan')))));
z2 = max(max(max(squeeze(mean(MR,1,'omitnan')))));
z = max(abs(z1), abs(z2));

%% plot ERD/ERS for MR

figure('Units','normalized','Position',[0 0 1 1])
tiledlayout(4,5, 'Padding', 'loose','TileSpacing','loose');

for ch =  1:16
    nexttile(plotpos(ch))
    s = pcolor(squeeze(mean(mean(MR(:,ch,:,:),2,'omitnan'),1,'omitnan'))); set(gca,'YDir','normal'); s.FaceColor = 'interp';set(s, 'EdgeColor', 'none');
    caxis([z1, z2])
    set(gca,'ytick',10:10:length(freqvec),'yticklabels',round(freqvec(10:10:length(freqvec))));
    set(gca,'xtick',11:20:length(time),'xticklabels',time(11:20:length(time)));
    xline(find(time==0),'k','LineWidth',2);
    xline(find(time==1),'k:','LineWidth',2);
    xline(find(time==2),'k:','LineWidth',2);
    xline(find(time==3),'k','LineWidth',2);
    yline(7.5,'k-.')
    yline(12.5,'k-.')
    yline(30,'k-.')
    hold on;
    colormap(redblue)
    text(38,34,elpos(ch),'FontWeight','bold','FontSize',25)

    if ch == 1
        xlabel('Time [s]')
        ylabel('Frequency [Hz]')
    else
        xticklabels({})
        yticklabels({})
    end
    text(3,11,'\alpha','FontSize',20,'FontWeight','bold')
    text(3,20,'\beta','FontSize',20,'FontWeight','bold')
    set(gca,'FontSize',20)
    
    % cluster permutation
    [signif,~,~] = permstattest(squeeze(MR(:,ch,:,:)),1000,0.05,0.05,'ttest',0,3);
    contour(signif,1,'k','LineWidth',2)
end
cb = colorbar;
cb.Ruler.TickLabelFormat='%g%%';
cb.Layout.Tile = 'east';

%% Topoplots

band.alpha = 8:12;
band.beta = 13:30;

% --- common parameters
cfg = [];
cfg.marker = 'on';
cfg.elec = 'standard_1020.elc';

tmp = spect(1).illusion;
tmpcfg = keepfields(cfg, {'layout', 'rows', 'columns', 'commentpos', 'scalepos', 'elec', 'grad', 'opto', 'showcallinfo'});
tmp.dimord = 'freq_chan_time';
tmp.freq = 1;
tmp.time = time;

cfg.comment = 'no';
cfg.layout = ft_prepare_layout(tmpcfg, tmp);
cfg.layout.pos = cfg.layout.pos * 0.8;
cfg.colormap = colormap(redblue);

% --- Grand averages (across time and subjects)
figure;
% mu band
subplot(1,2,1)
cfg.xlim         = [0   4];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.alpha,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title('Grand mu band average');
c = colorbar('south');
c.Ruler.TickLabelFormat='%g%%';
% beta band
subplot(1,2,2)
cfg.xlim         = [0   4];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.beta,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title('Grand beta band average');
c = colorbar('south');
c.Ruler.TickLabelFormat='%g%%';


% --- Grand averages per 1s window
figure;
% --- time points mu
subplot(2,6,2)
cfg.xlim         = [-0.5   0];
cfg.zlim         = [-6 6];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.alpha,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,3)
cfg.xlim         = [0   1];
cfg.zlim         = [-6 6];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.alpha,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,4)
cfg.xlim         = [1   2];
cfg.zlim         = [-6 6];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.alpha,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,5)
cfg.xlim         = [2   3];
cfg.zlim         = [-6 6];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.alpha,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,6)
cfg.xlim         = [3   4];
cfg.zlim         = [-6 6];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.alpha,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

% --- time points beta
subplot(2,6,8)
cfg.xlim         = [-0.5   0];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.beta,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,9)
cfg.xlim         = [0   1];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.beta,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,10)
cfg.xlim         = [1   2];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.beta,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,11)
cfg.xlim         = [2   3];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.beta,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,12)
cfg.xlim         = [3   4];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(mean(mean(MR(:,:,band.beta,:),3,'omitnan'),1,'omitnan'));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

% --- add text
subplot(2,6,1)
text(0,0.5,'mu band'); axis off

subplot(2,6,7)
text(0,0.5,'beta band'); axis off

sgtitle('Illusion - Control contrast ERD/ERS over time')
