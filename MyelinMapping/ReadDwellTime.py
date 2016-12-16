#!/home/share/Software/anaconda/bin/python
#-!/usr/bin/python 
from __future__ import division
import dicom
import sys

def ReadDwellTime(image_file, scanner):
    image = dicom.read_file(image_file)
    
    if scanner == 'SIEMENS':
        DwellTime = float(image[0x19, 0x1018].value)*1e-9
    elif scanner == 'GE':
        DwellTime = 1/float(image[0x18, 0x95].value*image[0x28, 0x10].value)
    else: 
        print "Scanner undefined"
        
    print("%11.9f"%DwellTime)
    
def main():
    image_file = sys.argv[1]
    scanner = sys.argv[2]

    ReadDwellTime(image_file, scanner)

if __name__ == "__main__":
    main()

