p2rank 2.5.1-r1

Purpose:
  Protein ligand-binding site prediction and pocket rescoring with P2Rank.
  The default upstream command is prank; fpocket is bundled for fpocket-rescore.

Usage:
  taf-p2rank -- -v
  taf-p2rank prank help
  taf-p2rank predict -f protein.pdb -threads 4 -visualizations 0 -o p2rank_out
  taf-p2rank predict proteins.ds -o p2rank_dataset_out

Common workflows:
  taf-p2rank predict -f protein.cif -c alphafold -o alphafold_p2rank_out
  taf-p2rank rescore fpocket.ds -o p2rank_rescore_out
  taf-p2rank fpocket-rescore proteins.ds -fpocket_keep_output 0 -o fpocket_rescore_out

Packaged commands:
  prank      P2Rank 2.5.1 command-line program
  fpocket    Fpocket 4.2.3 helper for prank fpocket-rescore
  java       OpenJDK 17 runtime

Upstream help and version:
  taf-p2rank -- -v
  taf-p2rank prank help
  taf-p2rank -- help
  taf-p2rank fpocket     Inspect helper availability; not a full Fpocket app

Inputs:
  protein.pdb/.cif/.bcif     Protein structure for prediction
  proteins.ds                P2Rank dataset file
  fpocket.ds                 Prediction/protein pairs for rescoring

Key outputs:
  *_predictions.csv          Predicted pocket table
  *_residues.csv             Residue-level pocket score table
  *_rescored.csv             Rescored pocket table
  visualizations/            Optional PyMOL/ChimeraX scripts and SAS points

Platform and resources:
  Built for linux/amd64. P2Rank models and configs are bundled under
  /opt/p2rank. No template database is required. A reduced BioJava chemical
  component cache is preloaded under /opt/p2rank/cache; unusual ligands may
  need a user-provided writable PDB_CACHE_DIR. Docker/Podman runs request
  --platform linux/amd64 through src/main.taf.

Boundaries:
  PyMOL and ChimeraX viewers are not included.
  fpocket is included only for P2Rank fpocket-rescore; use taf-fpocket for
  full fpocket/mdpocket/dpocket/tpocket workflows.
  Cite Fpocket as well when using fpocket-rescore.

Detailed documentation:
  https://github.com/rdk/p2rank/blob/2.5.1/README.md
  https://github.com/rdk/p2rank/blob/2.5.1/doc/dataset-file-format.md

Wrapper options:
  taf-p2rank --help       Show this TAFFISH help.
  taf-p2rank --version    Show TAFFISH wrapper version.
  taf-p2rank --compile    Compile the TAFFISH wrapper.
  taf-p2rank -- -v        Pass option-leading arguments to prank.
