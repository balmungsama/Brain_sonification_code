TOP_DIR='/mnt/c/Users/john/Dropbox/2016-2017/brain_music/sonification_pkg/example_data/participants' # The master directory containing all of group data
ROI_TXT='/mnt/c/Users/john/Documents/textrois.txt' # add the csv file containing the ROI file names in standard space
TEMPLATE=              # file for the standardized template. If not specified, default to MNI152 2mm T1

###########################
######## SETTINGS #########
###########################

SKULL_STRIP=1 ### 1 = FSL (BET); 2 = AFNI (3dSkullStrip), 3 = AFNI (3dSkullStrip, -push-to-edge)
NORM_3D=1     ### 1 = FSL (FLIRT), 2 = AFNI (3dvolreg), 3 = AFNI (3dQwarp)

if [ -n "$TEMPLATE" ]; then
	echo ''
else
	TEMPLATE=/usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain.nii.gz
fi

echo TEMPLATE = $TEMPLATE

###########################
####### PREPROCESS ########
###########################

######## LOOP GROUP ########

for GROUP in $(ls -d $TOP_DIR/*); do
	cd $GROUP

	######## LOOP SUBJ ########

	for SUBJECT in $(ls -d ./*); do
		cd $SUBJECT

		##### SKULL STRIPPING #####
		
		cd anatom
		SUBJ_ANAT=*_3dvol.nii
		echo $SUBJ_ANAT

		if (($SKULL_STRIP == 1)); then
			# echo $SUBJ_ANAT
			bet $SUBJ_ANAT 'brain_T1'
		elif (($SKULL_STRIP == 2)); then
			3dSkullStrip -input $SUBJ_ANAT -prefix brain_
			3dAFNItoNIFTI -prefix brain brain_*.HEAD
			rm *+orig.*
		elif (($SKULL_STRIP == 3)); then
			3dSkullStrip -input $SUBJ_ANAT -prefix brain_edge -push_to_edge
			3dAFNItoNIFTI -prefix brain brain_*.HEAD
			rm *+orig.*
		else 
			echo ERROR: Enter a value between 1 and 3.
		fi

		###### T1 NORMALIZATION ######
		if (($NORM_3D == 1)); then
			flirt -omat struct2norm.mat -in brain_T1.nii -ref $TEMPLATE -out w_brain_T1
		elif (($NORM_3D == 2)); then
			echo This setting is not yet ready.
		elif (($NORM_3D == 3)); then
			auto_warp.py -base $TEMPLATE -input brain_T1.nii -skull_strip_input no 
		else 
			echo ERROR: Enter a value between 1 and 3.
		fi

        ###### MC & FUNC NORMALIZATION ######
        
        cd ../fun

        COUNT=1
        for RUN in $(ls *.nii); do

        	echo $RUN
        	echo $COUNT

        	mcflirt -in $RUN -o m_$RUN # Motion Correction

        	##### SKULL STRIP MC FUNC DATA #####
        	
        	if (($SKULL_STRIP == 1)); then
        		bet m_$RUN bm_$RUN -F -t #-f 0.7
        	elif (($SKULL_STRIP == 2)); then
        		echo This setting is not yet ready.
        	elif (($SKULL_STRIP == 3)); then
        		echo This setting is not yet ready.
        	fi
        	
        	##### WARP FUNC TO T1 #####
        	
        	echo one
        	flirt -ref ../anatom/ID4503_3dvol.nii -in $RUN -omat func2str_$COUNT.mat -dof 6           # Functional to Structural
        	echo two
        	flirt -ref $TEMPLATE -in ../anatom/brain_T1.nii.gz -omat ../anatom/aff_str2std.mat -out ../anatom/std_brain_T1.nii.gz  # Structural to Standardized 
        	echo three
        	fnirt --ref=$TEMPLATE --in=../anatom/ID4503_3dvol.nii --aff=../anatom/aff_str2std.mat --cout=../anatom/warp_str2std.nii.gz # FNIRT warp structural to standardized
        	echo four
        	applywarp --ref=$TEMPLATE --in=$RUN --out=norm_$RUN.nii --warp=../anatom/warp_str2std.nii.gz --premat=func2str_$COUNT.mat 

        	COUNT=$(expr $COUNT + 1)

        	# flirt -dof 6 -omat fun2anat.mat -in bm_$RUN -ref ../anatom/brain_T1.nii.gz  # Find a way to make a unique fun2anat.mat for each loop iteration
        	# flirt -ref $TEMPLATE -in betted_struct.nii -omat aff_struct2mni.mat

        	# applyxfm4D bm_$RUN $TEMPLATE rbm_$RUN fun2anat.mat -singlematrix
        	# applyxfm4D rbm_$RUN $TEMPLATE wrbm_$RUN ../anatom/struct2norm.mat -singlematrix
        	
        done

    done
done

###########################
####### MAKE MUSIC ########
###########################

# cat $ROI_TXT | while read roi
# do
# 	echo $roi
# done
# 