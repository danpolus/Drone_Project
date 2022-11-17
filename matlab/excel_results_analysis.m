clear all; close all; clc;

titleFntSz = 16;
sgtitleFntSz = 19;
axisLabelFntSz = 14;
axisTickFntSz = 14;
linewidth = 2;

nClass = '4';
feature = {'bandpower','higuchi'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nCSP analysis
x = [2 4 6 8 10];

figure;
sgtitle('Validation set classification accuracy as a function of #CSPs', 'FontSize',sgtitleFntSz);
for iFeat = 1:length(feature)
    T = readtable('C:\My Files\Work\BGU\PhD\results\drone\results 2a nCSP.xlsx','Sheet',[nClass 'class ' feature{iFeat}]);
    valid = T{1:18,3:4:size(T,2)};

    ax = subplot(2,1,iFeat); 
    errorbar(x, mean(valid,1), std(valid,[],1), 'Color','#A2142F', 'linewidth',linewidth); 
    xlim([x(1)-1 x(end)+1]); ylim([0 0.8]);
    xlabel('#CSPs', 'FontSize',axisLabelFntSz); ylabel('\kappa', 'FontSize',axisLabelFntSz+2); 
    ax.FontSize = axisTickFntSz;
    if strcmp(feature{iFeat}, 'bandpower')
        title('Total Power', 'FontSize',titleFntSz);
    else
        title('Higuchi', 'FontSize',titleFntSz);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%percent analysis
x = [100 50 33.33 25 20 16.67 14.28 10 7.15 5];

figure;
sgtitle('Classification accuracy as a funtion of the traing set percent', 'FontSize',sgtitleFntSz);
for iFeat = 1:length(feature)
    T = readtable('C:\My Files\Work\BGU\PhD\results\drone\results 2a test percent.xlsx','Sheet',[nClass 'class ' feature{iFeat}]);
    
    ax = subplot(2,1,iFeat);
    hold on
    y = mean(T{1:18, 2:4:size(T,2)},1);
    err = mean(T{1:18, 4:4:size(T,2)},1);
    errorbar(x,y,err, 'linewidth',linewidth);
    y = mean(T{1:18, 3:4:size(T,2)},1);
    err = mean(T{1:18, 5:4:size(T,2)},1);
    errorbar(x,y,err, 'linewidth',linewidth); 
    xlim([0 110]); ylim([0 1.1]); set(gca,'xdir','reverse'); legend({'train','validation'}, 'FontSize',axisLabelFntSz, 'Location','northwest');
    xlabel('data percentage', 'FontSize',axisLabelFntSz+2); ylabel('\kappa', 'FontSize',axisLabelFntSz+2);
    ax.FontSize = axisTickFntSz;
    %ax.XScale = 'log';
    if strcmp(feature{iFeat}, 'bandpower')
        title('Total Power', 'FontSize',titleFntSz);
    else
        title('Higuchi', 'FontSize',titleFntSz);
    end
    hold off
end

figure; 
sgtitle(['Classification accuracy ' nClass 'class ' feature{iFeat}]);
y = T{1:18,2:4:size(T,2)};
err = T{1:18,4:4:size(T,2)};
subplot(2,2,1); plot(x,y, 'linewidth',linewidth-1); xlim([0 110]); set(gca,'xdir','reverse'); xlabel('data percentage'); title('train');
subplot(2,2,2); plot(x,err, 'linewidth',linewidth-1); xlim([0 110]); set(gca,'xdir','reverse'); xlabel('data percentage'); title('train std');
y = T{1:18,3:4:size(T,2)};
err = T{1:18,5:4:size(T,2)};
subplot(2,2,3); plot(x,y, 'linewidth',linewidth-1); xlim([0 110]); set(gca,'xdir','reverse'); xlabel('data percentage'); title('validation');
subplot(2,2,4); plot(x,err, 'linewidth',linewidth-1); xlim([0 110]); set(gca,'xdir','reverse'); xlabel('data percentage'); title('validation std');

idx = [17 18];
figure; 
hold on;
for i = 1:length(idx)
    errorbar(x,y(idx(i),:),err(idx(i),:)); xlim([0 110]); set(gca,'xdir','reverse'); 
end
hold off;
title(['validation ' num2str(idx)]); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%results excel anlysis

train100thresh = 0.2; %kappa threshold
Aug = {'x2_noise', 'x1', 'x2', 'x5', 'x1_jitter', 'x2_jitter'};
T = readtable('C:\My Files\Work\BGU\PhD\results\drone\results 2a fractal new.xlsx','Sheet','2class kappa'); %powerband fractal
class100 = T{1:18,2:5}; 
class50 = T{1:18,6:9};
for i = 0:length(Aug)-1
    augmnt{i+1} = T{1:18, 11+i*4:14+i*4};
end

%all
good_subj = (1:size(class100,1))';
group_inx = true(size(class100,1),1);
disp_aug_results(class100, class50, augmnt, good_subj, group_inx, 'all', Aug);
pause

%filter
good_subj = find(class100(:,1)>=train100thresh & class100(:,2)>0 & class100(:,2)>=class50(:,2)); %  minimal accuracy for MI & can't start below chance & improvement not due to augmentation
class100 = class100(good_subj,:);class50 = class50(good_subj,:);
for i = 0:length(Aug)-1
    augmnt{i+1} = augmnt{i+1}(good_subj,:);
end
group_inx = true(size(class100,1),1);
disp_aug_results(class100, class50, augmnt, good_subj, group_inx, 'all filtered', Aug);
return% pause

%split by middle value
group_inx = class100(:,1)>(max(class100(:,1)) + min(class100(:,1)))/2;
disp_aug_results(class100, class50, augmnt, good_subj, group_inx, 'class100 train above middle', Aug);
group_inx = class100(:,2)>(max(class100(:,2)) + min(class100(:,2)))/2;
disp_aug_results(class100, class50, augmnt, good_subj, group_inx, 'class100 validation above middle', Aug);
group_inx = class50(:,2)>(max(class50(:,2)) + min(class50(:,2)))/2;
disp_aug_results(class100, class50, augmnt, good_subj, group_inx, 'class50 validation above middle', Aug);
pause

%split by successfull augmentation
for i = 1:length(Aug)
    group_inx = augmnt{i}(:,2) > class50(:,2);
    disp_aug_results(class100, class50, augmnt, good_subj, group_inx, 'successfull augmentation', Aug, i);
end

%%%%%%%%%%%%
function disp_aug_results(class100, class50, augmnt, good_subj, group_inx, titl, Aug, kAug)
    if nargin == 7
        kAug = 1:length(Aug);
    end
    for i = kAug
        disp(' ');
        disp(['aug ' Aug{i} ' validation results:']);
        for g=1:2
            if g == 1
                group_inx_ = group_inx;
                disp(['group: ' titl ', subj: ' num2str(good_subj(group_inx_)')]);
            else
                group_inx_ = ~group_inx;
                disp(['group: NOT ' titl ', subj: ' num2str(good_subj(group_inx_)')]);
            end
            if sum(group_inx_) == 0
                continue;
            end
            auggroup = augmnt{i}(group_inx_,2);
            class100group = class100(group_inx_,2); class50group = class50(group_inx_,2); 
            diffclass100 = auggroup - class100group; diffclass50 = auggroup - class50group;
            disp(['MEAN class100: ' num2str(mean(class100group),'%.3f') '+-' num2str(std(class100group),'%.3f') ' (median: ' num2str(median(class100group),'%.3f') '),'...
            '  class50: ' num2str(mean(class50group),'%.3f') '+-' num2str(std(class50group),'%.3f') ' (median: ' num2str(median(class50group),'%.3f') '),'...
            '  augmented: ' num2str(mean(auggroup),'%.3f') '+-' num2str(std(auggroup),'%.3f') ' (median: ' num2str(median(auggroup),'%.3f') ')']);
            disp(['MEAN DIFF class100: ' num2str(mean(diffclass100),'%.3f') '+-' num2str(std(diffclass100),'%.3f') ' (median: ' num2str(median(diffclass100),'%.3f') '),'...
            '  class50: ' num2str(mean(diffclass50),'%.3f') '+-' num2str(std(diffclass50),'%.3f') ' (median: ' num2str(median(diffclass50),'%.3f') ')']);     
        end
    end
end
