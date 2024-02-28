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
plt.ioff()


def PlotCinematicVariable(
    data, variable, suptitle, njets=4, save=True, plot=False, folder="Plots/", dpi=500
):
    fig, ax = plt.subplots(2, 2)

    axs = {
        0: ax[0, 0],
        1: ax[0, 1],
        2: ax[1, 0],
        3: ax[1, 1],
    }

    for i in range(njets):
        rango = np.linspace(
            data[f"jet_{variable}{i}"].min(), data[f"jet_{variable}{i}"].max()
        )
        axs[i].hist(data[f"jet_{variable}{i}"], bins=rango, density=True)
        axs[i].set_title(f"Jet {i}", fontsize=15)
        axs[i].grid()
        axs[i].tick_params(axis="x", labelsize=12)
        axs[i].tick_params(axis="y", labelsize=12)

    plt.suptitle(suptitle, fontsize=30)

    if plot:
        plt.show()
    if save:
        plt.savefig(f"{folder}{variable}.png", dpi=dpi)
    plt.close(fig)


def PlotEtaPhiPlane(data, n_jets=4, save=True, plot=False, folder="Plots/", dpi=500):
    fig, ax = plt.subplots(2, 2)

    axs = {
        0: ax[0, 0],
        1: ax[0, 1],
        2: ax[1, 0],
        3: ax[1, 1],
    }

    for i in range(n_jets):
        rango1 = np.linspace(data[f"jet_eta{i}"].min(), data[f"jet_eta{i}"].max())
        rango2 = np.linspace(data[f"jet_phi{i}"].min(), data[f"jet_phi{i}"].max())
        axs[i].hist2d(
            data[f"jet_eta{i}"],
            data[f"jet_phi{i}"],
            bins=[rango1, rango2],
            density=True,
        )
        axs[i].set_title(f"Jet {i}", fontsize=15)
        axs[i].grid()
        axs[i].set_xlabel(r"$\eta$", fontsize=15)
        axs[i].set_ylabel(r"$\phi$", fontsize=15)
        axs[i].tick_params(axis="x", labelsize=12)
        axs[i].tick_params(axis="y", labelsize=12)

    if plot:
        plt.show()
    if save:
        plt.savefig(f"{folder}etaphiplane.png", dpi=dpi)
    plt.close(fig)


def PlotMissingETVariable(data, save=True, plot=False, folder="Plots/", dpi=500):
    fig, ax = plt.subplots(2)

    rango = np.linspace(data["missinget_met"].min(), data["missinget_met"].max())
    ax[0].hist(data["missinget_met"], bins=rango, density=True)
    ax[0].set_title(r"$\left|E_{T}^{miss}\right|$", fontsize=15)
    ax[0].grid()
    ax[0].tick_params(axis="x", labelsize=12)
    ax[0].tick_params(axis="y", labelsize=12)

    rango = np.linspace(data["missinget_phi"].min(), data["missinget_phi"].max())
    ax[1].hist(data["missinget_phi"], bins=rango, density=True)
    ax[1].set_title(r"$\phi_{E_{T}^{miss}}$", fontsize=15)
    ax[1].grid()
    ax[1].tick_params(axis="x", labelsize=12)
    ax[1].tick_params(axis="y", labelsize=12)

    if plot:
        plt.show()
    if save:
        plt.savefig(f"{folder}missinget.png", dpi=dpi)
    plt.close(fig)


def makePlots(data, folder, save=True, plot=False):
    # pt
    PlotCinematicVariable(data, "pt", r"$p_{T}$", folder=folder, save=save, plot=plot)
    # eta
    PlotCinematicVariable(data, "eta", r"$\eta$", folder=folder, save=save, plot=plot)
    # phi
    PlotCinematicVariable(data, "phi", r"$\phi$", folder=folder, save=save, plot=plot)
    # mass
    PlotCinematicVariable(data, "mass", r"$m$", folder=folder, save=save, plot=plot)
    # Eta Phi Plane
    PlotEtaPhiPlane(data, folder=folder, save=save, plot=plot)
    # missinget
    PlotMissingETVariable(data, folder=folder, save=save, plot=plot)


def invariant_mass(row, jet0=0, jet1=1):
    m = np.sqrt(
        2
        * row[f"jet_pt{jet0}"]
        * row[f"jet_pt{jet1}"]
        * abs(np.cosh(row["Delta_rapidity"]) - np.cosh(row["Delta_phi"]))
    )
    return m


def azimuthal_difference(row, jet0=0, jet1=1):
    deltaPhi = abs(row[f"jet_phi{jet0}"] - row[f"jet_phi{jet1}"])
    if deltaPhi > np.pi:
        deltaPhi = abs(deltaPhi - 2 * np.pi)
    return deltaPhi


def pseudorapidity_separation(row, jet0=0, jet1=1):
    deltaEta = abs(row[f"jet_eta{jet0}"] - row[f"jet_eta{jet1}"])
    return deltaEta


def total_henergy(row, n_jets=4):
    H = sum([row[f"jet_pt{_i}"] for _i in range(n_jets)])
    return H


def pseudorapidity_product(row, jet0=0, jet1=1):
    etaProd = row[f"jet_eta{jet0}"] * row[f"jet_eta{jet1}"]
    return etaProd


def construct_variables(data):
    funcVariables = [
        azimuthal_difference,
        pseudorapidity_separation,
        invariant_mass,
        pseudorapidity_product,
        total_henergy,
    ]
    variables = [
        "Delta_phi",
        "Delta_rapidity",
        "Inv_mass",
        "Rapidity_prod",
        "Hadronic_energy",
    ]

    for i in range(len(variables)):
        data[variables[i]] = data.apply(funcVariables[i], axis=1)

    return data


def construct_variables_all(data):
    # Only invariant mass and pseudorapidity product between all 4 jets
    funcVariables = [
        invariant_mass,
        pseudorapidity_product,
    ]
    variables = [
        "Inv_mass",
        "Rapidity_prod",
    ]

    data["Hadronic_energy"] = data.apply(total_henergy, axis=1)

    for i in range(len(variables)):
        for j in range(4):
            for k in range(4):
                if j <= k:
                    continue
                data[f"{variables[i]}_{k}{j}"] = data.apply(
                    funcVariables[i], axis=1, args=(k, j)
                )

    return data


def plotObservable(
    datas,
    names,
    variable,
    save=True,
    plot=False,
    folder="Plots/",
    dpi=500,
    selection=False,
    query="",
):
    numDatas = len(datas)

    if selection:
        for i in range(numDatas):
            # if names[i] == 'Z+Jets' or names[i] == 'W+Jets':
            #    continue
            # else:
            datas[i].query(query, inplace=True)

    variableDict = {
        "Delta_phi": [azimuthal_difference, r"$\left|\Delta\phi\right|$", (0, np.pi)],
        "Inv_mass": [invariant_mass, r"$m_{jj}$ [GeV]", (0, 3000)],
        "Delta_rapidity": [
            pseudorapidity_separation,
            r"$\left|\Delta\eta\right|$",
            (0, 10),
        ],
    }

    fig = plt.figure()
    ax = fig.add_subplot(111)

    majorValue = 0

    prop_cycle = plt.rcParams["axes.prop_cycle"]
    colors = prop_cycle.by_key()["color"]
    colorsIter = iter(colors)

    for i in range(numDatas):
        if names[i] == "Z+Jets" or names[i] == "W+Jets":
            if not variable in datas[i].columns:
                datas[i][variable] = datas[i].apply(variableDict[variable][0], axis=1)
            rango = np.linspace(datas[i][variable].min(), datas[i][variable].max())
            # color = next(ax._get_lines.prop_cycler)["color"]
            # ax.hist(datas[i][variable], bins=rango, density=True, color=color, edgecolor=color, fc="None", lw=1, label=names[i])
            yvalues, bins, hist = ax.hist(
                datas[i][variable], bins=rango, density=True, label=names[i]
            )

        else:
            if not variable in datas[i].columns:
                datas[i][variable] = datas[i].apply(variableDict[variable][0], axis=1)
            rango = np.linspace(datas[i][variable].min(), datas[i][variable].max())
            color = next(colorsIter)
            yvalues, bins, hist = ax.hist(
                datas[i][variable],
                bins=rango,
                density=True,
                color=color,
                edgecolor=color,
                fc="None",
                lw=3,
                label=names[i],
            )

        # Normalization to total number of events
        for item in hist:
            item.set_height(item.get_height() / sum(yvalues))

        majorValue = (
            yvalues.max() / sum(yvalues)
            if yvalues.max() / sum(yvalues) > majorValue
            else majorValue
        )

    ax.legend(fontsize=20)
    ax.set_xlabel(variableDict[variable][1], fontsize=25)
    ax.grid()
    ax.tick_params(axis="x", labelsize=20)
    ax.tick_params(axis="y", labelsize=20)
    ax.set_xlim(variableDict[variable][2])
    ax.set_ylim(0, majorValue)
    ax.set_ylabel("a.u.")

    hep.cms.lumitext(text="(13 TeV)")

    if selection:
        f"{folder}{variable}_withQuery.png"
    else:
        filePath = f"{folder}{variable}.png"
    if save:
        plt.savefig(filePath, dpi=dpi)
    if plot:
        plt.show()
    plt.close(fig)


# Significance Analysis


def find_significance(
    cases,
    SG,
    BG,
    cut_var,
    mass_points=2,
    use_weights=False,
    SG_weights={},
    BG_weights=[],
    size=100,
    set_lims=False,
    lims=(0, 1),
    cond=">",
):
    var_values = {}
    Z = {}  # outputs
    nBG = len(BG)  # number of backgrounds

    if not use_weights:
        BG_weights = np.ones(nBG)

    for i in cases:
        var_values[i] = []
        Z[i] = []

        if not use_weights:
            SG_weights[i] = []

        for j in range(mass_points):
            if not use_weights:
                SG_weights[i].append(1.0)

            # Limits
            infLim = SG[i][j][cut_var].min()
            supLim = SG[i][j][cut_var].max()
            if set_lims:
                infLim = lims[0] if infLim < lims[0] else infLim
                supLim = lims[1] if supLim > lims[1] else supLim

            var_values[i].append(np.linspace(infLim, supLim, size))
            Z[i].append(np.zeros(len(var_values[i][j])))

            for k in range(len(var_values[i][j])):
                if cond == ">":
                    # Signal
                    S = (
                        SG[i][j][SG[i][j][cut_var] > var_values[i][j][k]].shape[0]
                        * SG_weights[i][j]
                    )
                    # Background
                    B = sum(
                        [
                            BG[ii][BG[ii][cut_var] > var_values[i][j][k]].shape[0]
                            * BG_weights[ii]
                            for ii in range(len(BG))
                        ]
                    )
                elif cond == "<":
                    # Signal
                    S = (
                        SG[i][j][SG[i][j][cut_var] < var_values[i][j][k]].shape[0]
                        * SG_weights[i][j]
                    )
                    # Background
                    B = sum(
                        [
                            BG[ii][BG[ii][cut_var] < var_values[i][j][k]].shape[0]
                            * BG_weights[ii]
                            for ii in range(len(BG))
                        ]
                    )
                else:
                    return KeyError

                Z[i][j][k] = S / np.sqrt(S + B)

    return Z, var_values


def get_cuts(cases, Z, var_values, cut_var, var_unit, massLabels, printResults=False):
    massPoints = len(massLabels)
    cuts = {}
    for i in cases:
        if printResults:
            print("case :", i)
        cuts[i] = []
        for j in range(massPoints):
            maxZ = max(Z[i][j])
            max_index = Z[i][j].argmax()
            cut = var_values[i][j][max_index]
            cuts[i].append(cut)
            if printResults:
                print(f"\tmass point: {massLabels[j]}")
                print(f"\t\tmax significance: {maxZ}")
                print(f"\t\tcut: {cut_var} > {round(cut, 3)}{var_unit}")
    return cuts
