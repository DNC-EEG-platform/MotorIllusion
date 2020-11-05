function [] = Results_Plots(uql, s, H)
%RESULTS_PLOTS - Plots results of the classification analysis
% Specifically:
% - Extracts results from ERD and PSD classification functions
% - Computes significance with respect to the random permutation results
% - Creates a bar plot with the combined resultss
%
% Syntax:  [] = Results_Plots(uql, s, H)
%
% Inputs:
%    uql (cell array) - contains the feature labels 'ERP' or 'PSD'
%    s (struct) - contains the classification results as filled in Results_Run.m
%    H (vector) - logical vector, true if subject classification result is
%                 above chance level, false otherwise
%
% Outputs:
%    none
%
% Example: 
%    [] = Results_Plots(uql, s, H)
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

%% compute values for plotting

for lab = 1:numel(uql)
    switch uql{lab}
        case 'ERP'
            val.erp = mean(mean(s(lab).foldclsf,3),1)*100;
            val_sem.erp = std(mean(s(lab).foldclsf,3),[],1)/sqrt(10)*100;
            star.erp = H(lab,:);
        case 'PSD'
            val.psd = mean(mean(s(lab).foldclsf,3),1)*100;
            val_sem.psd = std(mean(s(lab).foldclsf,3),[],1)/sqrt(10)*100;
            star.psd = H(lab,:);
    end
end


%% plot resuls of ERP and PSD classification in one plot

figure;
hold all;

% plot significance stars for psd
starx = (1:length(val.psd)) - 0.15;
stary = (val.psd + val_sem.psd) + 3;
for k = 1:length(star.psd)
    if star.psd(k)
        scatter(starx(k),stary(k),'*k')
    end
end
% plot significance stars for erp
starx = (1:length(val.erp)) + 0.15;
stary = (val.erp + val_sem.erp) + 3;
for k = 1:length(star.erp)
    if star.erp(k)
        scatter(starx(k),stary(k),'*k')
    end
end

% plot classification results in bar plot with standard error of the mean
% across the 10 repetitions of the cross validation
bp = barwitherr([val_sem.psd;val_sem.erp]',[val.psd;val.erp]');

% plot theoretical chance level
hline(50,':k');

% make plot nice and label everything
bp(1).FaceColor = [0.5 0.5 1];
bp(2).FaceColor = [1 0.5 0.5];
bp(1).BaseValue = 0;
xticks(1:13)
xticklabels({'S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12','S13'});
ylabel('classification accuracy [%]')
legend(bp,{'ERD/ERS','ERP'},'Orientation','horizontal')