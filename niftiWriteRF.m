% niftiWriteRF.m
%
% writes params of an RF model, COMPUTED INPLANE!!!, to a nii file where
% each volume contains a different parameter; the first (0th) being the
% variance explained for thresholding. Readable by programs such as afni,
% fsl (not tested), BV (not tested), etc.
%
% RFmodel is a model structure saved by rmMain.m
% new_fn is the filename of the nii (extension .nii or .nii.gz)
% basenii is a nifti structure in the 'correct' orientation of the
% functional data used to create RF maps (e.g., load one of the averaged
% vols)
%
% NOTE: no support for sigma major/minor (assumes major), etc - really
% built for nonlinear models, but can be adjusted to deal w/ others...
% 
%
% Tommy Sprague, 4/5/2017



function niftiWriteRF(RFmodel,new_fn,basenii,which_params,xform)

if nargin < 2
    % error
end


if nargin < 3
    % either create a null nifti w/ niftiCreate, or load the first
    % bar_width_*.nii.gz file in output directory? probably former (TODO)
    basenii = [];
end

% check whether basenii is a niftiStruct?


if nargin < 4
    which_params = {'ve','pol','ecc','sigmamajor','exponent','x0','y0','b'};
end

if nargin < 5
    xform = niftiCreateXformBetweenStrings('PRS','PRS'); % identity transform matrix
end


% clear out data
newnii = basenii;
newnii.data = newnii.data*0;


% apply xform to PRS (the internal coord system of inplane models) NOTE -
% not necessary for square slices, like in afni, but in theory maybe
% important for non-square slices? I'll leave it in, doesn't harm
% anyone...
curr_ori = niftiCurrentOrientation(newnii); % what ori is the original data in? 
newnii = niftiApplyXform(newnii,niftiCreateXformBetweenStrings(curr_ori,'PRS'));  % reorient the nii so it's in the 'matched' ori as the model (PRS)

newnii.data = newnii.data(:,:,:,1:length(which_params));
newnii.dim(4) = length(which_params);

% TODO: check the model.(param) sizes match the first 3 nifti dims





% loop over which_params and insert into the relevant volume
for pp = 1:length(which_params)
    
    if strcmpi(which_params{pp},'b')
        tmp = rmGet(RFmodel,which_params{pp});
        newnii.data(:,:,:,pp) = tmp(:,:,:,1);
        clear tmp;
    else
        newnii.data(:,:,:,pp) = rmGet(RFmodel,which_params{pp});
    end
    
    % check if "b", if so, take only the first volume...
end



%% apply transform to 'final' nifti
% (maybe just need to flip the data brick? this may change qto/etc in a
% way we don't need....)

% convert from vista internal to an orientation that afni will like
newnii = niftiApplyXform(newnii,niftiCreateXformBetweenStrings('PRS','LPS'));

% fix the qto, sto to be like the base nii!!!!
savenii = basenii;
savenii.data = newnii.data;
savenii.dim  = newnii.dim;
% this should have the correct position info, but a data block that's in
% the right orientation, etc....

niftiWrite(savenii,new_fn);


return
