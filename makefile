ROOTDIR=$(WORK)/github/OpticalImageAnalysis
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
.SECONDARY:

IMAGELIST= GFP L012 Luminol kB5 NFkB 7TFC mCherry
DISTANCELIST= GFPL012 kB5L012 GFPLuminol kB5Luminol 7TFCL012 7TFCLuminol NFkBL012 NFkBLuminol mCherryL012 mCherryLuminol

#SUBDIRS := $(filter_out *svn* other-unwanted_dirs $(shell find DataDirectory -type d -print))
#SUBDIRS := $(shell find DataDirectory/ -mindepth 1 -links 2 -type d -print)
#SUBDIRS := RandomDataTry
SUBDIRS := $(shell find DataDirectory/ -mindepth 1 -links 2 -type d -print | cut -d'/' -f 2-)

#build list of image snapshots
SNAPSHOTS= $(foreach idimage,$(IMAGELIST),$(addsuffix /$(idimage).comp.png,$(addprefix $(WORKDIR)/,$(SUBDIRS)))) $(foreach idimage,$(IMAGELIST),$(addsuffix /$(idimage).distance.png,$(addprefix $(WORKDIR)/,$(SUBDIRS)))) $(foreach idimage,$(IMAGELIST),$(addsuffix /$(idimage).GMM.png,$(addprefix $(WORKDIR)/,$(SUBDIRS)))) $(foreach idimage,$(IMAGELIST),$(addsuffix /$(idimage).original.png,$(addprefix $(WORKDIR)/,$(SUBDIRS)))) $(addsuffix /Mask.png,$(addprefix $(WORKDIR)/,$(SUBDIRS)))

#build list of image statistics to be computed 
stats: $(foreach idimage,$(IMAGELIST),$(addsuffix /$(idimage).GMM.VolStat.csv,$(addprefix $(WORKDIR)/,$(SUBDIRS)))) $(foreach iddist,$(DISTANCELIST),$(addsuffix /$(iddist).DistanceStat.csv,$(addprefix $(WORKDIR)/,$(SUBDIRS))))  $(SNAPSHOTS)


#compute distance images from the segmentation
$(WORKDIR)/%.distance.nii.gz: $(WORKDIR)/%.GMM.nii.gz
	$(ANTSIMAGEMATHCMD)  $@  MaurerDistance $< $(NTISSUE)

#compute connect-components from the segmentation
$(WORKDIR)/%.comp.nii.gz: $(WORKDIR)/%.GMM.nii.gz
	$(C3DEXE) $<  -thresh 3 3 1 0  -comp   $@

#snapshots of distance images
$(WORKDIR)/%.distance.png: $(WORKDIR)/%.distance.nii.gz
	$(C3DEXE) $< -slice z 0  -color-map grey -type uchar -omc  $@

#snapshots of original images
$(WORKDIR)/%.original.png: $(DATADIR)/%.hdr
	$(C3DEXE) $< -slice z 0  -color-map grey -type uchar -omc  $@

#extract image statistics from label map
#https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html 	$(*D)
$(WORKDIR)/%.GMM.VolStat.csv: $(DATADIR)/%.hdr $(WORKDIR)/%.GMM.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+//g;s/\s\+/,/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/GFPL012.DistanceStat.csv:    $(WORKDIR)/%/GFP.distance.nii.gz $(WORKDIR)/%/L012.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/kB5L012.DistanceStat.csv:    $(WORKDIR)/%/kB5.distance.nii.gz $(WORKDIR)/%/L012.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/7TFCL012.DistanceStat.csv:    $(WORKDIR)/%/7TFC.distance.nii.gz $(WORKDIR)/%/L012.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/NFkBL012.DistanceStat.csv:    $(WORKDIR)/%/NFkB.distance.nii.gz $(WORKDIR)/%/L012.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/mCherryL012.DistanceStat.csv:    $(WORKDIR)/%/mCherry.distance.nii.gz $(WORKDIR)/%/L012.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/GFPLuminol.DistanceStat.csv: $(WORKDIR)/%/GFP.distance.nii.gz $(WORKDIR)/%/Luminol.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/kB5Luminol.DistanceStat.csv: $(WORKDIR)/%/kB5.distance.nii.gz $(WORKDIR)/%/Luminol.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/7TFCLuminol.DistanceStat.csv:    $(WORKDIR)/%/7TFC.distance.nii.gz $(WORKDIR)/%/Luminol.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/NFkBLuminol.DistanceStat.csv:    $(WORKDIR)/%/NFkB.distance.nii.gz $(WORKDIR)/%/Luminol.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@

#extract image statistics from label map
$(WORKDIR)/%/mCherryLuminol.DistanceStat.csv:    $(WORKDIR)/%/mCherry.distance.nii.gz $(WORKDIR)/%/Luminol.comp.nii.gz
	$(C3DEXE) $^ -lstat > $@.txt ; sed "s/^\s\+/$(*D),$(subst Day,,$(*F)),$(firstword $(subst ., ,$(@F))),/g;s/\s\+/,/g;s/LabelID/DataID,Time,DistanceID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $@.txt > $@


# echo sub directories to verify job list
joblist:
	@echo $(SUBDIRS)

#snapshots of label maps
$(WORKDIR)/%/Mask.png: $(DATADIR)/%/Mask.hdr 
	$(C3DEXE) $< -slice z 0  -dup -oli dfltlabels.txt 1.0 -type uchar -omc $@
$(WORKDIR)/%.GMM.png: $(WORKDIR)/%.GMM.nii.gz
	$(C3DEXE) $< -slice z 0  -dup -oli dfltlabels.txt 1.0 -type uchar -omc $@
$(WORKDIR)/%.comp.png: $(WORKDIR)/%.comp.nii.gz
	$(C3DEXE) $< -slice z 0  -dup -oli dfltlabels.txt 1.0 -type uchar -omc $@

#run mixture model to segment the image
#https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
#https://www.gnu.org/software/make/manual/html_node/Secondary-Expansion.html#Secondary-Expansion
.SECONDEXPANSION:
$(WORKDIR)/%.GMM.nii.gz: $(DATADIR)/%.hdr $(DATADIR)/$$(*D)/Mask.hdr 
	mkdir -p $(WORKDIR)/$(*D)
	$(ATROPOSCMD) -a $< -x $(word 2,$^) -o [$@,$(WORKDIR)/$*.gmmPOSTERIORS%d.nii.gz] 
