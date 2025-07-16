Edits made to the TANS (Lynch et al., 2022) code for Sun, Billot, et al., 2025 Precision TMS pipeline

## tans_dose.m

# line 24

Edited code:
NetworkLabels = sortrows(NetworkLabels,'No');
NetworkLabels = NetworkLabels(:,2:5);
NetworkLabels.Properties.VariableNames(1)={'Network'}; 

# line 64

Edited code:
O.data(:,1:length(DiDt)) = repmat(FunctionalNetworks.data(:,1),[1 length(DiDt)]);

# line 70

Edited code:
HotSpot = magnE.data(:,t) >= AbsoluteThreshold; 

# lines 74-75

Edited code:
OnTarget(t,1) = sum(VertexSurfaceArea.data(HotSpot&TargetNetwork.data(:,1)==1)) / sum(VertexSurfaceArea.data(HotSpot));
Penalty(t,1) = sum(VertexSurfaceArea.data(HotSpot&AvoidanceRegion.data(:,1)==1)) / sum(VertexSurfaceArea.data(HotSpot));

# line 84

Edited code:
O2 = O;
O2.brainstructure(VertexSurfaceArea.brainstructure==-1)=-1;
ft_write_cifti_mod([OutDir 'StimulatedNetworks'],O2);

# lines 128-129
 
Edited code:
xticks(Idx([2,4,6,8,10,12,14,16,18,20]));
allxlabs = round(DiDt(Idx)/1e6);
xticklabels(allxlabs([2 4 6 8 10 12 14 16 18 20]));

## tans_headmodels.m

# line 46

Edited code:
system(['charm --forceqform ' Subject ' T1w.nii.gz T2w.nii.gz --skipregisterT2 > /dev/null 2>&1']);

## tans_optimize.m

# lines 84-86 

Edited code:
HotSpot = MagnE.data(:,ii) > prctile(MagnE.data(:,ii),PercentileThresholds(iii)); % this is the hotspot
OnTarget(idx,ii,iii) = (sum(VertexSurfaceArea.data(HotSpot&TargetNetwork.data(:,1)==1)) / sum(VertexSurfaceArea.data(HotSpot))); 
Penalty(idx,ii,iii) = (sum(VertexSurfaceArea.data(HotSpot&AvoidanceRegion.data(:,1)==1)) / sum(VertexSurfaceArea.data(HotSpot)));

# lines 247-249

Edited code:
HotSpot = MagnE.data(:,i) > prctile(MagnE.data(:,i),PercentileThresholds(ii));
OnTarget(1,i,ii) = (sum(VertexSurfaceArea.data(HotSpot&TargetNetwork.data(:,1)==1)) / sum(VertexSurfaceArea.data(HotSpot))); 
Penalty(1,i,ii) = (sum(VertexSurfaceArea.data(HotSpot&AvoidanceRegion.data(:,1)==1)) / sum(VertexSurfaceArea.data(HotSpot))); 


## tans_roi.m

# line 57 commented out

# line 67

Inserted code:
system(['wb_command -cifti-create-dense-from-template ' OutDir '/ROI/TargetNetwork.dtseries.nii ' OutDir '/ROI/SearchSpace_converted.dtseries.nii -series 1 1 -cifti ' OutDir '/ROI/SearchSpace.dtseries.nii']);
SearchSpace_converted=ft_read_cifti_mod([OutDir '/ROI/SearchSpace_converted.dtseries.nii']);
TargetNetwork.data(SearchSpace_converted.data==0) = 0;
ft_write_cifti_mod([OutDir '/ROI/TargetNetwork+SearchSpace.dtseries.nii'],TargetNetwork);

TargetNetwork=ft_read_cifti_mod([OutDir '/ROI/TargetNetwork+SearchSpace.dtseries.nii']);

# between lines 76 and 77

Inserted code:
InvertedSulc = -Sulc.data;
TargetNetwork.data(InvertedSulc < SulcThresh) = 0; % remove network vertices in sulcus / fundus; % lh.sulc values are inverted

# line 82 commented out

# between lines 90 and 91

Inserted code:
Clusters2 = Clusters;
BrainStructure2 = VertexSurfaceArea.brainstructure;
Clusters2.data(BrainStructure2==-1)=[];

# line 105

Edited code:
ClusterSize(i) =  sum(VertexSurfaceArea.data(find(Clusters2.data==i)));

# line 111

Edited code:
TargetPatch = Clusters.data==TargetPatch;

# line 132

Edited code:
TargetPatch = Clusters.data==TargetPatch; 

### Other notes
This version of TANS has been edited on 4/19/2024 to allow the use of connectome_workbench in a container.
connectome workbench stopped working on 4/17/24 after RC upgraded some files that we don’t have control over. Tim O'Keefe has graciously put together a fix so we can continue using wb_command, wb_view, and wb_shortcuts:
 
First you’ll need to load the new module that Tim wrote:
module load wb_contain/1.0.0-linux_x64-ncf
 
Then you can use the functions as follows
wb_contain -v 1.5.0 wb_command -help
wb_contain -v 1.3.2 wb_command -help
 
Note that this allows you to specify the version that you want.
 
For wb_view, you can do:
wb_contain -v 1.5.0 wb_view
wb_contain -v 1.3.2 wb_view
 
 
For those that are using wb_command in matlab scripts, you can load the wb_contain module once before launching matlab, and do (for example):
system(['wb_contain -v 1.3.2 wb_command -help'])
 
Note that -help is a placeholder for whatever wb_command you want to run.
 