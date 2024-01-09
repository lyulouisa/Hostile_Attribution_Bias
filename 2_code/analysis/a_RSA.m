%% RSA

clear all

run_rsa = 1;
RSA_Type = 'NN'; % NN = Nearest Neighbor, AnnaK
NeuralDistance = 'corr'; % corr, ED

behavDir = '../../1_data/1_behav';
dataDir = strcat('../../1_data/2_fNIRs_preprocessed/');

load(strcat(dataDir, '/', 'all_oxy.mat'))
load(strcat(dataDir, '/', 'sublst.mat'))

lowTri_indx = ~triu(ones(length(subDirs),length(subDirs)));

%% Run RSA
if run_rsa 

    channel_r = NaN(20,1);
    
    % Create behavioral distance matrix
    load(fullfile('../../1_data/1_behav/mean_scores.mat'));
    host_scores = mean_scores(:,4);
    
    behav_matrix = NaN(length(subDirs),length(subDirs));
    
    for i = 1:length(subDirs)
       for j = 1:length(subDirs)
           
           switch RSA_Type
               
               case 'NN'
                    behav_matrix(i,j) = abs(host_scores(i) - host_scores(j));
                
               case 'AnnaK'
                    behav_matrix(i,j) = mean([host_scores(i),host_scores(j)]);
                
           end
           
       end
    end
    
    behav_vector = behav_matrix(lowTri_indx);
       
    % create neural dissimilarity matrix
    for ch = 1:20
        
        this_channel = squeeze(all_oxy(:,:,ch));
        
        switch NeuralDistance
            case 'corr'
                all_distance(ch,:) = pdist(this_channel,'correlation');
                
            case 'ED'
                all_distance(ch,:) = pdist(this_channel,'euclidean');
        end
        
        channel_r(ch,1) = nancorr(behav_vector', all_distance(ch,:)');
        
    end
    
    % Run Shuffling Analysis
    n_iteration = 10000;
    r_counter = zeros(20,1);
    
    for k = 1:n_iteration
        
        fake_channel_r = NaN(20,1);
        
        if mod(k,100) == 0
            fprintf('Iteration = %i \n', k);
        end
        
        % shuffle behavioral vector
        shuffle_idx = randperm(length(host_scores));
        fake_behav_matrix = behav_matrix(shuffle_idx,shuffle_idx);
        
        fake_host_dist = fake_behav_matrix(lowTri_indx);
                
        for ch = 1:20
            
            fake_channel_r(ch,1) = nancorr(fake_host_dist', all_distance(ch,:)');
            
        end
        
        r_greater_than = fake_channel_r > channel_r;
        
        r_counter = r_counter + r_greater_than;

    end
    
    p_value = (r_counter + 1)/n_iteration;
    
    save(sprintf('%s/RSA_%s_%s',dataDir, NeuralDistance,RSA_Type),'channel_r','p_value','n_iteration');

end

[M, i] = min(p_value);
fprintf('Minumum p-value = %0.3f,at Channel %i\n', M, i);
fdr_bky(p_value,0.05,'yes');

