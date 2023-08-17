import awkward as ak
import pandas as pd
import numpy as np


from coffea.nanoevents import NanoEventsFactory
from coffea.nanoevents import NanoAODSchema, DelphesSchema


class Converter:
    """
    Converter is an object thing to convert a .root file produced with MadGraph5, Pythia8 and Delphes,
    into a pandas DataFrame, i.e. a squared data structure. The object converter must have a path to the .root file
    in the initialization of the object, and to obtain the Data Frame first a dictionary of branches and leafs,
    were the branches are string keys of the dictionary and the leafs are string lists values of the dictionary.

    If there is no dictionary as argument for the generate method, by default, it will generate a DataFrame with the next columns:
    ['jet_pt0', 'jet_pt1', 'jet_pt2', 'jet_pt3', 'jet_eta0', 'jet_eta1',
       'jet_eta2', 'jet_eta3', 'jet_phi0', 'jet_phi1', 'jet_phi2', 'jet_phi3',
       'jet_mass0', 'jet_mass1', 'jet_mass2', 'jet_mass3', 'jet_btag0',
       'jet_btag1', 'jet_btag2', 'jet_btag3', 'jet_tautag0', 'jet_tautag1',
       'jet_tautag2', 'jet_tautag3', 'muon_pt0', 'muon_eta0', 'muon_phi0',
       'muon_charge0', 'electron_pt0', 'electron_eta0', 'electron_phi0',
       'electron_charge0', 'missinget_met', 'missinget_phi']


    Example:
    tree_test = Converter(fname)
    tree_test.generate({"Jet": ["PT", "Eta", "Phi", "Mass", "BTag", "TauTag"],
                                   "Muon": ["PT", "Eta", "Phi", "Charge"],
                                   "Electron": ["PT", "Eta", "Phi", "Charge"],
                                   "MissingET": ["MET", "Phi"]})
    df = tree_test.df

    Any doubt please consider to write to tatehort@cern.ch or to Tomas Atehortua Garces via mattermost
    """

    def __init__(self, usr_path, tree_name="/Delphes"):
        self.path = usr_path
        self.tree = tree_name
        self.events = NanoEventsFactory.from_root(
            self.path, schemaclass=DelphesSchema, treepath=self.tree
        ).events()

    def generate(
        self,
        branches={
            "Jet": ["PT", "Eta", "Phi", "Mass", "BTag", "TauTag"],
            "Muon": ["PT", "Eta", "Phi", "Charge"],
            "Electron": ["PT", "Eta", "Phi", "Charge"],
            "MissingET": ["MET", "Phi"],
        },
        jet_elements=4,
        e_mu_elements=1,
    ):
        """
        Fills the DataFrame with the the columns needed. There is an example in the class documentation.

        - variables:
            branches: A Dictionary with the keys being the branches of the .root file and the values as a list of strings
            with the leafs inside the branch considered. Branches can be checked as <converter_name>.events.fields
        - jet_elements: Number of jets to be considered for the DataFrame
        - e_mu_elements: Number of electrons and muons to be considered for the DataFrame
        """

        self.max_jets = jet_elements
        self.max_e_mu = e_mu_elements
        self.df = pd.DataFrame(index=range(len(self.events)))

        for branch, leafes in branches.items():
            for leaf in leafes:
                self._add_branch(branch, leaf)

    def _add_branch(self, branch, leaf):
        branch_name, leaf_name = branch.lower(), leaf.lower()
        if branch == "MissingET":
            var = self.events[branch][leaf]
            var = ak.to_pandas(var)
            var.reset_index(drop=True, inplace=True)
            var.columns = [f"{branch_name}_{leaf_name}"]

        elif branch == "Electron" or branch == "Muon":
            var = self.events[branch][leaf]
            var = ak.to_pandas(
                ak.pad_none(var, target=self.max_e_mu, clip=True)
            ).unstack()
            var.columns = [
                f"{branch_name}_{leaf_name}{i}" for i in range(self.max_e_mu)
            ]
            var.reset_index(drop=True, inplace=True)

        elif branch == "Jet":
            var = self.events[branch][leaf]
            var = ak.to_pandas(
                ak.pad_none(var, target=self.max_jets, clip=True)
            ).unstack()
            var.columns = [
                f"{branch_name}_{leaf_name}{i}" for i in range(self.max_jets)
            ]
            var.reset_index(drop=True, inplace=True)

        self.df = pd.concat([self.df, var], axis=1)
        return self.df
