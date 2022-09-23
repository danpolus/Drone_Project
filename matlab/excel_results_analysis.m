clear all; close all; clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %percent analysis
% T = readtable('D:\My Files\Work\BGU\PhD\results\drone\results 2a test percent.xlsx','Sheet','2class higuchi'); %bandpower higuchi
% x = [100 50 40 30 25 20 10];
% 
% figure; 
% y = T{1:18,2:4:size(T,2)};
% subplot(1,2,1); plot(x,y); xlim([0 110]); set(gca,'xdir','reverse'); title('train');
% err = T{1:18,4:4:size(T,2)};
% subplot(1,2,2); plot(x,err); xlim([0 110]); set(gca,'xdir','reverse'); title('train std');
% 
% figure; 
% y = T{1:18,3:4:size(T,2)};
% subplot(1,2,1); plot(x,y); xlim([0 110]); set(gca,'xdir','reverse'); title('validation');
% err = T{1:18,5:4:size(T,2)};
% subplot(1,2,2); plot(x,err); xlim([0 110]); set(gca,'xdir','reverse'); title('validation std');
% 
% idx = [17 18];
% figure; 
% hold on;
% for i = 1:length(idx)
%     errorbar(x,y(idx(i),:),err(idx(i),:)); xlim([0 110]); set(gca,'xdir','reverse'); 
% end
% hold off;
% title(['validation ' num2str(idx)]); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%results excel anlysis
train100thresh = 0.2;
Aug = {'x1', 'x2', 'x5', 'x1_jitter', 'x2_jitter'};
T = readtable('D:\My Files\Work\BGU\PhD\results\drone\results 2a fractal new.xlsx','Sheet','2class kappa'); %powerband fractal

class100 = T{1:18,2:5}; class50 = T{1:18,6:9};
good_subj  = find(class100(:,1)>=train100thresh & class100(:,2)>0 & class100(:,2)>=class50(:,2)); %  minimal accuracy for MI & can't start below chance & improvement not due to augmentation
class100 = class100(good_subj,:);class50 = class50(good_subj,:);
for i = 0:length(Aug)-1
    augmnt{i+1} = T{1:18, 15+i*4:18+i*4};
    augmnt{i+1} = augmnt{i+1}(good_subj,:);
end

group_inx = true(size(class100,1),1);
disp_aug_results(class100, class50, augmnt, group_inx, 'all', Aug);
for i = 1:length(Aug)
    group_inx = augmnt{i}(:,2) > class50(:,2);
    disp_aug_results(class100, class50, augmnt, group_inx, ['augmentation success for subj: ' num2str(good_subj(group_inx)')], Aug, i);
end
group_inx = class100(:,1)>(max(class100(:,1)) + min(class100(:,1)))/2;
disp_aug_results(class100, class50, augmnt, group_inx, 'class100 train high DR', Aug);
group_inx = class100(:,2)>(max(class100(:,2)) + min(class100(:,2)))/2;
disp_aug_results(class100, class50, augmnt, group_inx, 'class100 valid high DR', Aug);
group_inx = class50(:,2)>(max(class50(:,2)) + min(class50(:,2)))/2;
disp_aug_results(class100, class50, augmnt, group_inx, 'class50 valid high DR', Aug);


function disp_aug_results(class100, class50, augmnt, group_inx_, titl, Aug, kAug)
    if nargin == 6
        kAug = 1:length(Aug);
    end
    for i = kAug
        disp(' ');
        disp(['aug ' Aug{i} ' validation difference:']);
        for g=1:2
            if g == 1
                group_inx = group_inx_;
                disp(['group: ' titl]);
            else
                group_inx = ~group_inx_;
                disp(['group: NOT ' titl]);
            end
            if sum(group_inx) == 0
                continue;
            end
            disp(['TOTAL class100 mean: ' num2str(mean(augmnt{i}(group_inx,2)) - mean(class100(group_inx,2)),'%.3f') '+-' num2str(std(augmnt{i}(group_inx,2)),'%.3f')...
            ', median: ' num2str(median(augmnt{i}(group_inx,2)) - median(class100(group_inx,2)),'%.3f')...
            '  class50 mean: ' num2str(mean(augmnt{i}(group_inx,2)) - mean(class50(group_inx,2)),'%.3f') '+-' num2str(std(augmnt{i}(group_inx,2)),'%.3f')...
            ', median: ' num2str(median(augmnt{i}(group_inx,2)) - median(class50(group_inx,2)),'%.3f')]);  
            disp(['SUBJECT class100 mean: ' num2str(mean(augmnt{i}(group_inx,2) - class100(group_inx,2)),'%.3f') '+-' num2str(std(augmnt{i}(group_inx,2) - class100(group_inx,2)),'%.3f')...
            ', median: ' num2str(median(augmnt{i}(group_inx,2) - class100(group_inx,2)),'%.3f')...
            '  class50 mean: ' num2str(mean(augmnt{i}(group_inx,2) - class50(group_inx,2)),'%.3f') '+-' num2str(std(augmnt{i}(group_inx,2) - class50(group_inx,2)),'%.3f')...
            ', median: ' num2str(median(augmnt{i}(group_inx,2) - class50(group_inx,2)),'%.3f')]);     
        end
    end
end
