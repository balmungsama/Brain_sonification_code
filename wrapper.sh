###########################
######## HELP TEXT ########
###########################

if [ "$1" == "--help" ]; then
	echo "Usage: `basename $0` [some stuff]"
	exit 0
fi

clear

TOP_DIR='/mnt/c/Users/john/Dropbox/2016-2017/brain_music/sonification_pkg/example_data/participants' # master directory containing group data
ROI_TXT='/mnt/c/Users/john/Documents/textrois.txt' # add the csv file containing the ROI file names in standard space
TEMPLATE=              # file for the standardized template. If not specified, default to MNI152 2mm T1

TR_SKIP=2

###########################
######## SETTINGS #########
###########################

SKULL_STRIP=1 ### 1 = FSL (BET); 2 = AFNI (3dSkullStrip), 3 = AFNI (3dSkullStrip, -push-to-edge)

if [ -n "$TEMPLATE" ]; then
	echo ''
else
	TEMPLATE=/usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain.nii.gz
fi

###########################
####### PREPROCESS ########
###########################

cd $TOP_DIR

######## LOOP GROUP ########

echo ' '
echo "Let's make some music!"
echo ' '

for GROUP in $(ls -d ./*); do
	cd $GROUP

	echo Group: $GROUP

	######## LOOP SUBJ ########

	for SUBJECT in $(ls -d ./*); do
		cd $SUBJECT

		##### SKULL STRIPPING #####
		
		echo Subject: $SUBJECT 
		echo '    Skull-stripping'

		cd anatom
		SUBJ_ANAT=3dvol_T1.nii

		if (($SKULL_STRIP == 1)); then
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

		###### MC & FUNC NORMALIZATION ######
		
		cd ../fun

		COUNT=0
		for RUN in $(ls *.nii); do

			COUNT=$(expr $COUNT + 1)

			echo '    Analyzing run' $RUN

			echo '       + Running Motion-Correction...'
			mcflirt -in $RUN -o m_$RUN # Motion Correction
			
			##### WARP FUNC TO T1 #####
			
			echo '       + Linear-warping functional to structural...'
			flirt -ref ../anatom/$SUBJ_ANAT -in $RUN -omat func2str_$COUNT.mat -dof 6           # Functional to Structural
			echo '       + Linear-warping structural to standard template...'
			flirt -ref $TEMPLATE -in ../anatom/brain_T1.nii.gz -omat ../anatom/aff_str2std.mat -out ../anatom/std_brain_T1.nii.gz  # Strcut to Std 
			echo '       + Non-linear-warping structural to standard template...'
			fnirt --ref=$TEMPLATE --in=../anatom/$SUBJ_ANAT --aff=../anatom/aff_str2std.mat --cout=../anatom/warp_str2std.nii.gz # FNIRT strct to std
			echo '       + Applying standardized warp to functional data...'
			applywarp --ref=$TEMPLATE --in=$RUN --out=norm_$RUN.nii --warp=../anatom/warp_str2std.nii.gz --premat=func2str_$COUNT.mat 
			

			##### GET MEAN ROI TIME COURSE #####
			
			echo '    Making Music'
			mkdir -p ../ROI_tcourses
			mkdir -p ../ROI_tcourses/sound_files
			for ROI in $(ls -A ../../../../ROIs/bin_*); do

				ROI=`basename $ROI`
				ROI=${ROI%.nii.gz*}
				
				echo '       + Scoring' $ROI
				fslstats -t norm_$RUN.nii.gz -k '../../../../ROIs/'$ROI'.nii.gz' -M > ../ROI_tcourses/'t_'$ROI'_'$COUNT.txt
				
				ROI_FILE=$(pwd)/../ROI_tcourses/'t_'$ROI'_'$COUNT.txt
				Rscript ../../../../../zTrans.R -p $ROI_FILE -tr $TR_SKIP --save # script to z-transform the data

			done

			octave ../../../../../mkmusic.m $COUNT
			
			echo '  '
		done

		echo Making a movie..
		cd ../ROI_tcourses
		Rscript ../../../../../graphing.R

		### make videos from image
		for i in 1 $COUNT; do

			## make a master audio file for each run
			sox -M sound_files/*_$i.wav sound_files/masterRun_$i.wav

			## make a video out of those frames
			ffmpeg -y -r 10 -f image2 -s 1920x1080 -i figures/ROI_tcourse_$i'_'%d.jpg -i sound_files/masterRun_$i.wav -vcodec libx264 -crf 25 -pix_fmt yuv420p figures/videos/run$i.mp4
		done

	done

done

echo ' * Your symphony is complete! * '
echo ' '
echo ' '
