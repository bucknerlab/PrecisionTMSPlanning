function sgacc_corr_sequence(codedir, sub, sess, datadir, iprocdir, efieldfolder, threshold)
    % sgacc_corr_sequence - Executes a sequence of functions for sgACC correlation analysis.
    %
    % Syntax: sgacc_corr_sequence(codedir, sub, sess, datadir, iprocdir, efieldfolder)
    %
    % Inputs:
    %    codedir - Directory containing the code
    %    sub - Subject ID
    %    sess - Session identifier
    %    datadir - Directory containing overall subject data
    %    iprocdir - Directory containing preprocessed fMRI data
    %    efieldfolder - Directory containing electric field data
    %
    % Example:
    %    sgacc_corr_sequence('/path/to/code', 'subject1', 'session1', '/path/to/data', '/path/to/iprocdir', '/path/to/efield')
    
    % Validate inputs
    if nargin ~= 7
        error('All 7 input arguments are required.');
    end
    
    % Add the toolbox path
    addpath(genpath([codedir '/sgacc_corr/']));
    
    try
        % Call SNR_map function
        SNR_map(codedir, sub, datadir, iprocdir);
        
        % Call make_sgACC_ROIs function
        make_sgACC_ROIs(codedir, sub, datadir, iprocdir, efieldfolder);
        
        % Call average_fc_for_sgACC function
        fc_sgACC_average_ts(codedir, sub, sess, datadir, efieldfolder);
        
        % Run the bash script
        system(['bash ' codedir '/sgacc_corr/sgACC_corr_fs6_2_fsLR.sh ' sub ' ' codedir ' ' datadir ' ' efieldfolder]);
        
        % Call make_sgACC_corr_networks function
        make_sgACC_corr_networks(codedir, sub, datadir, efieldfolder, threshold);
    catch ME
        error('An error occurred: %s', ME.message);
    end
end
