%
function [central_chan_data, isSimSuccess] = variate_augmentation(NFTparams, Spectra, project_params, iChan, n_aug_trials, trial_len_sec)

central_chan_data = [];

% project_params.augmentation.n_trials_same_params = n_aug_trials; %no variation
project_params.minSectLenSec = project_params.augmentation.n_trials_same_params*trial_len_sec;
origNFTparams = NFTparams;
for iChunk = 1:ceil(n_aug_trials/project_params.augmentation.n_trials_same_params)
    
    if iChunk == 1
        NFTparams = origNFTparams;
    else
        for iParam = 1:length(project_params.augmentation.params_to_vary)
            p = origNFTparams.(project_params.augmentation.params_to_vary{iParam})(1)*...
                unifrnd((1-project_params.augmentation.variation_factor),(1+project_params.augmentation.variation_factor));
            p = min(max(p, project_params.augmentation.params_lim{iParam}(1)), project_params.augmentation.params_lim{iParam}(2));
            NFTparams.(project_params.augmentation.params_to_vary{iParam}) = p + 0*NFTparams.(project_params.augmentation.params_to_vary{iParam}); 
        end
    end

    [~, ~, central_chan_data_chunk, isSimSuccess] = simulate_nft(NFTparams, Spectra, project_params, iChan, 0);
    if ~isSimSuccess
        s=rng; rng(randi(100));
        [~, ~, central_chan_data_chunk, isSimSuccess] = simulate_nft(NFTparams, Spectra, project_params, iChan, 0);
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
