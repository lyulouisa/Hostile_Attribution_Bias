%% Run Classification analysis by single channel
clear all

addpath(genpath('../../2_scripts/9_help_scripts'));

%% Specify pre-processing parameters and file paths
classification = 1;
permutation = 1;

behavDir = '../../1_data/1_behav';
dataDir = strcat('../../1_data/2_fNIRs_preprocessed/');

load(strcat(dataDir, '/', 'all_oxy.mat'))
load(strcat(dataDir, '/', 'sublst.mat'))

nChannel = 20;

%% Classification analysis
if classification
    % Read behavioral data
    load(fullfile('../../1_data/1_behav/mean_scores.mat'));
    host_scores = mean_scores(:,4);
    
    host_subj = host_scores > median(host_scores);
    benign_subj = host_scores < median(host_scores);
    
    ch_acc_subj = NaN(nChannel,length(sublst));
    
    % Loop over subjects
    for i = 1:length(sublst)
        
        thisData = squeeze(all_oxy(i,:,:));
        thisLabel = host_subj(i); % True Label: 1 = Hostile, 0 = Benign
        missingChannels = isnan(thisData(1,:));
        
        thisHost = host_subj; thisBenign = benign_subj;
        thisHost(i) = 0; thisBenign(i) = 0;
       
        avgHost = squeeze(nanmean(all_oxy(thisHost,:,:)));
        avgBenign = squeeze(nanmean(all_oxy(thisBenign,:,:)));
        
        HostCorr = corr_col(thisData,avgHost);
        BenignCorr = corr_col(thisData,avgBenign);
        
        ClassHost = HostCorr > BenignCorr;
        ch_acc_subj(:,i) = ClassHost == thisLabel;
        
        % make nanchannels NaN
        ch_acc_subj(missingChannels,i) = NaN;
        
    end
    
    ch_acc = nanmean(ch_acc_subj,2); 
    
    save(strcat(dataDir, '/', 'ch_acc.mat'), 'ch_acc','host_subj','host_scores','benign_subj','subDirs');
 
end

%% Permutation
if permutation
    
    load(strcat(dataDir, '/', 'ch_acc.mat'));
    
    nIteration = 10000;
    fake_ch_acc = NaN(nChannel, nIteration);
    
    for iteration = 1:nIteration
        if mod(iteration, 10) == 0
            fprintf('Iteration %i \n', iteration);
        end
        
        fake_host = host_subj(randperm(length(host_subj)));
        fake_benign = ~fake_host;
        
        fake_ch_acc_subj = NaN(nChannel,length(subDirs));
        
        % Loop over subjects
        for i = 1:length(subDirs)
            
            thisData = squeeze(all_oxy(i,:,:));
            thisLabel = fake_host(i); % True Label: 1 = Hostile, 0 = Benign
            missingChannels = isnan(thisData(1,:));
            
            thisHost = fake_host; thisBenign = fake_benign;
            thisHost(i) = 0; thisBenign(i) = 0;
            
            avgHost = squeeze(nanmean(all_oxy(thisHost,:,:)));
            avgBenign = squeeze(nanmean(all_oxy(thisBenign,:,:)));
            
            HostCorr = corr_col(thisData,avgHost);
            BenignCorr = corr_col(thisData,avgBenign);
            
            ClassHost = HostCorr > BenignCorr;
            fake_ch_acc_subj(:,i) = ClassHost == thisLabel;
            
            % make nanchannels NaN
            fake_ch_acc_subj(missingChannels,i) = NaN;
            
        end
        
        fake_ch_acc(:,iteration) = nanmean(fake_ch_acc_subj,2); 
    end
    
    p_value = (sum(fake_ch_acc > ch_acc,2) + 1)/nIteration;
    
    save(strcat(dataDir, '/', 'ch_acc_permutation.mat'), 'fake_ch_acc','p_value');
    
end
    