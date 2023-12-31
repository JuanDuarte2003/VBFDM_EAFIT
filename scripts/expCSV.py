import awkward as ak
import pandas as pd
import numpy as np
import vector
from coffea.nanoevents import NanoEventsFactory
from coffea.nanoevents import NanoAODSchema, DelphesSchema
import DM_HEP_AN as dm
from math import pi

def export_to_csv(filepath, outpath, n_jets=4, n_lep=0):
    # n_jets = number of jets to take into account
    # n_lep = number of leptons to take into account
    tree = dm.Converter(filepath)
    tree.generate(jet_elements=n_jets, e_mu_elements=n_lep)
    data = tree.df
    data.to_csv(outpath, index=False)
