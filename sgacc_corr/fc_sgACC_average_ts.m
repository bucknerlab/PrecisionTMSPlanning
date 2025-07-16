function fc_sgACC_average_ts(codedir, sub, sess, datadir, efieldfolder)

addpath(genpath([codedir '/ncf_tools/cifti-matlab-master/']));
addpath(genpath(fullfile([codedir '/MSHBM'])))


wb = [codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command'];

roidir=[datadir '/' sub '/' efieldfolder '/anticorrelations/'];
root = [datadir '/' sub '/' sub '_' sess '/NETWORKS/correlation_matrix/'];
% Create the directory if it doesn't exist
if ~exist(root, 'dir')
    mkdir(root);
end
fixation_path = [datadir '/' sub '/' sub '_' sess '/NETWORKS/baseline_rest_input/' sub];

cifti=ciftiopen([roidir sub '_sgACC.dscalar.nii'],'wb_command');
ROI_label=cifti.cdata;


lhdirlist = dir([fixation_path '/lh*nat_resid_bpss_fsaverage6_sm*.nii.gz']);
rhdirlist = dir([fixation_path '/rh*nat_resid_bpss_fsaverage6_sm*.nii.gz']);
roi_ts=[]; roi_ts_all = []; zcorr_mat_all= [];
for i = 1:length(lhdirlist)
    i
    input_lh = [lhdirlist(i).folder '/' lhdirlist(i).name];
    input_rh = [rhdirlist(i).folder '/' rhdirlist(i).name];
    [~, t_series_lh, ~] = read_fmri(input_lh);
    [~, t_series_rh, ~] = read_fmri(input_rh);
    wholebraint_series = [t_series_lh;t_series_rh];
    roi_ts = mean(wholebraint_series(ROI_label==1,:),1,'omitnan');
    zcorr_mat = atanh(CBIG_corr(roi_ts', wholebraint_series'));
    roi_ts_all(i,:) = roi_ts;
    zcorr_mat_all(i,:) = zcorr_mat;
end

save([root,'sgACC_ts_corr.mat'],'roi_ts_all','zcorr_mat_all');

zcorr_roi_avg = mean(zcorr_mat_all,'omitnan');

g = ciftiopen([codedir '/ncf_tools/fsaverage6/surf/fsaverage6_cifti_template.dscalar.nii'], wb, 1);
g.cdata=[zcorr_roi_avg'];

ciftisavereset(g,fullfile([roidir '/' sub '_sgACC_correlations_r2z.dscalar.nii']),wb);

disp("Successfully finished making sgACC correlation map.")

end
%
