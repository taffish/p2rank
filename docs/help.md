p2rank 2.5.1-r3

Purpose:
  Predict protein ligand-binding pockets with P2Rank.
  Run P2Rank subcommands through the explicit prank executable.
  fpocket is bundled for prank fpocket-rescore.

Usage:
  taf-p2rank prank predict -f protein.pdb -threads 4 -visualizations 0 -o p2rank_out
  taf-p2rank prank predict proteins.ds -o p2rank_dataset_out
  taf-p2rank -- -v
  taf-p2rank prank help

Common tasks:
  taf-p2rank prank predict -f protein.cif -c alphafold -o alphafold_out
  taf-p2rank prank rescore fpocket.ds -o p2rank_rescore_out
  taf-p2rank prank fpocket-rescore proteins.ds -fpocket_keep_output 0 -o fpocket_out

Required inputs:
  protein.pdb/.cif/.bcif     Protein structure; compressed forms also work
  proteins.ds                P2Rank dataset file
  fpocket.ds                 Prediction/protein pairs for rescoring

Common options:
  -f FILE                    Run on one structure
  -o DIR                     Select the output directory
  -c PROFILE_OR_FILE         Select an upstream profile or custom config
  -threads N                 Select P2Rank worker threads
  -visualizations 0          Skip PyMOL/ChimeraX script generation

Key outputs:
  *_predictions.csv          Ranked predicted pockets
  *_residues.csv             Residue-level scores and assignments
  *_rescored.csv             Rescored pockets
  visualizations/            Optional viewer scripts and SAS point data

Backend-specific use:
  Docker:
    TAFFISH_CONTAINER_BACKEND=docker taf-p2rank prank predict -f protein.pdb -o out
  Podman:
    TAFFISH_CONTAINER_BACKEND=podman taf-p2rank prank predict -f protein.pdb -o out
  Apptainer on linux/amd64:
    TAFFISH_CONTAINER_BACKEND=apptainer taf-p2rank prank predict -f protein.pdb -o out
  Docker/Podman arm64 hosts use app-encoded amd64 emulation.
  Apptainer arm64 is unsupported; use Docker or Podman instead.

Optional persistent chemical-component cache:
  mkdir -p "$HOME/.cache/taffish/p2rank/chemcomp/2.5.1"
  Set TAFFISH_P2RANK_CHEMCOMP_CACHE_PATH to that absolute writable directory.
  Docker, Podman, and Apptainer then create an actual read-write cache bind.
  Docker runs as your host UID/GID so persistent cache files remain user-owned.
  Invalid or unsafe paths stop in wrapper preflight before a backend is started.
  Example:
    TAFFISH_P2RANK_CHEMCOMP_CACHE_PATH="$HOME/.cache/taffish/p2rank/chemcomp/2.5.1" \
      taf-p2rank prank predict -f protein_with_ligand.pdb -o out

Immediate notes:
  Bare predict/rescore tokens are executable names in automatic command mode;
  keep the explicit prank prefix for P2Rank subcommands.
  Bundled P2Rank models and common BioJava definitions work offline.
  Container /tmp must be writable and executable for cache and Java extraction.
  PyMOL, ChimeraX, and PrankWeb are not included.
  Use taf-fpocket for full fpocket/mdpocket/dpocket/tpocket workflows.

More help:
  taf-p2rank prank help
  https://github.com/rdk/p2rank/blob/2.5.1/README.md
  https://github.com/rdk/p2rank/blob/2.5.1/doc/dataset-file-format.md

Wrapper options:
  taf-p2rank --help       Show this TAFFISH help.
  taf-p2rank --version    Show TAFFISH wrapper version.
  taf-p2rank --compile    Print the generated wrapper shell.
  taf-p2rank -- -v        Pass an option-leading argument to prank.
