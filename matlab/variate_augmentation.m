%
% Augments a channel. Variates NFT parameters
%
function [central_chan_data, isSimSuccess] = variate_augmentation(NFTparams, Spectra, project_params, iChan, n_aug_trials, trial_len_sec)

project_params.minSectLenSec = ceil(n_aug_trials/project_params.augmentation.n_variations)*trial_len_sec;

central_chan_data = [];
NFTparams = struct(NFTparams);
for iChunk = 1:project_params.augmentation.n_variations
    %set parameters
    simNFTparams = model.params(NFTparams); %copy
%     simNFTparams = NFTparams; %reference
    if iChunk > 1 %no NFT parameters variation at the first chunk
        for iParam = 1:size(project_params.augmentation.params2vary,1)
            pName = project_params.augmentation.params2vary{iParam,1};
            pVal = normrnd(NFTparams.(pName)(1), project_params.augmentation.params2vary{iParam,3}*(1+project_params.augmentation.variation_factor));
            pVal = min(max(pVal, project_params.augmentation.params2vary{iParam,2}(1)), project_params.augmentation.params2vary{iParam,2}(2));
            simNFTparams.(pName)(:) = pVal; 
        end
    end

    %simulate chunk
    [~, ~, central_chan_data_chunk, isSimSuccess] = simulate_nft(simNFTparams, Spectra, project_params, iChan, 0);
    if ~isSimSuccess
        s=rng; rng(randi(100));
        [~, ~, central_chan_data_chunk, isSimSuccess] = simulate_nft(simNFTparams, Spectra, project_params, iChan, 0);
        rng(s);
    end
    if ~isSimSuccess 
        if iChunk == 1
            error('First Chunk Augmentation Failure!');
        else
            central_chan_data_chunk = prev_central_chan_data_chunk;
        end
    end
    central_chan_data = cat(2,central_chan_data, central_chan_data_chunk);
    prev_central_chan_data_chunk = central_chan_data_chunk;
end

central_chan_data = central_chan_data(1:n_aug_trials * trial_len_sec * project_params.fs); %truncate
