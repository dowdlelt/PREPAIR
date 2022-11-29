function prepair = PREPAIR_main(prepair)
%% PREPAIR options
% These are fields of the struct, for example - outdir refers to
% prepair.outdir
%
% <outdir> A name for the folder that the output and intermediate files
% will be saved to. 
% <indir> The full path to the data files. 
% <savestats> A boolean flag (1/0) for whether you would like to save out
% the t statistic maps for the cardiac and respiratory regressor. 


%% 1) Create outdir folder (indir/PREPAIR)

% If the user has provided an out directory, use that. 
if ~isfield(prepair, 'outdir')
    prepair.outdir = fullfile(prepair.indir, 'PREPAIR'); 
else
    prepair.outdir = fullfile(prepair.indir, prepair.outdir); 
end

if ~isfolder(prepair.outdir)
    command=['mkdir ' prepair.outdir];
    system(command);
end


%% 2) Load EPI magnitude and unwrapped phase data
prepair = PREPAIR_READ_fMRI(prepair);

if prepair.polort~=0
    prepair=PREPAIR_polort(prepair);
end

%% 3) Derive magnitude and phase waveforms
prepair=PREPAIR_physio_waveforms(prepair);


%% 4) Choose between magnitude or phase regressors
prepair = PREPAIR_mag_or_phase(prepair);


%% 5) Magnitude image correction
% get fixed magnitude, and also t stats for cardiac and respriation.
[ima_corr, t_c, t_r] = PREPAIR_correction(prepair);

if prepair.waitbarBoolean
    wait = waitbar(0,'Saving files ...'); % initialize waitbar
end
if prepair.waitbarBoolean
    waitbar(1/1,wait) % increment the waitbar
end

% Allow the user to provide a filename out.
if ~isfield(prepair, 'outname')
    prepair.outname = 'mag_corr.nii';
end



% Write out the corrected nii file using the original hdr.
tempnii.img = ima_corr;
tempnii.hdr = prepair.hdr;
save_nii(tempnii, fullfile(prepair.outdir,prepair.outname) )

if prepair.savestats == 1
    % the user wants the stat files saved out, do it. 
    tempnii.img = t_c;
    tempnii.hdr = prepair.hdr;
    tempnii.hdr.dime.dim(5) = 1; % update header, one timepoint
    save_nii(tempnii, fullfile(prepair.outdir,['tmap_cardiac_', prepair.outname]) )

    tempnii.img = t_r; % no need to update hdr, using the one from just above
    save_nii(tempnii, fullfile(prepair.outdir,['tmap_respiration_', prepair.outname]) )
end

prepair.ima_corr = ima_corr;

if prepair.waitbarBoolean
    close(wait);
end
