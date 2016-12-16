#!/home/share/Software/anaconda/bin/python
#-!/usr/bin/python 
from nipy import load_image, save_image
from nipy.core.api import Image
import numpy as np
import sys
from joblib import Parallel, delayed
from scipy.optimize import curve_fit

# TEs are given in milliseconds, r2 output is in 1/s
N_PARAMS = 2
INIT_R2 = 0.02
PARALLEL_JOBS = 2

def saveIm(x, coordmap, fname):
    auxImg = Image(x.astype(np.float32), coordmap)
    newimg = save_image(auxImg, fname)
    
def func(data, a, r):
    x = data[0]
    offset = data[1]
    return a*np.exp(-x*r) + offset 

def fit_func(xdata, ydata, offset):
    try: 
        popt, pcov = curve_fit(func, (xdata, offset), ydata**2, sigma = 1./ydata, 
            p0=(ydata[0], INIT_R2))
        f = 0
    except RuntimeError:
    #signal outliers as well ?
        popt = np.zeros(N_PARAMS)
        f = 1
    except KeyboardInterrupt:
        raise
    return popt, f

def relaxometry(data_file, mask_file, TE_file, offset, PD_file, 
        r2_file, err_file):        
        
    dataImg = load_image(data_file)
    data = dataImg.get_data()
    nFrames = data.shape[3]

    maskImg = load_image(mask_file)
    mask = maskImg.get_data() > 0 
    n_voxels = np.sum(mask)    

    mask4D = np.reshape(mask, mask.shape + (1, ) )
    mask4D = np.repeat(mask4D, nFrames, 3)

    dataMatrix = np.float32(np.reshape(data[mask4D], ( n_voxels , nFrames)))
    xdata = np.loadtxt(TE_file, delimiter=' ') 

# use squared model
    dataMatrix = dataMatrix**2
    xdata = xdata*2
    
# do curve fitting
    pars = Parallel(n_jobs=PARALLEL_JOBS)(delayed(fit_func)(xdata, 
        dataMatrix[i], offset) for i in range(n_voxels))
        
    pars = map(list, zip(*pars))
    popt = np.array(pars[0])

# save images
    PD = np.zeros(mask.shape)

# undo squared model    
    r2 = np.zeros(mask.shape)    
    err_data = np.zeros(mask.shape)
    y = popt[:, 0]
    y[y<0] = 0
    PD[ mask ] = np.sqrt(y)
    r2[ mask ] = popt[:, 1]*1000
    err_data[mask] = np.array(pars[1])
    
    saveIm(PD, maskImg.coordmap, PD_file)
    saveIm(r2, maskImg.coordmap, r2_file)
    saveIm(err_data, maskImg.coordmap, err_file)

def main():

    data_file = sys.argv[1]
    mask_file = sys.argv[2]
    TE_file = sys.argv[3]
    offset = sys.argv[4]
    PD_file = sys.argv[5]
    r2_file = sys.argv[6]
    err_file = sys.argv[7]

    relaxometry(data_file, mask_file, TE_file, np.float(offset), PD_file, 
        r2_file, err_file)

if __name__ == "__main__":
    main()

