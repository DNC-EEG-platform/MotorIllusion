function stdplot(varargin )
%SEMPLOT Summary of this function goes here
%   Detailed explanation goes here
if (length(varargin)==1) || ~isnumeric(varargin{2})
    va = 2;
    data = varargin{1};
    x = 1:size(data,2);
else
    va = 3;
    x = varargin{1};
    data = varargin{2};
end
hold on;
sem = nanstd(data);
plot(x,nanmean(data),varargin{va:end},'LineWidth',2);
plot(x,nanmean(data)+sem,varargin{va:end});
plot(x,nanmean(data)-sem,varargin{va:end});
%plot(x,data,varargin{:});

end

