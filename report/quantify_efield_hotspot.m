function quantify_efield_hotspot(codedir, sub, root, conditions_str, Ein)
    % This function quantifies efield hotspots for given conditions.
    % Input arguments:
    % - codedir: Directory containing the code.
    % - sub: Subject identifier.
    % - root: Root directory for subject data.
    % - conditions_str: Comma-separated string of conditions.
    disp("starting...")

    warning('off', 'all'); % Turn off all warnings


    % Parse the comma-separated conditions string into a cell array
    conditions = strsplit(conditions_str, ',');
        
    % Add the toolbox path
    addpath(genpath([codedir '/ncf_tools/cifti-matlab-master/']));

    % Define constants
    % Ein = 'EFIELD_BASELINE';
    wb = [codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command'];
    Colortable = readtable([root, '/MASKS/ColorMap_15.txt'], 'ReadVariableNames', true);

    % Define filenames and labels
    filename = 'BestCoilCenter+BestOrientation'; %+ActualDose
    label = ''; %'_ActualDose'
    Avoidance = 'A0';

    % Change directory to the subject's efield baseline directory
    cd([root '/' sub]);
    cd(Ein);

    % Open the functional networks file
    netfile = ['pfm/' sub '_FunctionalNetworks_32k.dtseries.nii'];
    net = ciftiopen(netfile, wb, 1);
    networks = net.cdata;

    % Define output directory for hotspot values
    oroot = [root '/' sub '/' Ein '/report/hotspot_values'];
    if ~exist(oroot, 'dir')
        mkdir(oroot);
    end

    % Loop through each condition
    for c = 1:length(conditions)
        condition = conditions{c};

        % Define the efield file path
        efile = ['tans/' condition '/' Avoidance '/Optimize/magnE_' filename '.dtseries.nii'];
        ef = ciftiopen(efile, wb, 1);
        efield = ef.cdata;

        % Define the output directory and converted file path
        OutDir = ['tans/' condition '/' Avoidance '/Optimize_forplot/'];
        efile_converted = [OutDir 'magnE_' filename '_converted.dtseries.nii'];

        % Create the converted efile folder if it doesn't exist
        if ~exist([OutDir efile_converted], 'file')
            mkdir(OutDir);
        end

        system(['module load wb_contain && wb_contain -v 1.5.0 wb_command -cifti-create-dense-from-template ' ...
                netfile ' ' efile_converted ' -series 1 1 -cifti ' efile]);

        % Open the converted efile
        ef_converted = ciftiopen(efile_converted, wb, 1);
        efield_converted = ef_converted.cdata;

        % Get non-zero values of the efield
        Egrid_vector_nonzero = nonzeros(efield_converted);

        % Initialize threshold and counts arrays
        thr = [];
        counts = [];
        egrids = {};

        % Loop for efield thresholding
        for d = 0:9
            t = 99 + d / 10;
            val = prctile(Egrid_vector_nonzero, t);
            thr = [thr, val];
            egrid = efield_converted > val;
            egrids{d + 1} = egrid;
            n = sum(egrid(:));
            counts = [counts, n];
        end

        % Initialize table for network statistics
        stats_net = table();

        % Loop through each network
        for i = 1:15
            single_net = networks;
            indices_zero = find(single_net ~= i);
            single_net(indices_zero) = 0;
            indices_bin = find(single_net ~= 0);
            single_net(indices_bin) = 1;

            % Mask the efield with the network
            Egrid_masked = efield_converted .* single_net;

            % Populate the statistics table
            stats_net(i, 1) = Colortable.LabelName(Colortable.No == i);
            stats_net(i, 2) = num2cell(min(nonzeros(Egrid_masked(:))));
            stats_net(i, 3) = num2cell(max(Egrid_masked(:)));
            stats_net(i, 4) = num2cell(mean(nonzeros(Egrid_masked), 'all'));

            % Loop through each threshold
            for j = 1:10
                Egrid_thr = egrids{j};
                Egrid_thr_masked = Egrid_thr .* single_net;
                hotspotsize = counts(j);
                stats_net(i, 4 + j) = num2cell(sum(Egrid_thr_masked(:)) / hotspotsize * 100);
            end
        end

        % Define column names for the statistics table
        stats_net.Properties.VariableNames = {'Network', 'Min', 'Max', 'Mean', 'V_p99.0', 'V_p99.1', 'V_p99.2', 'V_p99.3', 'V_p99.4', 'V_p99.5', 'V_p99.6', 'V_p99.7', 'V_p99.8', 'V_p99.9'};

        % Remove 'Network_' from the condition name
        newcond = erase(condition, 'Network_');
        
        % Write the statistics table to a CSV file
        writetable(stats_net, [oroot '/' sub '_' newcond '_' Avoidance '_hotspotval' label '.csv']);
    end
    disp("Successfully finished saving efield thresholded values.")
    warning('on', 'all'); % Turn on all warnings

end
