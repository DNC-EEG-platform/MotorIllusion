function [acc, cvp, feat_out, time_out] = Xval(config, time, trials, group, type)
%XVAL - Performs nested cross validation for the classification procedure
%
% Syntax:  [acc, cvp, feat_out, time_out] = Xval(config, time, trials, group, type)
%
% Inputs:
%    config (struct) - configuration set in PSD_Setting.m and ERD_Setting.m
%    time (vector) - time vector of the input trials
%    trials (struct) - trials to classify from PSD_Run.m or ERD_RUN.m
%    group (vector) - vector of trial labels for classification
%                   classification with 1. All other features are 0.
%    type (string) - feature type identifier. Eiter 'PSD' or 'ERP'
%
% Outputs:
%    acc (struct) - contains classification accuracies
%    cvp (struct) - contains the used cross-validation partitioning
%    feat_out (array [outer folds x features]) - marks features used in the
%                   classification with 1. All other features are 0.
%    time_out (vector) - time line of feature vector
%
% Example:
%    [acc, cvp, feats, feat_time] = Xval(default, timevec, trials, labels, 'PSD');
%
% Other m-files required: none
% Subfunctions: clsfeval
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

switch type
    
    case 'PSD'
        
        %% extract time windows of interest
        
        starttime = config.clsf.interval(1); 
        endtime = config.clsf.interval(2);
        
        % average ERD/ERS across 0.5 second lumps
        for k = 1:(endtime-starttime)/0.5
            loopstarttime = starttime + (0.5 * (k-1));
            loopendtime = starttime + (0.5 * k);
            loopusetime = time >= loopstarttime & time <= loopendtime;
            looptrials(:,:,:,k) = mean(trials(:,:,:,(loopusetime)),4,'omitnan');
            time_out(k) = mean([loopendtime,loopstarttime]);
        end
        trials = looptrials;
        
        %% data aggregation across frequency bands
        
        % definition of frequency bands in Hz
        band.alpha = 8:12;
        band.beta_low = 13:20;
        band.beta_high = 20:30;
        
        % average PSDs across frequency bands
        for tr = 1:size(trials, 1)
            for tp = 1:size(trials, 2)
                trials_red(tr, tp, 1,:) = mean( trials( tr, tp, band.alpha ,:), 3);
                trials_red(tr, tp, 2,:) = mean( trials( tr, tp, band.beta_low ,:), 3);
                trials_red(tr, tp, 3,:) = mean( trials( tr, tp, band.beta_high ,:), 3);
            end
        end
        
        trials = trials_red;
        
        % remove NaN-only frequency bands from dataset
        detectNaN = mean(mean(isnan(squeeze(mean(trials,1,'omitnan'))),3),1);
        trials = trials(:,:,~detectNaN,:);
        
        %% reshape features
        
        % concatenate features into 1D feature vector in specific way
        for tr = 1:size(trials,1)
            tmp = [];
            for ch = 1:size(trials,2)
                tmp2 = [];
                for bd = 1:size(trials,3)
                    tmp2 = [tmp2; squeeze(trials(tr, ch, bd, :))]; %#ok<*AGROW>
                end
                tmp = [tmp; tmp2]; %#ok<*AGROW>
            end
            trials_feat_concat(tr,:) = tmp;
        end
        
        trials = trials_feat_concat;
        
    case 'ERP'
        %% extract time features of interest
        
        usetime = [];
        for c = size(config.clsf.interval,1)
            usetime = cat(1, usetime, time.erp > config.clsf.interval(c,1) & time.erp < config.clsf.interval(c,2));
        end
        
        time = time.erp(logical(usetime));
        trials = squeeze(mean(trials.erp(:,:,logical(usetime)),2));
        
        %% smooth data
        
        % apply moving average filter (Fs = 500 Hz)
        winsamples = config.movwinlen*500;
        trials = movmean(trials,winsamples,2);
        
        % downsample smoothed data
        trials = trials(:,1:winsamples:end);
        time_out = time(1:winsamples:end);
        
        group = group.erp;
        
        %% reshape features
        
        % concatenate features into 1D feature vector in specific way
        for tr = 1:size(trials,1)
            tmp = [];
            for ch = 1:size(trials,2)
                tmp = [tmp; squeeze(trials(tr, ch, :))];
            end
            trials_feat_concat(tr,:) = tmp;
        end
        
        trials = trials_feat_concat;
        
end

%% start outer fold
cvp.outer = cvpartition(group,'KFold',config.xval.nouter);

% iterate over outer folds
for k_out = 1:cvp.outer.NumTestSets
    
    % separate data into train and test set
    data.outer.train = trials(cvp.outer.training(k_out),:,:);
    data.outer.test = trials(cvp.outer.test(k_out),:,:);
    labels.outer.train = group(cvp.outer.training(k_out));
    labels.outer.test = group(cvp.outer.test(k_out));
    
    %% shuffle labels if random permutation test is selected
    
    if config.clsf.random
        labels.outer.train = labels.outer.train(randperm(length(labels.outer.train)));
    end
    
    % zero-mean the data
    data.outer.train = data.outer.train - repmat( mean(data.outer.train,1), size(data.outer.train,1), 1);
    data.outer.test = data.outer.test - repmat( mean(data.outer.train,1), size(data.outer.test,1), 1);
    
    % Group training data w.r.t. the label
    groups = unique(labels.outer.train);
    dat1 = data.outer.train(labels.outer.train == groups(1),:);
    dat2 = data.outer.train(labels.outer.train == groups(2),:);
    
    % if number of features is large (> 50) do pre-selection based on
    % p-values (for the paper only valid for the ERD/ERS feature space)
    if size(data.outer.train,2) > 50
        for feat = 1:size(data.outer.train,2)
            if sum(isnan(dat1(:,feat))) == numel(dat1(:,feat)) || sum(isnan(dat2(:,feat))) == numel(dat2(:,feat))
                p(feat) = nan;
            else
                p(feat) = ranksum(dat1(:,feat), dat2(:,feat));
            end
        end
        
        % if t-test p-value of a feature larger than p-lim, don't use in
        % classification. Used to speed up wrapper feature selection below.
        plim = 0.05;
        dontuse = (p >= plim) | isnan(p);
        
        % if no feature passes the hurdle, increase p-lim incrementally
        while sum(dontuse) > length(dontuse) - 10   % minimum 10 features left over for wrapper selection
            plim = plim + 0.05;
            dontuse = (p >= plim) | isnan(p);
        end
    else
        dontuse = false(1,size(data.outer.train,2));
    end
    
    %% start inner fold feature selection
    
    if strcmp(config.xval.type, 'leaveoneout')
        cvp.inner(k_out) = cvpartition(labels.outer.train,'LeaveOut');
    else
        cvp.inner(k_out) = cvpartition(labels.outer.train,'KFold',config.xval.ninner);
    end
    
    % --- Wrapper forward feature selection using lda
    fun = @clsfeval;
    opts = statset();
    [features, ~] = sequentialfs(fun, data.outer.train, labels.outer.train,...
        'cv', cvp.inner(k_out), 'keepout', dontuse, 'options',opts);
    
    % record which features were chosen in this fold
    feat_out(k_out,:) = features;
    
    %% end inner fold, back to outer fold
    
    % train classification model with best feature set found in the inner
    % fold
    mdl = fitcdiscr(data.outer.train(:,features), labels.outer.train, 'DiscrimType', 'linear', 'Prior', 'uniform');
    
    % compute the prediction accuracy for:
    % training set
    acc.train(k_out) = mean(mdl.predict(data.outer.train(:,features)) == labels.outer.train);
    % test set (single trial)
    acc.test(k_out) = mean(mdl.predict(data.outer.test(:,features)) == labels.outer.test);
    % test set (trial average)
    [pred.testmean.labels(1,:),pred.testmean.score(1,:),~] = mdl.predict(mean( data.outer.test(labels.outer.test == 90,features) ) );
    [pred.testmean.labels(2,:),pred.testmean.score(2,:),~] = mdl.predict(mean( data.outer.test(labels.outer.test == 70,features) ) );
    acc.test_mean(k_out) = mean(pred.testmean.labels == [90; 70]);
    acc.test_mean_score(k_out,:) = pred.testmean.score(:,1)';
    acc.test_mean_labels(k_out,:) = [90, 70];

end

end


function [out] = clsfeval(XT, yT, Xt, yt)
% Scoring function for the wrapper forward feature selection. Evaluates the
% accuracy on test-set sub-averages and calculates the loss function value:
% 1 - ( D(illusion)*P(illusion) + D(control)*P(control))/2
% where D is 1 if the predicted label equals the real label, 0 otherwise
% and P is the posterior probability of the chosen class

ulab = unique(yt);
for k = 1:length(ulab)
    Xtnew(k,:) = mean(Xt(yt==ulab(k),:),1);
    ytnew(k) = mean(yt(yt==ulab(k)));
end

mdl = fitcdiscr(XT, yT, 'DiscrimType', 'linear', 'Prior', 'uniform');

[predlab,predscore,~] = mdl.predict(Xtnew);
base = predlab(:) == ytnew(:);

out = 1 - (base' * diag(predscore)) / 2;

end
