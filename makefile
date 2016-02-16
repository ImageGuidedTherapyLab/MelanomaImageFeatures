ROOTDIR=$(WORK)/github/MelanomaImageFeatures
WORKDIR=Processed
DATADIR=DataDirectory
SCRIPTSPATH=$(ROOTDIR)/Code
DIMENSION=3
NTISSUE=3
ATROPOSCMD=$(ANTSPATH)/Atropos -d $(DIMENSION) -i kmeans[$(NTISSUE)]  -c [3,0.0] -m [0.1,1x1x1] 
C3DEXE=c3d
ANTSREGISTRATIONCMD=$(ANTSPATH)/antsRegistration
ANTSAPPLYTRANSFORMSCMD=$(ANTSPATH)/antsApplyTransforms
ANTSIMAGEMATHCMD=$(ANTSPATH)/ImageMath $(DIMENSION)
NIFTITOOLS=nifti_tools

#https://www.gnu.org/software/make/manual/html_node/Special-Targets.html
.SECONDARY: $(addsuffix /mask.centroid.txt,$(addprefix $(WORKDIR)/,$(SUBDIRS))) $(addsuffix /mask.nii.gz,$(addprefix $(WORKDIR)/,$(SUBDIRS)))

IMAGELIST= anatomy

#SUBDIRS := $(filter_out *svn* other-unwanted_dirs $(shell find DataDirectory -type d -print))
#SUBDIRS := $(shell find DataDirectory/ -mindepth 1 -links 2 -type d -print)
#SUBDIRS := RandomDataTry
SUBDIRS := $(shell find DataDirectory/ -mindepth 2 -links 2 -type d -print | cut -d'/' -f 2-)

#build list of image snapshots

#build list of image statistics to be computed 
stats: $(foreach idimage,$(IMAGELIST),$(addsuffix /$(idimage).GMM.nii.gz,$(addprefix $(WORKDIR)/,$(SUBDIRS))))
png: $(addsuffix /label.png,$(addprefix $(WORKDIR)/,$(SUBDIRS)))

$(WORKDIR)/%/mask.nii.gz: $(DATADIR)/%/label.nii
	mkdir -p $(WORKDIR)/$*
	echo vglrun itksnap -g $(DATADIR)/$*/anatomy.nii -s $(DATADIR)/$*/label.nii 
	-c3d $(DATADIR)/$*/anatomy.nii $(DATADIR)/$*/label.nii  -lstat > $(WORKDIR)/$*/labelstat.txt 2>&1
	$(C3DEXE) $<  -binarize  -o $@

$(WORKDIR)/%/mask.centroid.txt: $(WORKDIR)/%/mask.nii.gz
	python slicecentroid.py --imagefile=$< > $@

$(WORKDIR)/%/label.png: $(WORKDIR)/%/mask.centroid.txt
	-c3d $(DATADIR)/$*/label.nii -slice z `cat $<` -dup -oli dfltlabels.txt 1.0   -type uchar -omc $(WORKDIR)/$*/label.png

	#for  iddata in $(SUBDIRS) ;do find  $(WORKDIR)/$$iddata/ -type d -printf "\\\\viewdata{%p}\n" | sort -V ; echo "\clearpage"; done > DoNotCOMMIT.tex
tex: png
	for  iddata in $(SUBDIRS) ;do find  $(WORKDIR)/$$iddata/ -type d -printf "\\\\viewdata{%p}\n" | sort -V > DoNotCOMMIT.tex; pdflatex -output-directory $(WORKDIR)/$$iddata/ ViewProcessed.tex ; done 
	pdftk `ls Processed/*/*/*.pdf | sort -V` cat output  out.pdf

#run mixture model to segment the image
#https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
#https://www.gnu.org/software/make/manual/html_node/Secondary-Expansion.html#Secondary-Expansion
.SECONDEXPANSION:
$(WORKDIR)/%.GMM.nii.gz: $(DATADIR)/%.nii $(WORKDIR)/$$(*D)/mask.nii.gz
	./createFeatureImages.sh  -d 3 -x $(word 2,$^) -l 1 -n anat -a $<  -r 1 -r 3 -r 5 -s 2 -b 3  -o $(WORKDIR)/$(*D)/texture
	echo $@
