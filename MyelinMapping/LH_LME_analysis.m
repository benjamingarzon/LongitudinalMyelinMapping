clear all
close all

% design matrix and contrasts
% M is a matrix with cols : time, group,
design = @(M)[ones(length(M),1) M(:,1)];
RFX = [1];
contrast = [0 1];

SUBJECTS_DIR = '/home/share/Left-HandStudy/recon';
WORK_DIR = '/home/share/Left-HandStudy/stats';
qdec_file = fullfile(WORK_DIR, 'qdec.table.ok.dat');

% loop through  metrics
metrics = {'myelin','thickness','QSM','r2star'};
for i = 1:numel(metrics)
    metric = metrics{i};
    display(metric)
    cd(fullfile(WORK_DIR, metric));
    for hemi={'lh','rh'};
        
        hemi = hemi{1};
        sphere_file = fullfile(SUBJECTS_DIR, 'fsaverage/surf/', [hemi '.sphere']); 
        cortex_file = fullfile(SUBJECTS_DIR, 'fsaverage/label/', [hemi '.cortex.label']); 
        data_file = [ hemi '.' metric '.fsaverage.mgz'];
        
        beta_files = {[hemi '.beta1.mgz'], [hemi '.beta2.mgz']};
        beta_indices = [1 2];
        
        sig_file = [hemi '.sig.mgz'];
        fdr_file = [hemi '.fdr.mgz'];
        fig_file = [hemi '.rg.jpg'];
        
        fitLME(data_file, sphere_file, cortex_file, qdec_file, beta_files, beta_indices, sig_file, fdr_file, fig_file, RFX, design, contrast);
    end
end