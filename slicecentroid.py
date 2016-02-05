import subprocess
import os

# setup command line parser to control execution
from optparse import OptionParser
parser = OptionParser()
parser.add_option( "--imagefile",
                  action="store", dest="imagefile", default=None,
                  help="FILE containing image info", metavar="FILE")
(options, args) = parser.parse_args()


if (options.imagefile != None):
  getHeaderCmd = 'c3d %s -centroid ' % options.imagefile
  maskimage   = options.imagefile
  imageprefix = '/'.join(options.imagefile.split('/')[:-1])
  timeid = '.'.join(options.imagefile.split('/')[-1].split('.')[1:])
  if ( len( imageprefix)):
    truthimage = "%s/Truth.%s" % (imageprefix, timeid )
  else:
    truthimage = "./Truth.%s" % ( timeid )
  #print  truthimage 
  if ( os.path.isfile(truthimage) ): # check training set available
   try: # necrosis first
     getHeaderCmd = 'c3d %s -thresh 3 3 1 0  -centroid ' % truthimage 
     #print getHeaderCmd
     headerProcess = subprocess.Popen(getHeaderCmd ,shell=True,stdout=subprocess.PIPE )
     while ( headerProcess.poll() == None ):
        pass
     rawcentroidinfo = headerProcess.stdout.readline().strip('\n')
     centroid = eval( rawcentroidinfo.replace('CENTROID_VOX',''))
   except NameError: # enhancing second
     getHeaderCmd = 'c3d %s -thresh 2 2 1 0  -centroid ' % truthimage 
     #print getHeaderCmd
     headerProcess = subprocess.Popen(getHeaderCmd ,shell=True,stdout=subprocess.PIPE )
     while ( headerProcess.poll() == None ):
        pass
     rawcentroidinfo = headerProcess.stdout.readline().strip('\n')
     centroid = eval( rawcentroidinfo.replace('CENTROID_VOX',''))
  else: #use mask
    getHeaderCmd = 'c3d %s -thresh 1 1 1 0  -centroid ' % maskimage 
    #print getHeaderCmd
    headerProcess = subprocess.Popen(getHeaderCmd ,shell=True,stdout=subprocess.PIPE )
    while ( headerProcess.poll() == None ):
       pass
    rawcentroidinfo = headerProcess.stdout.readline().strip('\n')
    centroid = eval( rawcentroidinfo.replace('CENTROID_VOX',''))
  #print getHeaderCmd
  #print centroid , int(centroid [2])
  print int(centroid [2])
else:
  parser.print_help()
  print options
 
