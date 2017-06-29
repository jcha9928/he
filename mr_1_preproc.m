function mr_hr_1_preproc(order)

%------------ FreeSurfer -----------------------------%
fshome = getenv('FREESURFER_HOME');
fsmatlab = sprintf('%s/matlab',fshome);
if (exist(fsmatlab) == 7)
    path(path,fsmatlab);
end
    

%% reset LD_LIBRARY_PATH
LD_LIBRARY_PATH=['/nfs/apps/gcc/4.9.2/lib64'];
%/home/juke/MATLAB/R2016b/sys/os/glnxa64:

setenv('LD_LIBRARY_PATH', LD_LIBRARY_PATH)
!echo $LD_LIBRARY_PATH

parentdir='/ifs/scratch/pimri/posnerlab/1anal/highrisk/fs';

[num,txt,raw] = xlsread(fullfile(parentdir,'list_good_dwi.xls'));

disp(['NOW PROCESSING ORDER ' int2str(order)])
s=num(order+1,2)
setenv('s', int2str(s))
workingdir=fullfile(parentdir,int2str(s));
cd(workingdir)


% %% labelconvert
% if ~exist ('mr_parcels.mif'),
% lut=fullfile(parentdir,'mr_roi_lut.txt');
% img_parcels=fullfile(workingdir,'dmri','roi','infant-neo-aal_warped_diff.nii.gz');
% cmd=['labelconvert ' img_parcels ' ' lut ' ' lut ' mr_parcels.mif && gzip mr_parcels.mif'];
% unix(cmd)
% end



%% 1. setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd('dmri2')
dwiname=txt(order+1,3)
cmd=['find . -maxdepth 1 -name "' dwiname{1} '"'] 
[status, out]=system(cmd)

% if status==1, error('NO RAW DWI FILES WERE FOUND'), end

img_dwi=out(1:length(out)-1)


C=regexp(dwiname{1},'[.]','split')
img_bvecs=fullfile(pwd,'bvecs')
img_bvals=fullfile(pwd,'bvals')


  if ~exist('mr_fod.mif.gz')
%% 2. DWI processing2-converting nifti to mif%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cmd = (['mrconvert ' img_dwi ' -force mr_dwi.mif.gz -fslgrad ' img_bvecs ' ' img_bvals ' -datatype float32 -stride 0,0,0,1'])
unix(cmd)

%% denoising
cmd = (['dwidenoise mr_dwi.mif.gz -force mr_dwi_denoised.mif.gz']);
unix(cmd)

%% dwipreproc -eddy current
cmd = (['dwipreproc PA mr_dwi_denoised.mif.gz mr_dwi_denoised_preproc.mif.gz -rpe_none -force'])
unix(cmd)

%% mask and bias field correction
% img_dwi_biasCorr=fullfile(workingdir,'dwi_denoised_biasCorr.nii.gz');
unix(['dwi2mask mr_dwi_denoised_preproc.mif.gz - | maskfilter - erode -npass 7 -force mr_eroded_mask.mif.gz'])

cmd = (['dwibiascorrect mr_dwi_denoised_preproc.mif.gz -force mr_dwi_denoised_preproc_biasCorr.mif.gz -ants -mask mr_eroded_mask.mif.gz -fslgrad ' img_bvecs ' ' img_bvals ' -nthreads 4']);
unix(cmd) 



%% DWI processing3- bad vol exclusion %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% if stripe noise is found in a volume, make sure you delete %%%%
%range=txt(order+1,6)

%cmd=['mrconvert -coord 3 ' range{1} ' mr_dwi_denoised_preproc_biasCorr.mif -force mr_dwi_denoised_preproc_biasCorr_reduced.mif']
%unix(cmd)


%%%% generating b0 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
unix('dwiextract mr_dwi_denoised_preproc_biasCorr.mif.gz - -bzero | mrmath - mean -force mr_meanb0.mif.gz -axis 3')

%% upsampling %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filelist={'mr_dwi_denoised_preproc_biasCorr','mr_eroded_mask','mr_meanb0'};
for i=1:length(filelist)
    im=[filelist{i} '.mif.gz'];
    newim=[filelist{i} '_upsample.mif.gz'];
    cmd=['mrresize ' im ' -scale 2.0 -force ' newim];
    unix(cmd)
end

%% dwi2response-subject level %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% dwi2response tournier <Input DWI> <Output response text file>
% shview <Output response text file>

%%%% eroded mask
s
cmd=['dwi2mask mr_dwi_denoised.mif.gz - | maskfilter - erode -npass 7 mr_eroded_mask.mif.gz -force']
unix(cmd)


%%%% response
cmd=['dwi2response dhollander -mask mr_eroded_mask.mif.gz -voxels mr_voxels_eroded.mif.gz mr_dwi_denoised_preproc_biasCorr.mif.gz response_wm.txt response_gm.txt response_csf.txt -force'];
unix(cmd)

%% global intensity normalization  THIS MIGHT BE SKIPPED


%% 5TTGEN


%% FOD%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make sure to use "DILATED MASK" for FOD generation
unix(['dwi2mask mr_dwi_denoised_preproc_biasCorr.mif.gz - | maskfilter - dilate -npass 5 -force mr_dilate_mask.mif.gz'])
% unix(['mrresize mr_dilate_mask.mif -scale 2.0 mr_dilate_mask_upsample.mif'])

cmd1=['dwi2fod msmt_csd mr_dwi_denoised_preproc_biasCorr.mif.gz response_wm.txt WM_FODs.mif.gz response_gm.txt gm.mif.gz response_csf.txt csf.mif.gz -mask mr_dilate_mask.mif.gz -force'];
unix(cmd1)

cmd2=['mrconvert WM_FODs.mif.gz - -coord 3 0 | mrcat csf.mif.gz gm.mif.gz - tissueRGB.mif.gz -axis 3'];
unix(cmd2)
disp('I THINK EVERYTHING IS DONE BY NOW')
end

% %% streamline tractography
% cmd=['tckgen mr_fod_upsample.mif mr_fod_upsample_tckgen_100M.tck -seed_image mr_parcels.mif -mask mr_eroded_mask_upsample.mif -number 100M -maxlength 250 -nthreads 4'];
% unix(cmd)
% zip('mr_fod_upsample_tckgen.zip', 'mr_fod_upsample_tckgen.tck')
%% sift

% example: tcksift 100M.tck WM_FODs.mif 10M_SIFT.tck -act 5TT.mif -term_number 10M

end
