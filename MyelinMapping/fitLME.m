function fitLME(data_file, sphere_file, cortex_file, qdec_file, beta_files, beta_indices, sig_file, fdr_file, fig_file, RFX, design, contrast)
addpath /home/share/Software/freesurferHCP/matlab/lme


[Y,mri] = fs_read_Y(data_file);
Qdec = fReadQdec(qdec_file);
Qdec = rmQdecCol(Qdec,1);
sID = Qdec(2:end,1);
Qdec = rmQdecCol(Qdec,1);
M = Qdec2num(Qdec);
[M,Y,ni] = sortData(M,1,Y,sID);

X = design(M);

sphere = fs_read_surf(sphere_file);
cortex = fs_read_label(cortex_file);

[Th0,Re] = lme_mass_fit_EMinit(X,RFX,Y,ni,cortex, 5, 1);
[Rgs,RgMeans] = lme_mass_RgGrow(sphere,Re,Th0,cortex,2,95);

surf.faces = sphere.tri;
surf.vertices = sphere.coord';

% print out
figure;
subplot(1,2,1)
p1 = patch(surf);
set(p1,'facecolor','interp','edgecolor','none','facevertexcdata',Th0(1,:)');
title('Original')
subplot(1,2,2)
p2 = patch(surf);
set(p2,'facecolor','interp','edgecolor','none','facevertexcdata',RgMeans(1,:)');
title('Segmented')

saveas(gcf, fig_file)
close all
stats = lme_mass_fit_Rgw(X,RFX,Y,ni,Th0,Rgs,sphere);

CM.C = contrast;
F_stats = lme_mass_F(stats,CM);

fs_write_fstats(F_stats,mri,sig_file,'sig');

% FDR correction
mri1 = mri;
mri1.volsz(4) = 1;

[detvtx,sided_pval,pth] = lme_mass_FDR2(F_stats.pval,F_stats.sgn,cortex,0.05,0);
fs_write_Y(sided_pval,mri1,fdr_file);

% write out parameter estimates
nv=length(stats);
for index=1:numel(beta_indices)
    Beta = zeros(1,nv);
    for i=1:nv
        if ~isempty(stats(i).Bhat)
            Beta(i) = stats(i).Bhat(beta_indices(index));
        end;
    end;
    
    fs_write_Y(Beta, mri1, beta_files{index});
end

end






