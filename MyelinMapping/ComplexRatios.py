#!/home/share/Software/anaconda/bin/python
#-!/usr/bin/python 
from nipy import load_image, save_image
from nipy.core.api import Image
import numpy as np
from scipy.stats import linregress as linregress
from joblib import Parallel, delayed
import sys

def ComplexRatios(dataFile, ratiosFile):
    dataImg = load_image(dataFile)
    shape = (dataImg.shape[0], dataImg.shape[1], dataImg.shape[2], dataImg.shape[3]-1)
   
    dataRatios = np.zeros(shape, dtype=np.complex64) 

    for i in range(shape[3]):
        print i 
        dataImg0 = dataImg[:, :, :, i]
        data0 = dataImg0.get_data()
        dataImg1 = dataImg[:, :, :, i+1]
        data1 = dataImg1.get_data()
        dataRatios[:, :, :, i] = data1/data0
        
    ratiosImg = Image(dataRatios, dataImg.coordmap)
    newimg = save_image(ratiosImg, ratiosFile)

def main():
    dataFile = sys.argv[1]
    ratiosFile = sys.argv[2]

    ComplexRatios(dataFile, ratiosFile)

if __name__ == "__main__":
    main()




