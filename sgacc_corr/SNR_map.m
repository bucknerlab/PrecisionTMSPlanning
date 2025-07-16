function SNR_map(codedir, SUB, datadir, iprocdir)
    % This function calculates the Signal-to-Noise Ratio (SNR) map for a given subject.
    % Input arguments:
    % - codedir: Directory containing the code and tools.
    % - SUB: Subject identifier.
    % - datadir: Directory containing the data.
    % - iprocdir: Directory containing the processed MRI data.

    % Add the toolbox path
    addpath(genpath([codedir '/ncf_tools/cifti-matlab-master/']));
    wb = [codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command'];

    % Define the output directory for SNR maps
    outdir = [datadir '/' SUB '/' iprocdir '/MRI/SNR/'];

    % Create the output directory if it doesn't exist
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end

    % Change directory to the subject's MRI directory
    cd(fullfile([datadir '/' SUB '/' iprocdir '/MRI/' SUB '/FS6/']));

    % List left and right hemisphere NIFTI files
    lhdirlist = dir('*/REST*/lh*_reorient_skip_mc_unwarp_anat_fsaverage6_sm*.nii.gz');
    rhdirlist = dir('*/REST*/rh*_reorient_skip_mc_unwarp_anat_fsaverage6_sm*.nii.gz');

    % Check if lhdirlist is empty and handle the error
    if isempty(lhdirlist)
        disp("ERROR: no REST runs found for SNR map.");
        return;
    end

    % Initialize arrays to store SNR data for each hemisphere
    SNRsub_lh = [];
    SNRsub_rh = [];

    % Loop through each left hemisphere file
    for i = 1:length(lhdirlist)
        % Read NIFTI data for left and right hemispheres
        tempnii_lh = niftiread([lhdirlist(i).folder '/' lhdirlist(i).name]);
        tempnii_rh = niftiread([rhdirlist(i).folder '/' rhdirlist(i).name]);

        % Reshape the 4D data into 2D (voxels by time)
        tempniiR_lh = reshape(tempnii_lh, [size(tempnii_lh, 1) * size(tempnii_lh, 2) * size(tempnii_lh, 3), size(tempnii_lh, 4)]);
        tempniiR_rh = reshape(tempnii_rh, [size(tempnii_rh, 1) * size(tempnii_rh, 2) * size(tempnii_rh, 3), size(tempnii_rh, 4)]);

        % Initialize arrays to store SNR values for each voxel
        tempSNR_lh = zeros(1, size(tempniiR_lh, 1));
        tempSNR_rh = zeros(1, size(tempniiR_rh, 1));

        % Calculate SNR for each voxel
        for j = 1:size(tempniiR_lh, 1)
            tempvert_lh = tempniiR_lh(j, :);
            tempvert_rh = tempniiR_rh(j, :);

            if sum(tempvert_lh) == 0
                tempSNR_lh(j) = 0;
            else
                tempSNR_lh(j) = mean(tempvert_lh) / std(tempvert_lh);
            end

            if sum(tempvert_rh) == 0
                tempSNR_rh(j) = 0;
            else
                tempSNR_rh(j) = mean(tempvert_rh) / std(tempvert_rh);
            end
        end

        % Store the SNR values for each subject
        SNRsub_lh(i, :) = tempSNR_lh;
        SNRsub_rh(i, :) = tempSNR_rh;
    end

    % Calculate the mean SNR across all subjects
    SNRmsub_lh = mean(SNRsub_lh);
    SNRmsub_rh = mean(SNRsub_rh);

    % Change directory to the output directory
    cd(outdir);

    % Open a CIFTI template file
    g = ciftiopen([codedir '/ncf_tools/fsaverage6/surf/fsaverage6_cifti_template.dscalar.nii'], wb, 1);

    % Assign the mean SNR values to the CIFTI data
    g.cdata = [SNRmsub_lh'; SNRmsub_rh'];

    % Define the output filename
    outname = [SUB '_SNR'];

    % Save the SNR data to a CIFTI file
    ciftisavereset(g, [outdir outname '.dscalar.nii'], wb);

    disp("Successfully finished making SNR map.")
end
