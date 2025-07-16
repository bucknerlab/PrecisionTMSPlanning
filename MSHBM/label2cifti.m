function label2cifti(OUTFOLDER,codedir)

% Written by Jingnan Du
% Contact Jingnan Du at jingnandu@fas.harvard.edu if you have any questions

colorfile= [codedir '/MSHBM/ColorMap_15.txt '];
matdir= dir([OUTFOLDER '*mat']);
FILENAME='MSHBM';

for i = 1:length(matdir)
    label_mat = fullfile(matdir(i).folder,matdir(i).name);
    load(label_mat)

    % Find the position of "sub"
    sub_idx = strfind(label_mat, 'sub');

    % Find the first underscore after "sub"
    underscore_idx = find(label_mat(sub_idx:end) == '_', 1) + sub_idx - 1;

    SUB = label_mat(underscore_idx+1:end-4);
    %SUB = label_mat(end-8:end-4);
    OUTDIR = fullfile([OUTFOLDER,SUB]);
    mkdir(OUTDIR);
    
    g = ciftiopen([codedir '/MSHBM/fsaverage6_cifti_template.dscalar.nii'],[codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command'],1)
    g.cdata=[lh_labels; rh_labels];
    dlabel = [' ' OUTDIR '/' SUB '_' FILENAME '.dlabel.nii'];
    
    ciftisavereset(g,fullfile([OUTDIR '/' SUB '_' FILENAME '.dscalar.nii']),[codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command'])
    system('module load wb_contain/1.0.0-linux_x64-ncf')
    system([codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command -cifti-label-import ' fullfile([OUTDIR '/' SUB '_' FILENAME '.dscalar.nii ']) colorfile fullfile([' ' OUTDIR '/' SUB '_' FILENAME '.dlabel.nii'])])
    system([codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command -cifti-separate ' dlabel ' COLUMN -label CORTEX_LEFT ' dlabel(1:end-11) '_lh.label.gii -label CORTEX_RIGHT ' dlabel(1:end-11) '_rh.label.gii'])
    system([codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command -label-to-border ' codedir '/ncf_tools/fsaverage6/surf/lh.pial_infl2.surf.gii ' dlabel(1:end-11) '_lh.label.gii ' dlabel(1:end-11) '_lh.border -placement 0.5'])
    system([codedir '/ncf_tools/connectome-workbench/1.3.2-fasrc01/bin_rh_linux64/wb_command -label-to-border ' codedir '/ncf_tools/fsaverage6/surf/rh.pial_infl2.surf.gii ' dlabel(1:end-11) '_rh.label.gii ' dlabel(1:end-11) '_rh.border -placement 0.5'])
    
end

end