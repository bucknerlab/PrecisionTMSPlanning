function extract_efield_values(codedir, sub, root, conditions_str, Ein)
    % This function extracts efield values for given conditions.
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
    oroot = [root '/' sub '/' Ein '/report/efield_values'];
    if ~exist(oroot, 'dir')
        mkdir(oroot);
    end

    networks_size = sum(networks~=0);
    
    % Loop through each condition
    for c=1:length(conditions)
        stats_net = table('size',[networks_size 3],'VariableTypes',["string","string","double"],'VariableNames',{'Subject','Network','EfieldVal'});
        nrow = 1;
        
        efile = ['tans/' conditions{c} '/' Avoidance '/Optimize/magnE_' filename '.dtseries.nii'];
        ef = ciftiopen(efile, wb, 1);
        efield = ef.cdata;

        OutDir = ['tans/' conditions{c} '/' Avoidance '/Optimize_forplot/'];
        efile_converted = [OutDir 'magnE_' filename '_converted.dtseries.nii'];

         % Create the converted efile folder if it doesn't exist
         if ~exist([OutDir efile_converted], 'file')
             mkdir(OutDir);
         end

         system(['wb_contain -v 1.5.0 wb_command -cifti-create-dense-from-template ' ...
             netfile ' ' efile_converted ' -series 1 1 -cifti ' efile]);

        ef_converted = ciftiopen(efile_converted, wb, 1);
        efield_converted = ef_converted.cdata;

        for j=1:15
            single_net = networks;
            indices_zero = find(single_net~=j);
            single_net(indices_zero) = 0;
            indices_bin = find(single_net ~= 0);
            single_net(indices_bin) = 1;

            Egrid_masked = efield_converted(single_net==1);

            stats_net.Subject(nrow:(nrow-1+length(Egrid_masked))) = sub;
            stats_net.Network(nrow:(nrow-1+length(Egrid_masked))) = Colortable.LabelName(Colortable.No==j);
            stats_net.EfieldVal(nrow:(nrow-1+length(Egrid_masked))) = Egrid_masked;
            nrow=nrow+length(Egrid_masked);

        end
        newcond = erase(conditions{c},'Network_');
        writetable(stats_net,[oroot '/' sub '_' newcond '_' Avoidance '_efieldval' label '.csv']);

    end
    disp("Successfully finished saving efield values.")
end
