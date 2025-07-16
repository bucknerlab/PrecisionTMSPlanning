function make_sgACC_corr_networks(codedir, sub, datadir, efieldfolder, threshold)
% Add the toolbox path
addpath(genpath([codedir '/ncf_tools/cifti-matlab-master/']));
wb = [codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command'];


% Define parameters
coroot = [datadir '/' sub '/' efieldfolder '/anticorrelations/fsaverage_LR32k/r2z/'];
outdir = [datadir '/' sub '/' efieldfolder '/'];

corfile = [coroot sub '_sgACC_correlations_r2z_32k.dtseries.nii'];
cor = ciftiopen(corfile, wb, 1);
cordata = cor.cdata;

dlpfcfile = [datadir '/MASKS/fsaverage_LR32k/BA46_30mm_dorsal2_noinsula_nomedial_32k.lh.dtseries.nii'];
dlpfc = ciftiopen(dlpfcfile, wb, 1);
dlpfcdata = dlpfc.cdata;
indices_dlpfc=find(dlpfcdata == 1);

indices_pos = find(cordata > 0);
cordata(indices_pos) = 2;
indices_neg = find(cordata < 0);
cordata(indices_neg) = 1;

outfile = [outdir 'pfm/' sub  '_sgACCNetworks_32k_orig_zr0.dtseries.nii'];
cor.cdata=cordata;

ciftisavereset(cor,outfile,wb);

cor = ciftiopen(corfile, wb, 1);
cordata2 = cor.cdata;

% restrict to dlpfc
data_dlpfc = cordata2(indices_dlpfc);
% Remove NaN values
data_no_nan = data_dlpfc(~isnan(data_dlpfc));
% Filter for negative values
negative_values = data_no_nan(data_no_nan < 0);


array = [10, 20, 30, 40, 50, 60];

for i = 1:length(array)
    cor = ciftiopen(corfile, wb, 1);
    cordata2 = cor.cdata;
    thresh = array(i);
    disp(thresh)
    percentile = prctile(negative_values, thresh);
    indices_pos = find(cordata2 > percentile);
    cordata2(indices_pos) = 2;
    indices_neg = find(cordata2 <= percentile);
    cordata2(indices_neg) = 1;    
    outfile2 = [outdir 'pfm/' sub  '_sgACCNetworks_32k_top' int2str(thresh) 'th_dlpfc.dtseries.nii'];
    cor.cdata=cordata2;
    ciftisavereset(cor,outfile2,wb);
    
    if thresh == str2double(threshold)
        disp(['Saving main network file at ' int2str(thresh) ' percentile'])
        outfile3 = [outdir 'pfm/' sub  '_sgACCNetworks_32k.dtseries.nii'];
        ciftisavereset(cor,outfile3,wb);
    end
end



disp("Successfully finished making sgACC anticorrelated regions.")

end
