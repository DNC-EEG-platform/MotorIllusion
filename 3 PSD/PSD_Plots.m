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
% November 2020
%------------- BEGIN CODE --------------

bsltime = time <= 0;

%% compute ERD/ERS values for illusion (MI) and control (MC)
clear A R
for k = 1:numel(spect)
    A = spect(k).illusion.powspctrm;
    R = repmat( nanmean(spect(k).illusion.powspctrm(:,:,bsltime),3), [1,1,size(A,3)]);
    MI(k,:,:,:) = (A - R) ./ R * 100;  %#ok<*AGROW>
end

clear A R
for k = 1:numel(spect)
    A = spect(k).control.powspctrm;
    R = repmat( nanmean(spect(k).control.powspctrm(:,:,bsltime),3), [1,1,size(A,3)]);
    MC(k,:,:,:) = (A - R) ./ R * 100; 
end

%% plot ERD/ERS for MI and MC
plotpos = [3,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
elpos = {'Fz', 'FC3', 'FC2', 'FCz', 'FC2', 'FC4', 'C3', 'C1', 'Cz', 'C2' ,'C4', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4'};
z1 = min( min(min(min(squeeze(nanmean(MI,1))))), min(min(min(squeeze(nanmean(MC,1))))) );
z2 = max( max(max(max(squeeze(nanmean(MI,1))))), max(max(max(squeeze(nanmean(MC,1))))) );
z = max(abs(z1), abs(z2));

% --- for illusion trials only
figure;
for ch =  1:16
    subplot(4,5,plotpos(ch))
    s = pcolor(squeeze(nanmean(nanmean(MI(:,ch,:,:),2),1))); set(gca,'YDir','normal'); s.FaceColor = 'interp';set(s, 'EdgeColor', 'none');
    caxis([-z, z])
    set(gca,'ytick',10:10:length(freqvec),'yticklabels',round(freqvec(10:10:length(freqvec))));
    set(gca,'xtick',11:20:length(time),'xticklabels',time(11:20:length(time)));
    vline(find(time==0),'k');
    vline(find(time==1),'k:');
    vline(find(time==2),'k:');
    vline(find(time==3),'k');
    hold on;
    colormap(redblue)
    title(elpos(ch))
    if ch == 1
        xlabel('Time [s]')
        ylabel('Frequency [Hz]')
    else
        xticklabels({})
        yticklabels({})
    end
    
    % cluster permutation to find significantly different frequency-time pairs
    [signif,~,~] = permstattest(squeeze(MI(:,ch,:,:)),1000,0.05,0.05,'ttest',0,3);
    contour(signif,1,'k','LineWidth',3)
end
subplot(4,5,1)
ax = axes;
caxis([-z, z])
c = colorbar(ax);
c.Ruler.TickLabelFormat='%g%%';
ax.Visible = 'off';

% --- for control trials only
figure;
for ch =  1:16
    subplot(4,5,plotpos(ch))
    s = pcolor(squeeze(nanmean(nanmean(MC(:,ch,:,:),2),1))); set(gca,'YDir','normal'); s.FaceColor = 'interp';set(s, 'EdgeColor', 'none');
    caxis([-z, z]) %caxis([z1, z2]) %
    set(gca,'ytick',10:10:length(freqvec),'yticklabels',round(freqvec(10:10:length(freqvec))));
    set(gca,'xtick',11:20:length(time),'xticklabels',time(11:20:length(time)));
    vline(find(time==0),'k');
    vline(find(time==1),'k:');
    vline(find(time==2),'k:');
    vline(find(time==3),'k');
    hold on;
    colormap(redblue)
    title(elpos(ch))
    if ch == 1
        xlabel('Time [s]')
        ylabel('Frequency [Hz]')
    else
        xticklabels({})
        yticklabels({})
    end
    
    [signif,~,~] = permstattest(squeeze(MC(:,ch,:,:)),1000,0.05,0.05,'ttest',0,3);
    contour(signif,1,'k','LineWidth',3)
end
subplot(4,5,1)
ax = axes;
caxis([-z, z])
c = colorbar(ax);
c.Ruler.TickLabelFormat='%g%%';
ax.Visible = 'off';


%% compute ERD/ERS contrast (MR) between illusion (MI) and control (MC)
MR = (MI - MC);
z1 = min(min(min(squeeze(nanmean(MR,1)))));
z2 = max(max(max(squeeze(nanmean(MR,1)))));
z = max(abs(z1), abs(z2));

%% plot ERD/ERS for MR
figure;
for ch =  1:16
    subplot(4,5,plotpos(ch))
    s = pcolor(squeeze(nanmean(nanmean(MR(:,ch,:,:),2),1))); set(gca,'YDir','normal'); s.FaceColor = 'interp';set(s, 'EdgeColor', 'none');
    caxis([-z, z]) %caxis([z1, z2]) %
    set(gca,'ytick',10:10:length(freqvec),'yticklabels',round(freqvec(10:10:length(freqvec))));
    set(gca,'xtick',11:20:length(time),'xticklabels',time(11:20:length(time)));
    vline(find(time==0),'k');
    vline(find(time==1),'k:');
    vline(find(time==2),'k:');
    vline(find(time==3),'k');
    hold on;
    colormap(redblue)
    title(elpos(ch))
    if ch == 1
        xlabel('Time [s]')
        ylabel('Frequency [Hz]')
    else
        xticklabels({})
        yticklabels({})
    end
    
    % cluster permutation
    [signif,~,~] = permstattest(squeeze(MR(:,ch,:,:)),1000,0.05,0.05,'ttest',0,3);
    contour(signif,1,'k','LineWidth',3)
end
subplot(4,5,1)
ax = axes;
caxis([-z, z])
c = colorbar(ax);
c.Ruler.TickLabelFormat='%g%%';
ax.Visible = 'off';

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
cfg.zlim         = [-6  6];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.alpha,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title('Grand mu band average');
c = colorbar('south');
c.Ruler.TickLabelFormat='%g%%';
% beta band
subplot(1,2,2)
cfg.xlim         = [0   4];
cfg.zlim         = [-4  4];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.beta,:),3),1));
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
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.alpha,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,3)
cfg.xlim         = [0   1];
cfg.zlim         = [-6 6];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.alpha,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,4)
cfg.xlim         = [1   2];
cfg.zlim         = [-6 6];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.alpha,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,5)
cfg.xlim         = [2   3];
cfg.zlim         = [-6 6];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.alpha,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,6)
cfg.xlim         = [3   4];
cfg.zlim         = [-6 6];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.alpha,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

% --- time points beta
subplot(2,6,8)
cfg.xlim         = [-0.5   0];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.beta,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,9)
cfg.xlim         = [0   1];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.beta,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,10)
cfg.xlim         = [1   2];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.beta,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,11)
cfg.xlim         = [2   3];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.beta,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

subplot(2,6,12)
cfg.xlim         = [3   4];
cfg.zlim         = [-4 4];
y(1,:,:) = squeeze(nanmean(nanmean(MR(:,:,band.beta,:),3),1));
tmp.powspctrm = y;
ft_topoplotTFR(cfg, tmp); title([num2str(cfg.xlim(1)),' - ',num2str(cfg.xlim(2)),' s']);

% --- add text
subplot(2,6,1)
text(0,0.5,'mu band'); axis off

subplot(2,6,7)
text(0,0.5,'beta band'); axis off

suptitle('Illusion - Control contrast ERD/ERS over time')
