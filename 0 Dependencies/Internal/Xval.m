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

switch type
    
    case 'PSD'
        
        %% remove time before onset of stimulation
        
        starttime = 0; endtime = 3;
        usetime = time > starttime & time < endtime;
        
        % average ERD/ERS across the trial duration
        trials = nanmean(trials(:,:,:,(usetime)),4);
        time_out = nanmean(time(time > starttime));
        
        %% dimensionality reduction + time smoothing (making data more robust)
        
        % compute number of total features
        features.number_full = size(trials, 2) * size(trials, 3);
 
        % if more features than max
        if features.number_full > config.xval.maxfeatures
            
            % calculate size of sub-bands in frequency domain to lower
            % feature count
            winsize = floor(features.number_full / config.xval.maxfeatures);
            
            % average PSDs across new frequency sub-bands
            for tr = 1:size(trials, 1)
                for tp = 1:size(trials, 2)
                    counter = 1;
                    while winsize*counter <= size(trials, 3)
                        win = (winsize*(counter - 1) + 1) : (winsize * counter);
                        trials_red(tr, tp, counter) = mean(squeeze(trials(tr, tp, win)));
                        counter = counter + 1;
                    end
                    % last sub-band if not divisible exactly
                    trials_red(tr, tp, counter) = mean( squeeze( trials( tr, tp, (winsize*(counter - 1) + 1) : end ) ) );
                end
            end
            
            trials = trials_red;
        end
        
        % remove NaN-only frequency bands from dataset
        detectNaN = mean(isnan(squeeze(nanmean(trials,1))),1);
        trials = trials(:,:,~detectNaN);

        %% reshape features
        
        % concatenate features into 1D feature vector in specific way 
        for tr = 1:size(trials,1)
            tmp = [];
            for ch = 1:size(trials,2)
                tmp = [tmp; squeeze(trials(tr, ch, :))]; %#ok<*AGROW>
            end
            trials_feat_concat(tr,:) = tmp;
        end
        
        trials = trials_feat_concat;
        
    case 'ERP'
        %% remove time before onset of stimulation

        usetime = [];
        for c = size(config.clusterpos,1)
            usetime = cat(1, usetime, time.erp > config.clusterpos(c,1) & time.erp < config.clusterpos(c,2));
        end

        time = time.erp(logical(usetime));
        trials = squeeze(mean(trials.erp(:,:,logical(usetime)),2));
        
        % apply moving average filter (Fs = 500 Hz) 
        winsamples = config.movwinlen*500;
        trials = movmean(trials,winsamples,2);
        
        % downsample smoothed data
        trials = trials(:,1:winsamples:end);
        time = time(1:winsamples:end);
        
        group = group.erp;

        %% dimensionality reduction + time smoothing (making data more robust)
        
        % compute number of total features
        features.number_full = size(trials, 2) * size(trials, 3);
        
        % if more features than max
        if features.number_full > config.xval.maxfeatures
            
            % interpolate values at fewer time points
            for tr = 1:size(trials, 1)
                trials_red(tr,:) = interp1(time,trials(tr,:),linspace(time(1),time(end),config.xval.maxfeatures));
            end
            trials = trials_red;
            time_out = linspace(time(1),time(end),config.xval.maxfeatures);
        else
            time_out = time;
        end
        
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
    
    %% start inner fold feature selection
    
    if strcmp(config.xval.type, 'leaveoneout')
        cvp.inner(k_out) = cvpartition(labels.outer.train,'LeaveOut');
    else
        cvp.inner(k_out) = cvpartition(labels.outer.train,'KFold',config.xval.ninner);
    end
    
    % Filter feature selection based on t-test
    groups = unique(labels.outer.train);
    dat1 = data.outer.train(labels.outer.train == groups(1),:);
    dat2 = data.outer.train(labels.outer.train == groups(2),:);
    
    % if number of features is large (> 50) do pre-selection based on
    % p-values
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
        while sum(dontuse) == length(dontuse)
            plim = plim + 0.05;
            dontuse = (p >= plim) | isnan(p);
        end
    else
        dontuse = false(1,size(data.outer.train,2));
    end
    %     dontuse = logical(dontuse .* 0);
    
    % --- Wrapper forward feature selection using lda
    fun = @(XT, yT, Xt, yt) loss( fitcdiscr(XT, yT, 'DiscrimType', 'linear', 'Prior', 'uniform'), Xt, yt);
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
    acc.test_mean(k_out) = mean( [mdl.predict( mean( data.outer.test(labels.outer.test == 90,features) ) ) == 90, ...
        mdl.predict( mean( data.outer.test(labels.outer.test == 70,features) ) ) == 70]);
    
end
