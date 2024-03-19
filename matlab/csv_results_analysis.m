%
% https://www.mathworks.com/matlabcentral/fileexchange/39696-raacampbell-sigstar
%

clear all; close all; clc;

train100thresh = 0; % 0.2 %kappa threshold for filtering
valid50thresh = 0.05:0.05:0.95; %kappa threshold for grouping
setType = 'valid';

kappa = 0.35; % if empty, search the best kappa
p_alpha = 0.05;

fp = 'C:\My Files\Work\BGU\Datasets\drone BCI\2a\';
out_fn = 'aumentation_summary.xlsx';

project_params = augmentation_params();

plot_flg = true;
plot_Ac = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[fn, fp] = uigetfile([fp '*.csv'], 'Select FULL set classification results');
classFull = extract_results_class_acc(fn, fp);
[fn, fp] = uigetfile([fp '*.csv'], 'Select SMALL set classification results');
classSmall = extract_results_class_acc(fn, fp);
[files, fp] = uigetfile([fp '*.csv'], 'Select AUGMENTED SETS classification results files', 'MultiSelect','on');
if ~iscell(files) %in case only 1 file selected
    files = {files};
end
for iFile = 1:length(files)
    classAug(iFile) = extract_results_class_acc(files{iFile}, fp);
end

good_subj_inx = classFull.train>train100thresh & classSmall.valid>0 & classFull.valid>=classSmall.valid; %  minimal accuracy for MI & can't start below chance & improvement not due to augmentation
resSumary = summarize_results(classFull, classSmall, classAug, setType, good_subj_inx, valid50thresh, kappa, p_alpha);
writetable(resSumary,[fp out_fn]);

if plot_flg
    if isempty(kappa)
        kappa = resSumary.kappa(strcmp(resSumary.Name1,'x2TypFit_Small33cls2CSPBandPower_classResults') & resSumary.kappa>0);
    end
    group_inx = good_subj_inx & classSmall.(setType) >= kappa(1);
    boxData = [classFull.(setType), classSmall.(setType), [classAug.(setType)]];
    boxData = boxData(group_inx,:);
    if ~plot_Ac
        y_lbl = '\kappa';
    else
        boxData = (boxData+1)/2;
        y_lbl = 'Accuracy';
    end

    figure('Color', 'white'); hold on;
    ColorOrder = linspecer(3);
    legend_labels = [];
    % bc = boxchart(boxData, 'LineWidth',project_params.grapics.linewidth-0.5);  %boxplot(boxData,labels);
    % boxchart(repelem(1:size(boxData,2), size(boxData,1)), reshape(boxData,1,[]), 'LineWidth',project_params.grapics.linewidth-0.5);
    for iBox = 1:size(boxData,2)
        boxchart(repelem(iBox,size(boxData,1)), boxData(:,iBox), 'BoxFaceColor',ColorOrder(min(3,iBox),:) ,'LineWidth',project_params.grapics.linewidth-0.5); 
        plot(iBox,mean(boxData(:,iBox)),"diamond", 'MarkerFaceColor',ColorOrder(min(3,iBox),:),'MarkerEdgeColor','none', 'MarkerSize',project_params.grapics.linewidth+8);
        legend_labels = [legend_labels,{'',''}];
    end
%     plot(mean(boxData,1),"diamond", 'MarkerFaceColor','r', 'MarkerSize',project_params.grapics.linewidth+8);
%     yline(mean(boxData(:,1)),'--', 'Color',ColorOrder(1,:)*0.9,'LineWidth',project_params.grapics.linewidth-1.5);
    yline(mean(boxData(:,2)),'--', 'Color',ColorOrder(2,:)*0.72,'LineWidth',project_params.grapics.linewidth-1.5);
%     yline(median(boxData(:,1)),'--', 'Color',ColorOrder(1,:)*0.9, LineWidth',project_params.grapics.linewidth-1.5);
%     yline(median(boxData(:,2)),'--', 'Color',ColorOrder(2,:)*0.9,'LineWidth',project_params.grapics.linewidth-1.5);
%     ylim([-1,1]);
    hold off;

    %prepare data for sigstar
    sig_groups = []; sig_stats = [];
    for iAug = 1:length(classAug)
        p_val_inx = strcmp(resSumary.Name1,classAug(iAug).Name) & strcmp(resSumary.Name2,classSmall.Name) & resSumary.kappa == kappa(1);
        if resSumary.p_val(p_val_inx) < p_alpha
            sig_groups = [sig_groups, {[2,2+iAug]}]; 
            sig_stats = [sig_stats resSumary.p_val(p_val_inx)];
        end
    end
    H = sigstar(sig_groups, sig_stats);           
    if ~isempty(H)
        set(H(:,1),'linewidth',project_params.grapics.linewidth-2);
        set(H(:,2),'FontSize',project_params.grapics.textFntSz-3);
        set(H(:,2),'FontName',project_params.grapics.fontName);
    end

    ax = gca;
    ax.XGrid = "off"; ax.YGrid = "off"; ax.GridColor = project_params.grapics.GridColor; ax.GridAlpha = project_params.grapics.GridAlpha;
    ax.XMinorGrid = "off"; ax.YMinorGrid = "on"; ax.MinorGridColor = project_params.grapics.GridColor; ax.MinorGridAlpha = project_params.grapics.GridAlpha;
    ax.Box = "on";
    ax.FontSize = project_params.grapics.axisTickFntSz-5;
    ax.FontName = project_params.grapics.fontName;
    xticks([1:size(boxData,2)]);
%     xticklabels([{'Full','Small'},{classAug.Name}]);
    xticklabels([{'Full (100%)','Small (33%)','Small (33%) + noise DA (67%)','Small (33%) + NFT DA (33%)','Small (33%) + NFT DA jitter[t_0] (33%)','Small (33%) + NFT DA (67%)','Small (33%) + NFT DA jitter[t_0] (67%)'}]);
    ylabel(y_lbl, 'FontSize',project_params.grapics.axisLabelFntSz,'FontName',project_params.grapics.fontName); 
%     title(['Augmentation Strategies: ' 'x2TypFit_Small33cls2CSPBandPower_classResults'], 'FontSize',project_params.grapics.titleFntSz, 'FontName',project_params.grapics.fontName));
%     legend({'','average','Full average','Full median','Small average','Small median'}, 'NumColumns',2, 'FontSize',project_params.grapics.axisLabelFntSz-16, 'FontName',project_params.grapics.fontName, 'Location','southeast');
    legend([legend_labels,{' small set average accuracy'}], 'FontSize',project_params.grapics.axisLabelFntSz-16, 'FontName',project_params.grapics.fontName, 'Location','southeast');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function classAcc = extract_results_class_acc(csvFN, csvFP)
    csvData = csvread(fullfile(csvFP, csvFN));
    classAcc.Name = csvFN(1:end-4);
    classAcc.train = csvData(:,1);
    classAcc.valid = csvData(:,2);
    classAcc.test = csvData(:,3);
    classAcc.trainStd = csvData(:,4);
    classAcc.validStd = csvData(:,5);
end

function resSumary = summarize_results(classFull, classSmall, classAug, setType, good_subj_inx, kappaThresh, th_kappa, p_alpha)
    resSumary = table();
    for iAug = 1:length(classAug)
        if isempty(th_kappa) %find kappa with maximal significant accuracy difference 
            pVals = inf(1,length(kappaThresh));
            diffMeans = -inf(1,length(kappaThresh));
            for iKappa = 1:length(kappaThresh)
                group_inx = classSmall.(setType)>=kappaThresh(iKappa);
                accStat = get_statistics(classAug(iAug), classSmall, setType, good_subj_inx & group_inx, kappaThresh(iKappa));
                pVals(iKappa) = accStat.p_val;
                diffMeans(iKappa) = accStat.diffmean;
            end
            if any(pVals<p_alpha)
                diffMeans(pVals>=p_alpha) = NaN;
            end
            [~,kappaInx] = max(diffMeans);
            kappa = kappaThresh(kappaInx);
        else 
            kappa = th_kappa;
        end

        group_inx = classSmall.(setType)>=kappa;
        resSumary = [resSumary; struct2table(get_statistics(classFull, classSmall, setType, good_subj_inx, 0))];
        resSumary = [resSumary; struct2table(get_statistics(classFull, classSmall, setType,  good_subj_inx & group_inx, kappa))];
        resSumary = [resSumary; struct2table(get_statistics(classFull, classSmall, setType,  good_subj_inx & ~group_inx, -kappa))];
        resSumary = [resSumary; struct2table(get_statistics(classAug(iAug), classSmall, setType, good_subj_inx, 0))];
        resSumary = [resSumary; struct2table(get_statistics(classAug(iAug), classSmall, setType,  good_subj_inx & group_inx, kappa))];
        resSumary = [resSumary; struct2table(get_statistics(classAug(iAug), classSmall, setType,  good_subj_inx & ~group_inx, -kappa))];        
        resSumary = [resSumary; struct2table(get_statistics(classAug(iAug), classFull, setType, good_subj_inx, 0))];
        resSumary = [resSumary; struct2table(get_statistics(classAug(iAug), classFull, setType,  good_subj_inx & group_inx, kappa))];
        resSumary = [resSumary; struct2table(get_statistics(classAug(iAug), classFull, setType,  good_subj_inx & ~group_inx, -kappa))];        
    end
end

function accStat = get_statistics(classAcc1, classAcc2, setType, group_inx, kappa)
    acc1 = classAcc1.(setType)(group_inx);
    acc2  = classAcc2.(setType)(group_inx);
    accDiff = acc1-acc2;
    accStat.Name1 = string(classAcc1.Name);
    accStat.Name2 = string(classAcc2.Name);
    accStat.kappa = kappa;
    accStat.nSubjects = sum(group_inx);
    accStat.acc1mean = mean(acc1);
    accStat.acc1std = std(acc1);
    accStat.acc1med = median(acc1);
    accStat.acc2mean = mean(acc2);
    accStat.acc2std = std(acc2);
    accStat.acc2med = median(acc2);    
    accStat.diffmean = mean(accDiff);
    accStat.diffstd = std(accDiff);
    accStat.diffmed = median(accDiff);  
    [~,accStat.p_val] = ttest(acc1,acc2); 
end
