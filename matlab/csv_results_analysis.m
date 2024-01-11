clear all; close all; clc;

train100thresh = 0; % 0.2 %kappa threshold for filtering
valid50thresh = 0.05:0.05:0.95; %kappa threshold for grouping
setType = 'valid';

kappa = []; % if empty, search the best kappa
p_alpha = 0.05;

fp = 'C:\My Files\Work\BGU\Datasets\drone BCI\2a\';
out_fn = 'aumentation_summary.xlsx';

project_params = augmentation_params();
project_params.grapics.axisLabelFntSz = 30;
project_params.grapics.axisTickFntSz = 30;

plot_flg = false;
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
    augName = 'x2TypFit_Small33cls2CSPBandPower_classResults';
    iAug = strcmp({classAug.Name},augName);
    kappa = resSumary.kappa(strcmp(resSumary.Name1,augName) & resSumary.kappa>0);
    group_inx = good_subj_inx & classAug(iAug).(setType)>=kappa(1);
    boxData = [classFull.(setType)(group_inx), classSmall.(setType)(group_inx),...
        classAug(iAug).(setType)(group_inx)];

    figure; hold on;
    bc = boxchart(boxData, 'LineWidth',3.5);%boxplot(boxData,labels);
    plot(mean(boxData,1),"diamond", 'MarkerFaceColor','r');
    yline(mean(boxData(:,1)),'--', 'Color',"#FF00FF",'LineWidth',2.5);
    yline(median(boxData(:,1)),'--', 'Color',"#00FF00",'LineWidth',2.5);
    yline(mean(boxData(:,2)),'--', 'Color',"#D95319", 'LineWidth',2.5);
    yline(median(boxData(:,2)),'--', 'Color',"#EDB120", 'LineWidth',2.5);
    hold off;
    title(['Augmentation Strategies: ' augName], 'FontSize',project_params.grapics.titleFntSz);
    xticklabels([{'Full','Small'},augName]); ax = gca; ax.FontSize = project_params.grapics.axisTickFntSz-4;
    ylabel('\kappa', 'FontSize',project_params.grapics.axisLabelFntSz+2); ylim([-1,1]);
    legend({'','average','Full average','Full median','Small average','Small median'}, 'NumColumns',2, 'FontSize',project_params.grapics.axisLabelFntSz-6, 'Location','southeast');
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
