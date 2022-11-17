% single trials fit statistics
function inspect_trials_fit(EEG, project_params, iLabel, iChan)

ResTable = table();
for iTrial=1:EEG.trials
    EEG1trial = pop_select(EEG, 'trial',iTrial);
    [NFTparams, Spectra] = fit_nft(EEG1trial, project_params, iChan, 0);

%     figure;
%     loglog(Spectra.f,mean(Spectra.P,1), Spectra.f_fit,mean(Spectra.P_fit,1));
%     xlabel('Hz'); legend('experimental','fitted');

    subj.pGee = NFTparams.gab(1);
    subj.pGei = NFTparams.gab(2);
    subj.pGes = NFTparams.gab(3);
    subj.pGse = NFTparams.gab(4);
    subj.pGsr = NFTparams.gab(5);
    subj.pGsn = NFTparams.gab(6);
    subj.pGre = NFTparams.gab(7);
    subj.pGrs = NFTparams.gab(8);
    subj.pGese = NFTparams.gabcd(3);
    subj.pGesre = NFTparams.gabcd(4);
    subj.pGsrs = NFTparams.gabcd(5);
    subj.pGeei = NFTparams.gab(1)/NFTparams.gab(2);
    subj.pAlpha = NFTparams.alpha(1);
    subj.pBeta = NFTparams.beta(1);
    subj.pT0 = NFTparams.t0;
    subj.pEmga = NFTparams.emg_a;
    subj.pX = NFTparams.xyz(1);
    subj.pY = NFTparams.xyz(2);
    subj.pZ = NFTparams.xyz(3);
    subj.pXYsum = NFTparams.xyz(1) + NFTparams.xyz(2);
    subj.pXYdif = NFTparams.xyz(1) - NFTparams.xyz(2);
    ResTable = [ResTable; struct2table(subj)];
end

histogram(ResTable.pGee);




