close all
clear all
hemi='rh'
cd('/home/share/Left-HandStudy/stats/myelin')
SUBJECTS_DIR = '/home/share/Left-HandStudy/recon';
cortex_file = fullfile(SUBJECTS_DIR, 'fsaverage/label/', [hemi '.cortex.label']); 

data_file = 'lh.myelin.unorm.fsaverage.mgz';
output_file = 'lh.myelin.fsaverage.mgz';

[Y, mri] = fs_read_Y(data_file);
cortex = fs_read_label(cortex_file);
Z = Y(:,cortex)';

C = corr(Z);
figure
imagesc(C)
colorbar

%% normalization
for i =1:size(Z, 2)
    x = Z(:, i);
    y = (x - mean(x))/std(x);
    
    %M = [ones(size(x)), x];
    %[b,bint,r,rint,stats] = regress(y2, M);
    M(:, i) = y;
end

%figure
%plotmatrix(M(1:100:end,:))

Y = Y*0;
Y(:, cortex) = M';

fs_write_Y(Y, mri, output_file);

%plot(M(1:100:end,3), M(1:100:end,4),'.'), axis equal, line([-10, 10], [-10 10])
