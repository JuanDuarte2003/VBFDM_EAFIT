import awkward as ak
import pandas as pd
import numpy as np
import vector
from coffea.nanoevents import NanoEventsFactory
from coffea.nanoevents import NanoAODSchema, DelphesSchema
import mplhep as hep
import matplotlib.pyplot as plt
import seaborn as sns
import DM_HEP_AN as dm
from math import pi
hep.style.use("CMS")
#%matplotlib inline
plt.ioff()

def PlotCinematicVariable(data, variable, suptitle, njets=4, save=True, plot=False, folder='Plots/', dpi=500):
    fig, ax = plt.subplots(2,2)

    axs = {
        0: ax[0,0],
        1: ax[0,1],
        2: ax[1,0],
        3: ax[1,1],
    }

    for i in range(njets):
        rango = np.linspace(data[f'jet_{variable}{i}'].min(), data[f'jet_{variable}{i}'].max())
        axs[i].hist(data[f'jet_{variable}{i}'], bins = rango, density = True)
        axs[i].set_title(f'Jet {i}',fontsize=15)
        axs[i].grid()
        axs[i].tick_params(axis='x',labelsize=12)
        axs[i].tick_params(axis='y',labelsize=12)

    plt.suptitle(suptitle, fontsize=30)

    if plot: plt.show()
    if save: plt.savefig(f'{folder}{variable}.png',dpi=dpi)
    plt.close(fig)

def PlotEtaPhiPlane(data, n_jets=4, save=True, plot=False, folder='Plots/', dpi=500):
    fig, ax = plt.subplots(2,2)

    axs = {
        0: ax[0,0],
        1: ax[0,1],
        2: ax[1,0],
        3: ax[1,1],
    }

    for i in range(n_jets):
        rango1 = np.linspace(data[f'jet_eta{i}'].min(), data[f'jet_eta{i}'].max())
        rango2 = np.linspace(data[f'jet_phi{i}'].min(), data[f'jet_phi{i}'].max())
        axs[i].hist2d(data[f'jet_eta{i}'],data[f'jet_phi{i}'], bins = [rango1,rango2], density = True)
        axs[i].set_title(f'Jet {i}',fontsize=15)
        axs[i].grid()
        axs[i].set_xlabel(r'$\eta$',fontsize=15)
        axs[i].set_ylabel(r'$\phi$',fontsize=15)
        axs[i].tick_params(axis='x',labelsize=12)
        axs[i].tick_params(axis='y',labelsize=12)
    
    if plot: plt.show()
    if save: plt.savefig(f'{folder}etaphiplane.png',dpi=dpi)
    plt.close(fig)
    

def PlotMissingETVariable(data, save=True, plot=False, folder='Plots/', dpi=500):
    fig, ax = plt.subplots(2)

    rango = np.linspace(data['missinget_met'].min(), data['missinget_met'].max())
    ax[0].hist(data['missinget_met'], bins = rango, density=True)
    ax[0].set_title(r'$\left|E_{T}^{miss}\right|$', fontsize=15)
    ax[0].grid()
    ax[0].tick_params(axis='x',labelsize=12)
    ax[0].tick_params(axis='y',labelsize=12)

    rango = np.linspace(data['missinget_phi'].min(), data['missinget_phi'].max())
    ax[1].hist(data['missinget_phi'], bins = rango, density=True)
    ax[1].set_title(r'$\phi_{E_{T}^{miss}}$', fontsize=15)
    ax[1].grid()
    ax[1].tick_params(axis='x',labelsize=12)
    ax[1].tick_params(axis='y',labelsize=12)

    if plot: plt.show()
    if save: plt.savefig(f'{folder}missinget.png',dpi=dpi)
    plt.close(fig)

def makePlots(data, folder):
    # pt
    PlotCinematicVariable(data, 'pt', r'$p_{T}$', folder=folder)
    # eta
    PlotCinematicVariable(data, 'eta', r'$\eta$', folder=folder)
    # phi
    PlotCinematicVariable(data, 'phi', r'$\phi$', folder=folder)
    # mass
    PlotCinematicVariable(data, 'mass', r'$m$', folder=folder)
    # Eta Phi Plane
    PlotEtaPhiPlane(data, folder=folder)
    # missinget
    PlotMissingETVariable(data, folder=folder)

def invariant_mass(row):
    m = np.sqrt(2 * row['jet_pt0'] * row['jet_pt1'] * \
                (np.cosh(row['jet_eta0'] - row['jet_eta1']) - \
                np.cosh(row['jet_phi0'] - row['jet_phi1'])))
    return m

def azimuthal_difference(row):
    deltaPhi = abs(row['jet_phi0'] - row['jet_phi1'])
    return deltaPhi

def pseudorapidity_separation(row):
    deltaEta = abs(row['jet_eta0'] - row['jet_eta1'])
    return deltaEta

def total_henergy(row, n_jets=4):
    H = sum([row['jet_pt{i}'] for i in range(n_jets)])
    return H

def plotObservable(datas, names, variable, save=True, plot=False, folder='Plots/', dpi=500):
    numDatas = len(datas)

    variableDict = {
        'Azim_diff' : [azimuthal_difference, r'$\left|\Delta\phi\right|$'],
        'Inv_mass' : [invariant_mass, r'$m_{jj}$'],
        'Pseudorapidity' : [pseudorapidity_separation, r'$\left|\Delta\eta\right|$']
    }



    fig = plt.figure()
    ax = fig.add_subplot(111)


    for i in range(numDatas):
        if names[i] == 'Z+Jets' or names[i] == 'W+Jets' :
            datas[i][variable] = datas[i].apply(variableDict[variable][0], axis=1)
            rango = np.linspace(datas[i][variable].min(), datas[i][variable].max())
            #color = next(ax._get_lines.prop_cycler)["color"]
            #ax.hist(datas[i][variable], bins=rango, density=True, color=color, edgecolor=color, fc="None", lw=1, label=names[i])
            ax.hist(datas[i][variable], bins=rango, density=True, label=names[i])
        else:
            datas[i][variable] = datas[i].apply(variableDict[variable][0], axis=1)
            rango = np.linspace(datas[i][variable].min(), datas[i][variable].max())
            color = next(ax._get_lines.prop_cycler)["color"]
            ax.hist(datas[i][variable], bins=rango, density=True, color=color, edgecolor=color, fc="None", lw=1, label=names[i])
    
    ax.legend(fontsize=20)
    ax.set_title(variableDict[variable][1], fontsize=25)
    ax.grid()
    ax.tick_params(axis='x',labelsize=20)
    ax.tick_params(axis='y',labelsize=20)

    if save: plt.savefig(f'{folder}{variable}.png',dpi=dpi)
    if plot: plt.show()
    plt.close(fig)