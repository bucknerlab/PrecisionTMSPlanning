function make_sgACC_ROIs(codedir, sub, datadir, iprocdir, efieldfolder)
    % This function makes an SNR-masked (>20) sgACC ROI for a given subject.
    % Input arguments:
    % - codedir: Directory containing the code and tools.
    % - SUB: Subject identifier.
    % - datadir: Directory containing the data.
    % - iprocdir: Directory containing the processed MRI data.
    % - efieldfolder: Directory containing the efield data.

    % Add the toolbox path
    addpath(genpath([codedir '/ncf_tools/cifti-matlab-master/']));
    wb = [codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command'];

    % Define the directory for SNR maps
    snroot = [datadir '/' sub '/' iprocdir '/MRI/SNR/'];

    % Define output directory for sgACC ROI
    outdir=[datadir '/' sub '/' efieldfolder '/anticorrelations/'];

    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end

    % open the bilateral Fox sgACC ROI 
    sgacc = ciftiopen([datadir '/MASKS/FS6/Fox_r10_sgACC_bilateral_MNI2fs6.dscalar.nii'],wb,1);
    sgdata = sgacc.cdata;
    
    % Open a CIFTI template file
    g = ciftiopen([codedir '/ncf_tools/fsaverage6/surf/fsaverage6_cifti_template.dscalar.nii'], wb, 1);

    %open the SNR file
    snrfile = [snroot '/' sub '_SNR.dscalar.nii'];
    snr = ciftiopen(snrfile, wb, 1);
    snrdata = snr.cdata;

    indices_low = find(snrdata < 20);
    snrdata(indices_low) = 0;
    indices_bin = find(snrdata ~= 0);
    snrdata(indices_bin) = 1;

    %mask the ROI to exclude vertices <20 SNR
    sg_masked = sgdata .* snrdata;

    outfile = [outdir '/' sub '_sgACC.dscalar.nii'];

    g.cdata=sg_masked;

    ciftisavereset(g,outfile,wb);
    disp("Successfully finished making sgACC ROI after masking with SNR map.")

end
              