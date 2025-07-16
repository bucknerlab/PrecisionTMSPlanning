%% This code was adapted from the tans_example_use.m script of the TANS (Lynch et al., 2022) toolbox for the Sun, Billot, et al., 2025 Precision TMS pipeline

function tans_PROFETT(SUB, INDIR, HEAD, ROI, GRID, EFIELD, OPTIMIZE, DOSE, PARCEL, THRESH, TARGET, AVOID, SEARCH, OUTDIR, codedir, maskdir)
    % TANS processing

    % Define directories
    Paths{1} = [codedir '/simnibs/4.0.1/'];
    Paths{2} = [codedir '/Targeted-Functional-Network-Stimulation-1.0.1_v2/'];
    Paths{3} = [codedir '/MSCcodebase_master/Utilities/'];

    % Add the directories
    addpath(genpath(Paths{1}));
    addpath(genpath(Paths{2}));
    addpath(genpath(Paths{3}));
    addpath(genpath([codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64']));
    addpath(genpath([codedir '/ncf_tools/gifti-1.6/']));

    HEAD = str2double(HEAD);
    ROI = str2double(ROI);
    GRID = str2double(GRID);
    EFIELD = str2double(EFIELD);
    OPTIMIZE = str2double(OPTIMIZE);
    DOSE = str2double(DOSE);
    PARCEL = str2double(PARCEL);
    THRESH = str2double(THRESH);
    TARGET = str2double(TARGET);
    AVOID = str2double(AVOID);

    Subject = SUB;
    Path = INDIR;

    %% Create the head model
    if HEAD == 1
        T1w = [Path '/anat/T1w/mpr_reorient.nii.gz'];
        OutDir = [Path '/tans'];
        tans_headmodels(Subject, T1w, [], OutDir, Paths);
        fprintf('tans_headmodels step completed\n');
    end

    %% Identify the target Network Patch
    if ROI == 1
        if PARCEL == 2
            % FunctionalNetworks = ft_read_cifti_mod([Path '/pfm/' Subject '_sgACCNetworks_32k_top30th.dtseries.nii']);
            FunctionalNetworks = ft_read_cifti_mod([Path '/pfm/' Subject '_sgACCNetworks_32k.dtseries.nii']);
        elseif PARCEL == 15
            FunctionalNetworks = ft_read_cifti_mod([Path '/pfm/' Subject '_FunctionalNetworks_32k.dtseries.nii']);
        end

        TargetNetwork = FunctionalNetworks;

        if TARGET == 16 % SAL + CG OP
            TARGET1 = 2;
            TARGET2 = 14;
            TargetNetwork.data(~ismember(TargetNetwork.data, [TARGET1, TARGET2])) = 0;
        elseif TARGET == 18 % DNA + DNB
            TARGET1 = 15;
            TARGET2 = 3;
            TargetNetwork.data(~ismember(TargetNetwork.data, [TARGET1, TARGET2])) = 0;
        else
            TargetNetwork.data(TargetNetwork.data ~= TARGET) = 0; % note: 14 == SAL, 11 = FPN-A, DN-A = 15
        end

        TargetNetwork.data(TargetNetwork.data ~= 0) = 1; % binarize

        if strcmp(SEARCH, 'LH')
            SearchSpace = ft_read_cifti_mod('LPFC_LH.dtseries.nii');
        elseif strcmp(SEARCH, 'RH')
            SearchSpace = ft_read_cifti_mod('LPFC_RH.dtseries.nii');
        elseif strcmp(SEARCH, 'LBA46')
            SearchSpace = ft_read_cifti_mod([maskdir '/fsaverage_LR32k/BA46_30mm_noinsula_32k.lh.dtseries.nii']);
        elseif strcmp(SEARCH, 'RBA46')
            SearchSpace = ft_read_cifti_mod([maskdir '/fsaverage_LR32k/BA46_30mm_noinsula_32k.rh.dtseries.nii']);
        elseif strcmp(SEARCH, 'LBA46_d2')
            SearchSpace = ft_read_cifti_mod([maskdir '/fsaverage_LR32k/BA46_30mm_dorsal2_noinsula_nomedial_32k.lh.dtseries.nii']);
        elseif strcmp(SEARCH, 'RBA46_d2')
            SearchSpace = ft_read_cifti_mod([maskdir '/fsaverage_LR32k/BA46_30mm_dorsal2_noinsula_nomedial_32k.rh.dtseries.nii']);
        else
            SearchSpace = ft_read_cifti_mod('LPFC_LH+RH.dtseries.nii');
        end

        Sulc = ft_read_cifti_mod([Path '/anat/MNINonLinear/fsaverage_LR32k/' Subject '.sulc.32k_fs_LR.dscalar.nii']);
        VertexSurfaceArea = ft_read_cifti_mod([Path '/anat/T1w/fsaverage_LR32k/' Subject '.midthickness_va.32k_fs_LR.dscalar.nii']);

        SulcThresh = THRESH;

        MidthickSurfs{1} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.lh.midthickness.32k_fs_LR.surf.gii']; % LH
        MidthickSurfs{2} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.rh.midthickness.32k_fs_LR.surf.gii']; % RH

        OutDir = [Path '/tans/' OUTDIR];
        tans_roi(TargetNetwork, MidthickSurfs, VertexSurfaceArea, Sulc, SulcThresh, SearchSpace, OutDir, Paths);
        fprintf('tans_roi step completed\n');
    end

    %% Make a search grid on the scalp above the target network patch centroid
    if GRID == 1
        OutDir = [Path '/tans/' OUTDIR];

        PialSurfs{1} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.lh.pial.32k_fs_LR.surf.gii'];
        PialSurfs{2} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.rh.pial.32k_fs_LR.surf.gii'];

        TargetNetworkPatch = ft_read_cifti_mod([OutDir '/ROI/TargetNetworkPatch.dtseries.nii']);
        SkinSurf = [Path '/tans/HeadModel/m2m_' Subject '/Skin.surf.gii'];

        SearchGridRadius = 20; % in mm
        GridSpacing = 2; % in mm

        [SubSampledSearchGrid, ~] = tans_searchgrid(TargetNetworkPatch, PialSurfs, SkinSurf, GridSpacing, SearchGridRadius, OutDir, Paths);
        fprintf('tans_searchgrid step completed\n');
    end

    %% Run e-field modeling
    if EFIELD == 1
        OutDir = [Path '/tans/' OUTDIR];
        load([OutDir '/SearchGrid/SubSampledSearchGrid.mat']);
        SearchGridCoords = SubSampledSearchGrid;

        SkinSurf = [Path '/tans/HeadModel/m2m_' Subject '/Skin.surf.gii'];
        MidthickSurfs{1} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.lh.midthickness.32k_fs_LR.surf.gii']; % LH
        MidthickSurfs{2} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.rh.midthickness.32k_fs_LR.surf.gii']; % RH

        WhiteSurfs{1} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.lh.white.32k_fs_LR.surf.gii'];
        WhiteSurfs{2} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.rh.white.32k_fs_LR.surf.gii'];
        PialSurfs{1} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.lh.pial.32k_fs_LR.surf.gii'];
        PialSurfs{2} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.rh.pial.32k_fs_LR.surf.gii'];

        MedialWallMasks{1} = [Path '/anat/MNINonLinear/fsaverage_LR32k/' Subject '.L.atlasroi.32k_fs_LR.shape.gii'];
        MedialWallMasks{2} = [Path '/anat/MNINonLinear/fsaverage_LR32k/' Subject '.R.atlasroi.32k_fs_LR.shape.gii'];

        HeadMesh = [Path '/tans/HeadModel/m2m_' Subject '/' Subject '.msh'];
        CoilModel = [Paths{1} 'simnibs_env/lib/python3.9/site-packages/simnibs/resources/coil_models/Drakaki_BrainStim_2022/MagVenture_Cool-B70.ccd'];
        DistanceToScalp = 2;
        AngleResolution = 30; % in degrees
        nThreads = 32;

        tans_simnibs(SearchGridCoords, HeadMesh, CoilModel, AngleResolution, DistanceToScalp, SkinSurf, MidthickSurfs, WhiteSurfs, PialSurfs, MedialWallMasks, nThreads, OutDir, Paths);
        fprintf('tans_simnibs step completed\n');
    end

    %% Optimize the coil placement
    if OPTIMIZE == 1
        PialSurfs{1} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.lh.pial.32k_fs_LR.surf.gii'];
        PialSurfs{2} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.rh.pial.32k_fs_LR.surf.gii'];
        WhiteSurfs{1} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.lh.white.32k_fs_LR.surf.gii'];
        WhiteSurfs{2} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.rh.white.32k_fs_LR.surf.gii'];
        MidthickSurfs{1} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.lh.midthickness.32k_fs_LR.surf.gii'];
        MidthickSurfs{2} = [Path '/anat/T1w/fsaverage_LR32k/' Subject '.rh.midthickness.32k_fs_LR.surf.gii'];
        VertexSurfaceArea = ft_read_cifti_mod([Path '/anat/T1w/fsaverage_LR32k/' Subject '.midthickness_va.32k_fs_LR.dscalar.nii']);
        MedialWallMasks{1} = [Path '/anat/MNINonLinear/fsaverage_LR32k/' Subject '.L.atlasroi.32k_fs_LR.shape.gii'];
        MedialWallMasks{2} = [Path '/anat/MNINonLinear/fsaverage_LR32k/' Subject '.R.atlasroi.32k_fs_LR.shape.gii'];
        SearchGrid = [Path '/tans/' OUTDIR '/SearchGrid/SubSampledSearchGrid.shape.gii'];
        SkinFile = [Path '/tans/HeadModel/m2m_' Subject '/Skin.surf.gii'];
        HeadMesh = [Path '/tans/HeadModel/m2m_' Subject '/' Subject '.msh'];
        OutDir = [Path '/tans/' OUTDIR '/'];
        PercentileThresholds = linspace(99.9, 99, 10);
        CoilModel = [Paths{1} '/simnibs_env/lib/python3.9/site-packages/simnibs/resources/coil_models/Drakaki_BrainStim_2022/MagVenture_Cool-B70.ccd'];
        DistanceToScalp = 2;
        Uncertainty = 5;
        AngleResolution = 5;

        if PARCEL == 2
            FunctionalNetworks = ft_read_cifti_mod([Path '/pfm/' Subject '_sgACCNetworks_32k.dtseries.nii']);
        elseif PARCEL == 15
            FunctionalNetworks = ft_read_cifti_mod([Path '/pfm/' Subject '_FunctionalNetworks_32k.dtseries.nii']);
        end

        TargetNetwork = FunctionalNetworks;

        if TARGET == 16
            TARGET1 = 2;
            TARGET2 = 14;
            TargetNetwork.data(~ismember(TargetNetwork.data, [TARGET1, TARGET2])) = 0;
        elseif TARGET == 18 % DNA + DNB
            TARGET1 = 15;
            TARGET2 = 3;
            TargetNetwork.data(~ismember(TargetNetwork.data, [TARGET1, TARGET2])) = 0;
        else
            TargetNetwork.data(TargetNetwork.data ~= TARGET) = 0; % note: 14 == SAL, 11 = FPN-A, DN-A = 15
        end
        TargetNetwork.data(TargetNetwork.data ~= 0) = 1; % binarize

        BrainStructure = VertexSurfaceArea.brainstructure;
        TargetNetwork.data(BrainStructure == -1) = [];

        if AVOID == 0
            AvoidanceRegion = [];
        elseif AVOID == 100
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(AvoidanceRegion.data == TARGET) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        elseif AVOID == 27
            AVOID1 = 2;
            AVOID2 = 14;
            AVOID3 = 11;
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(~ismember(AvoidanceRegion.data, [AVOID1, AVOID2, AVOID3])) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        elseif AVOID == 29
            AVOID1 = 3;
            AVOID2 = 15;
            AVOID3 = 11;
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(~ismember(AvoidanceRegion.data, [AVOID1, AVOID2, AVOID3])) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        elseif AVOID == 34
            AVOID1 = 3;
            AVOID2 = 15;
            AVOID3 = 2;
            AVOID4 = 14;
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(~ismember(AvoidanceRegion.data, [AVOID1, AVOID2, AVOID3, AVOID4])) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        elseif AVOID == 39
            AVOID1 = 3;
            AVOID2 = 15;
            AVOID3 = 11;
            AVOID4 = 10;
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(~ismember(AvoidanceRegion.data, [AVOID1, AVOID2, AVOID3, AVOID4])) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        elseif AVOID == 25
            AVOID1 = 2;
            AVOID2 = 14;
            AVOID3 = 9;
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(~ismember(AvoidanceRegion.data, [AVOID1, AVOID2, AVOID3])) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        else
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(AvoidanceRegion.data ~= AVOID) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        end

        tans_optimize_no59(Subject, TargetNetwork, AvoidanceRegion, AVOID, PercentileThresholds, SearchGrid, DistanceToScalp, SkinFile, VertexSurfaceArea, MidthickSurfs, WhiteSurfs, PialSurfs, MedialWallMasks, HeadMesh, AngleResolution, Uncertainty, CoilModel, OutDir, Paths);
        fprintf('tans_optimize step completed\n');
    end

    %% Estimate the optimal TMS dose
    if DOSE == 1
        OutDir = [Path '/tans/' OUTDIR '/'];
        AvoidDir = ['A' num2str(AVOID)];

        if PARCEL == 2
            FunctionalNetworks = ft_read_cifti_mod([Path '/pfm/' Subject '_sgACCNetworks_32k.dtseries.nii']);
        elseif PARCEL == 15
            FunctionalNetworks = ft_read_cifti_mod([Path '/pfm/' Subject '_FunctionalNetworks_32k.dtseries.nii']);
        end

        VertexSurfaceArea = ft_read_cifti_mod([Path '/anat/T1w/fsaverage_LR32k/' Subject '.midthickness_va.32k_fs_LR.dscalar.nii']);
        BrainStructure = VertexSurfaceArea.brainstructure;
        FunctionalNetworks.data(BrainStructure == -1) = [];

        NetworkLabels = readtable([maskdir '/ColorMap_15.txt'], 'ReadVariableNames', true);
        magnE = [OutDir AvoidDir '/Optimize/magnE_BestCoilCenter+BestOrientation.dtseries.nii'];
        DiDt = linspace(1, 155, 20) * 1e6; % A/us
        AbsoluteThreshold = 100; % V/m
        MinHotSpotSize = 1000; % surface area (mm^2)

        TargetNetwork = FunctionalNetworks;

        if TARGET == 16
            TARGET1 = 2;
            TARGET2 = 14;
            TargetNetwork.data(~ismember(TargetNetwork.data, [TARGET1, TARGET2])) = 0;
        elseif TARGET == 18 % DNA + DNB
            TARGET1 = 15;
            TARGET2 = 3;
            TargetNetwork.data(~ismember(TargetNetwork.data, [TARGET1, TARGET2])) = 0;
        else
            TargetNetwork.data(TargetNetwork.data ~= TARGET) = 0; % note: 14 == SAL, 11 = FPN-A, DN-A = 15
        end
        TargetNetwork.data(TargetNetwork.data ~= 0) = 1; % binarize

        if AVOID == 0
            AvoidanceRegion = [];
        elseif AVOID == 100
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(AvoidanceRegion.data == TARGET) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
        elseif AVOID == 27
            AVOID1 = 2;
            AVOID2 = 14;
            AVOID3 = 11;
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(~ismember(AvoidanceRegion.data, [AVOID1, AVOID2, AVOID3])) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
        elseif AVOID == 29
            AVOID1 = 3;
            AVOID2 = 15;
            AVOID3 = 11;
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(~ismember(AvoidanceRegion.data, [AVOID1, AVOID2, AVOID3])) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        elseif AVOID == 34
            AVOID1 = 3;
            AVOID2 = 15;
            AVOID3 = 2;
            AVOID4 = 14;
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(~ismember(AvoidanceRegion.data, [AVOID1, AVOID2, AVOID3, AVOID4])) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        elseif AVOID == 39
            AVOID1 = 3;
            AVOID2 = 15;
            AVOID3 = 11;
            AVOID4 = 10;
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(~ismember(AvoidanceRegion.data, [AVOID1, AVOID2, AVOID3, AVOID4])) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
            AvoidanceRegion.data(BrainStructure == -1) = [];
        else
            AvoidanceRegion = FunctionalNetworks;
            AvoidanceRegion.data(AvoidanceRegion.data ~= AVOID) = 0;
            AvoidanceRegion.data(AvoidanceRegion.data ~= 0) = 1; % binarize
        end

        [OnTarget, Penalty, HotSpotSize] = tans_dose(magnE, VertexSurfaceArea, DiDt, AbsoluteThreshold, MinHotSpotSize, TargetNetwork, AvoidanceRegion, FunctionalNetworks, NetworkLabels, [OutDir AvoidDir '/Optimize/'], Paths);
        fprintf('tans_dose step completed\n');
    end
end
