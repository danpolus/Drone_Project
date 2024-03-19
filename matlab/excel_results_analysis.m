clear all; close all; clc;

project_params = augmentation_params();
project_params.grapics.axisLabelFntSz = 30;
project_params.grapics.axisTickFntSz = 30;

nClass = '2';
feature = {'bandpower','higuchi'};
train100thresh = 0; %kappa threshold for filtering
valid50thresh = 0.35; %kappa threshold for grouping

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nCSP analysis
x = [2 4 6 8 10];

figure;
% sgtitle('Validation set classification accuracy as a function of #CSPs', 'FontSize',project_params.grapics.sgtitleFntSz,'FontName',project_params.grapics.fontName);
for iFeat = 1:length(feature)
    T = readtable('C:\My Files\Work\BGU\PhD\results\drone\results 2a nCSP.xlsx','Sheet',[nClass 'class ' feature{iFeat}]);
    valid = T{1:18,3:4:size(T,2)};

    ax = subplot(2,1,iFeat); 
    errorbar(x, mean(valid,1), std(valid,[],1), 'Color','#A2142F', 'linewidth',project_params.grapics.linewidth); 
    xlim([x(1)-1 x(end)+1]); ylim([0 1.1]);
    if iFeat == length(feature)
        xlabel('#CSPs', 'FontSize',project_params.grapics.axisLabelFntSz-5,'FontName',project_params.grapics.fontName); 
    end
    ylabel('\kappa', 'FontSize',project_params.grapics.axisLabelFntSz+2,'FontName',project_params.grapics.fontName); 
    ax.FontSize = project_params.grapics.axisTickFntSz;
    ax.FontName = project_params.grapics.fontName;
    if strcmp(feature{iFeat}, 'bandpower')
        title('Total Power', 'FontSize',project_params.grapics.titleFntSz-3,'FontName',project_params.grapics.fontName);
    else
        title('Higuchi', 'FontSize',project_params.grapics.titleFntSz-3,'FontName',project_params.grapics.fontName);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%percent analysis
x = [100 50 33.33 25 20 16.67 14.28 10 7.15 5];

figure;
sgtitle('Classification accuracy as a funtion of the traing set percent', 'FontSize',project_params.grapics.sgtitleFntSz,'FontName',project_params.grapics.fontName);
for iFeat = 1:length(feature)
    T = readtable('C:\My Files\Work\BGU\PhD\results\drone\results 2a test percent.xlsx','Sheet',[nClass 'class ' feature{iFeat}]);
    
    ax = subplot(2,1,iFeat);
    hold on
    y = mean(T{1:18, 2:4:size(T,2)},1);
    err = mean(T{1:18, 4:4:size(T,2)},1);
    errorbar(x,y,err, 'linewidth',project_params.grapics.linewidth);
    y = mean(T{1:18, 3:4:size(T,2)},1);
    err = mean(T{1:18, 5:4:size(T,2)},1);
    errorbar(x,y,err, 'linewidth',project_params.grapics.linewidth); 
    xlim([0 110]); ylim([0 1.1]); set(gca,'xdir','reverse'); legend({'train','validation'}, 'FontSize',project_params.grapics.axisLabelFntSz, ,'FontName',project_params.grapics.fontName, 'Location','northwest');
    xlabel('data percentage', 'FontSize',project_params.grapics.axisLabelFntSz+2,'FontName',project_params.grapics.fontName); ylabel('\kappa', 'FontSize',project_params.grapics.axisLabelFntSz+2,'FontName',project_params.grapics.fontName);
    ax.FontSize = project_params.grapics.axisTickFntSz;
    ax.FontName = project_params.grapics.fontName;
    %ax.XScale = 'log';
    if strcmp(feature{iFeat}, 'bandpower')
        title('Total Power', 'FontSize',project_params.grapics.titleFntSz,'FontName',project_params.grapics.fontName);
    else
        title('Higuchi', 'FontSize',project_params.grapics.titleFntSz,'FontName',project_params.grapics.fontName);
    end
    hold off
end

figure;
sgtitle('Subject classification accuracy as a funtion of the traing set percent', 'FontSize',project_params.grapics.sgtitleFntSz-6,'FontName',project_params.grapics.fontName);
for iFeat = 1:length(feature)
    T = readtable('C:\My Files\Work\BGU\PhD\results\drone\results 2a test percent.xlsx','Sheet',[nClass 'class ' feature{iFeat}]);
    
    y = T{1:18,2:4:size(T,2)};
%     err = T{1:18,4:4:size(T,2)};
    ax = subplot(2,2,(iFeat-1)*2+1); plot(x,y, 'linewidth',project_params.grapics.linewidth-1.5); xlim([0 110]); set(gca,'xdir','reverse'); 
    %hold on; yline((max(y(:,1))+min(y(:,1)))/2, '--k', 'linewidth',project_params.grapics.linewidth-1); hold off;
    hold on; yline(valid50thresh, '--k', 'linewidth',project_params.grapics.linewidth-2); hold off; 
    xlabel('data percentage', 'FontSize',project_params.grapics.axisLabelFntSz-8,'FontName',project_params.grapics.fontName); ylabel('\kappa', 'FontSize',project_params.grapics.axisLabelFntSz+2,'FontName',project_params.grapics.fontName);
    ax.FontSize = project_params.grapics.axisTickFntSz-8; 
    ax.FontName = project_params.grapics.fontName;
    if strcmp(feature{iFeat}, 'bandpower')
        title('Total Power (train set)', 'FontSize',project_params.grapics.titleFntSz-6,'FontName',project_params.grapics.fontName);
    else
        title('Higuchi (train set)', 'FontSize',project_params.grapics.titleFntSz-6,'FontName',project_params.grapics.fontName);
    end
    
    y = T{1:18,3:4:size(T,2)};
%     err = T{1:18,5:4:size(T,2)};
    ax = subplot(2,2,(iFeat-1)*2+2); plot(x,y, 'linewidth',project_params.grapics.linewidth-1.5); xlim([0 110]); set(gca,'xdir','reverse'); 
    %hold on; yline((max(y(:,1))+min(y(:,1)))/2, '--k', 'linewidth',project_params.grapics.linewidth-1); hold off;
    hold on; yline(valid50thresh, '--k', 'linewidth',project_params.grapics.linewidth-2); hold off;
    xlabel('data percentage', 'FontSize',project_params.grapics.axisLabelFntSz-8,'FontName',project_params.grapics.fontName); ylabel('\kappa', 'FontSize',project_params.grapics.axisLabelFntSz+2,'FontName',project_params.grapics.fontName);
    ax.FontSize = project_params.grapics.axisTickFntSz-8; 
    ax.FontName = project_params.grapics.fontName;
    if strcmp(feature{iFeat}, 'bandpower')
        title('Total Power (validation set)', 'FontSize',project_params.grapics.titleFntSz-6,'FontName',project_params.grapics.fontName);
    else
        title('Higuchi (validation set)', 'FontSize',project_params.grapics.titleFntSz-6,'FontName',project_params.grapics.fontName);
    end
    % subplot(2,2,2); plot(x,err, 'linewidth',project_params.grapics.linewidth-1); xlim([0 110]); set(gca,'xdir','reverse'); xlabel('data percentage'); title('train std');
    % subplot(2,2,4); plot(x,err, 'linewidth',project_params.grapics.linewidth-1); xlim([0 110]); set(gca,'xdir','reverse'); xlabel('data percentage'); title('validation std');  
end


figure;
sgtitle('Baseline Set Validation Accuracy Distribution', 'FontSize',project_params.grapics.sgtitleFntSz,'FontName',project_params.grapics.fontName);
for iFeat = 1:length(feature)
    T = readtable('C:\My Files\Work\BGU\PhD\results\drone\results 2a test percent.xlsx','Sheet',[nClass 'class ' feature{iFeat}]);
    y = T{1:18,3:4:size(T,2)};
    ax = subplot(2,1,iFeat); histogram(y(:,3),8, 'FaceColor',"#FF0000", 'linewidth',project_params.grapics.linewidth-2);
    hold on; xline(valid50thresh, '--k', 'linewidth',project_params.grapics.linewidth-1); hold off; 
    xlabel('\kappa', 'FontSize',project_params.grapics.axisLabelFntSz+2,'FontName',project_params.grapics.fontName); ylabel('# subjects', 'FontSize',project_params.grapics.axisLabelFntSz-8,'FontName',project_params.grapics.fontName);
    ax.FontSize = project_params.grapics.axisTickFntSz; 
    ax.FontName = project_params.grapics.fontName;
    ylim([0,8]); %yticks([0:2:8]);
    if strcmp(feature{iFeat}, 'bandpower')
        title('Total Power', 'FontSize',project_params.grapics.titleFntSz-4,'FontName',project_params.grapics.fontName);
    else
        title('Higuchi', 'FontSize',project_params.grapics.titleFntSz-4,'FontName',project_params.grapics.fontName);
    end      
end


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

% Aug = {'33%+67% NOISE', '33%+33% NFT', '33%+67% NFT', '33%+167% NFT', '33%+67% jittered NFT \alpha -0.99', '33%+67% jittered NFT \alpha -0.9', '33%+67% jittered NFT \alpha -0.5', '33%+67% jittered NFT \alpha 0', '33%+67% jittered NFT \alpha 0.5',...
%     '33%+67% jittered NFT \gamma -0.99', '33%+67% jittered NFT \gamma -0.9', '33%+67% jittered NFT \gamma -0.5', '33%+67% jittered NFT \gamma 0', '33%+67% jittered NFT \gamma 0.5',...
%     '33%+67% jittered NFT t0 -0.9', '33%+67% jittered NFT t0 -0.5', '33%+67% jittered NFT t0 0', '33%+67% jittered NFT t0 0.5', '33%+67% jittered NFT t0 6', '33%+67% jittered NFT t0 10', '33%+67% jittered NFT t0 15',...
%     '33%+67% jittered NFT', '33%+67% jittered NFT FULL'};		
% Aug = {'33%+67% NOISE', '33%+33% NFT', '33%+67% NFT', '33%+167% NFT', '33%+67% jittered NFT \alpha -0.9', '33%+67% jittered NFT \alpha -0.5', '33%+67% jittered NFT \alpha 0', '33%+67% jittered NFT \alpha 0.5', '33%+67% jittered NFT'};


for iFeat = 1:length(feature)
    T = readtable(['C:\My Files\Work\BGU\PhD\results\drone\results 2a augmentation.xlsx'],'Sheet',[nClass 'class ' feature{iFeat}]);
    Aug = {'33%+67% NOISE', '33%+33% NFT', '33%+67% NFT', '33%+167% NFT', '33%+67% jittered NFT: \alpha only', '33%+67% jittered NFT'};
    class100 = T{1:18,2:5}; 
    class50 = T{1:18,6:9};
    for i = 0:length(Aug)-1
        augmnt{i+1} = T{1:18, 11+i*4:14+i*4};
    end
%     T = readtable(['C:\My Files\Work\BGU\PhD\results\drone\results ws augmentation.xlsx'],'Sheet',feature{iFeat});
%     Aug = {'33%+67% NOISE', '33%+67% NFT', '33%+67% jittered NFT: \alpha only', '33%+67% jittered NFT'};
%     class100 = T{1:5,2:6}; 
%     class50 = T{1:5,7:11};
%     for i = 0:length(Aug)-1
%         augmnt{i+1} = T{1:5, 13+i*5:17+i*5};
%     end    

    if strcmp(feature{iFeat}, 'bandpower')
        titl = 'Total Power';
    else
        titl = 'Higuchi';
    end    
    
    % %all
    % good_subj = (1:size(class100,1))';
    % group_inx = true(size(class100,1),1);
    % disp_aug_results(class100, class50, augmnt, good_subj, group_inx, [titl ' all not filtered'], project_params, Aug);
    % pause
    
    %filter
    good_subj = find(class100(:,1)>=train100thresh & class50(:,2)>0 & class100(:,2)>=class50(:,2)); %  minimal accuracy for MI & can't start below chance & improvement not due to augmentation
    class100 = class100(good_subj,:);class50 = class50(good_subj,:);
    for i = 0:length(Aug)-1
        augmnt{i+1} = augmnt{i+1}(good_subj,:);
    end
    group_inx = true(size(class100,1),1);
    disp_aug_results(class100, class50, augmnt, good_subj, group_inx, titl, project_params, Aug);
    % pause
    
    %split by middle value
    % group_inx = class100(:,1)>valid50thresh; %>(max(class100(:,1)) + min(class100(:,1)))/2;
    % disp_aug_results(class100, class50, augmnt, good_subj, group_inx, 'class100 train above middle', project_params, Aug);
    % group_inx = class100(:,2)>valid50thresh; %>(max(class100(:,2)) + min(class100(:,2)))/2;
    % disp_aug_results(class100, class50, augmnt, good_subj, group_inx, 'class100 validation above middle', project_params, Aug);
    group_inx = class50(:,2)>valid50thresh; %(max(class50(:,2)) + min(class50(:,2)))/2;
    disp_aug_results(class100, class50, augmnt, good_subj, group_inx, [titl ' validation \kappa>' num2str(valid50thresh) ' group'], project_params, Aug);
    % pause
    % 
    % %split by successfull augmentation
    % for i = 1:length(Aug)
    %     group_inx = augmnt{i}(:,2) > class50(:,2);
    %     disp_aug_results(class100, class50, augmnt, good_subj, group_inx, 'successfull augmentation', project_params, Aug, i);
    % end
end

%%%%%%%%%%%%
function disp_aug_results(class100, class50, augmnt, good_subj, group_inx, titl, project_params, Aug, kAug)
    if nargin == 8
        kAug = 1:length(Aug);
    end
    boxData = {[],[]};
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
            [~,p_class100] = ttest(auggroup,class100group); [~,p_class50] = ttest(auggroup,class50group);
%             p_class100 = ranksum(auggroup,class100group); p_class50 = ranksum(auggroup,class50group);
            disp(['MEAN class100: ' num2str(mean(class100group),'%.3f') '+-' num2str(std(class100group),'%.3f') ' p<' num2str(p_class100,'%.3f') ' (median: ' num2str(median(class100group),'%.3f') '),'...
            '  class50: ' num2str(mean(class50group),'%.3f') '+-' num2str(std(class50group),'%.3f') ' p<' num2str(p_class50,'%.3f') ' (median: ' num2str(median(class50group),'%.3f') '),'...
            '  augmented: ' num2str(mean(auggroup),'%.3f') '+-' num2str(std(auggroup),'%.3f') ' (median: ' num2str(median(auggroup),'%.3f') ')']);
            diffclass100 = auggroup - class100group; diffclass50 = auggroup - class50group; diffclass10050 = class100group - class50group;
            [~,p_class100] = ttest(diffclass100); [~,p_class50] = ttest(diffclass50);            
%             p_class100 = signrank(diffclass100); p_class50 = signrank(diffclass50); 
            disp(['MEAN DIFF class100: ' num2str(mean(diffclass100),'%.3f') '+-' num2str(std(diffclass100),'%.3f') ' p<' num2str(p_class100,'%.3f') ' (median: ' num2str(median(diffclass100),'%.3f') '),'...
            '  class50: ' num2str(mean(diffclass50),'%.3f') '+-' num2str(std(diffclass50),'%.3f') ' p<' num2str(p_class50,'%.3f') ' (median: ' num2str(median(diffclass50),'%.3f') '),'...
            '  GAP: ' num2str(mean(diffclass10050),'%.3f') '+-' num2str(std(diffclass10050),'%.3f') ' (median: ' num2str(median(diffclass10050),'%.3f') ')']);     

            boxData{g}(:,1:2) = [class100group, class50group];
            boxData{g}(:,2+i) = auggroup;
        end
    end

    for g=1:2
        if isempty(boxData{g})
            continue;
        end
        figure; hold on;
        bc = boxchart(boxData{g}, 'LineWidth',3.5);%boxplot(boxData{g},labels);  
        plot(mean(boxData{g},1),"diamond", 'MarkerFaceColor','r'); 
        yline(mean(boxData{g}(:,1)),'--', 'Color',"#FF00FF",'LineWidth',2.5);
        yline(median(boxData{g}(:,1)),'--', 'Color',"#00FF00",'LineWidth',2.5);
        yline(mean(boxData{g}(:,2)),'--', 'Color',"#D95319", 'LineWidth',2.5);
        yline(median(boxData{g}(:,2)),'--', 'Color',"#EDB120", 'LineWidth',2.5);    
        hold off;
        title(['Augmentation Strategies: ' titl], 'FontSize',project_params.grapics.titleFntSz,'FontName',project_params.grapics.fontName);
        xticklabels([{'100%','33%'},Aug]); ax = gca; ax.FontSize = project_params.grapics.axisTickFntSz-4; ax.FontName = project_params.grapics.fontName;
        ylabel('\kappa', 'FontSize',project_params.grapics.axisLabelFntSz+2,'FontName',project_params.grapics.fontName); ylim([-1,1]);
        legend({'','average','100% average','100% median','33% average','33% median'}, 'NumColumns',2, 'FontSize',project_params.grapics.axisLabelFntSz-6,'FontName',project_params.grapics.fontName, 'Location','southeast');
    end
end
