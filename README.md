# p2rank

`p2rank` packages P2Rank for TAFFISH.

Package identity:

- name: `p2rank`
- command: `taf-p2rank`
- kind: `tool`
- version: `2.5.1-r1`
- license: Apache-2.0
- upstream: <https://github.com/rdk/p2rank>

## What This App Packages

P2Rank is a standalone command-line program for fast prediction of protein
ligand-binding sites from PDB, mmCIF, binary CIF, and compressed structure
files. The packaged upstream command is `prank`.

This app uses the upstream binary release `p2rank_2.5.1.tar.gz`, OpenJDK 17,
the upstream models/configuration/test data, and a bundled `fpocket` 4.2.3
helper so that `prank fpocket-rescore ...` works inside the same container.

## Scope

This app supports:

- `prank predict` for P2Rank pocket prediction on individual structure files or
  dataset files.
- `prank rescore` and `prank fpocket-rescore` for rescoring precomputed or
  Fpocket-generated pockets.
- `prank eval-predict` and `prank eval-rescore` for upstream evaluation
  workflows on datasets with known ligands.
- Upstream P2Rank models and configuration profiles, including `default`,
  `alphafold`, `default_rescore`, `rescore_2024`, and conservation-oriented
  profiles.

This app does not:

- Include PyMOL or ChimeraX. P2Rank can generate `.pml` and `.cxc`
  visualization scripts, but viewing them requires external desktop software.
- Provide a web server. PrankWeb is separate from this command-line runtime.
- Bundle the full RCSB chemical component dictionary. A reduced BioJava
  chemcomp cache is preloaded for common residues and the smoke-tested paths;
  unusual ligands may use BioJava fallback behavior or a user-provided cache.

## Container Contents

- `prank`: P2Rank 2.5.1 command-line entry point.
- `fpocket`: Fpocket 4.2.3 helper used by `prank fpocket-rescore`.
- OpenJDK 17 runtime.
- `/opt/p2rank/models`, `/opt/p2rank/config`, and `/opt/p2rank/test_data` from
  the upstream P2Rank release.
- `/opt/p2rank/cache/chemcomp`: reduced BioJava chemical component cache
  extracted from the bundled BioJava jar.

## Usage

Show upstream version and help:

```sh
taf-p2rank -- -v
taf-p2rank prank help
```

Predict pockets for one structure:

```sh
taf-p2rank predict -f protein.pdb -threads 4 -visualizations 0 -o p2rank_out
```

Predict with a P2Rank dataset file:

```sh
taf-p2rank predict proteins.ds -threads 4 -o p2rank_dataset_out
```

Use another upstream configuration:

```sh
taf-p2rank predict -f alphafold_model.cif -c alphafold -o alphafold_p2rank_out
```

Rescore existing Fpocket predictions:

```sh
taf-p2rank rescore fpocket.ds -o p2rank_rescore_out
```

Run Fpocket and rescore in one command:

```sh
taf-p2rank fpocket-rescore proteins.ds -fpocket_keep_output 0 -o fpocket_rescore_out
```

## Command Mode

`taf-p2rank` defaults to `prank`, so `taf-p2rank predict ...` runs
`prank predict ...` inside the container. Automatic command mode is also
enabled for helper inspection, for example `taf-p2rank fpocket` prints the
bundled helper's usage text. The packaged Fpocket binary is present to support
P2Rank's `fpocket-rescore` workflow, not to replace the dedicated
`taf-fpocket` app.

Use `taf-p2rank -- -v` for option-leading arguments to the default `prank`
command. Use `taf-p2rank prank help` or `taf-p2rank -- help` for upstream help.

## Inputs

| Input | Meaning | Notes |
| --- | --- | --- |
| PDB/mmCIF/BCIF structure | Protein structure for prediction | P2Rank also accepts `.gz` and `.zst` examples from upstream. |
| P2Rank dataset file | Text file listing structures or prediction/protein pairs | See upstream `doc/dataset-file-format.md`. |
| Fpocket output | Pocket predictions for `prank rescore` | `prank fpocket-rescore` can generate these automatically with bundled `fpocket`. |

## Output Notes

For prediction, P2Rank writes files such as:

- `{struct_file}_predictions.csv`: predicted pockets, scores, centers,
  adjacent residues/atoms, and probabilities.
- `{struct_file}_residues.csv`: residue-level scores and pocket assignments.
- Optional visualization scripts and SAS point data when visualizations are
  enabled.

For rescoring, P2Rank writes files such as `{struct_file}_rescored.csv` and, for
`fpocket-rescore`, `predictions.csv` style outputs that can often replace direct
`predict` output in downstream workflows.

## Resources, Databases, and Platform

P2Rank models are bundled in the upstream release and no template database is
required for normal prediction. BioJava may consult chemical component
definitions while parsing structures; this image preloads the reduced
definitions included with upstream BioJava and sets `PDB_CACHE_DIR` and
`PDB_DIR` to `/opt/p2rank/cache`.

For unusual ligands not present in the reduced cache, users can provide a
writable cache by mounting a directory and setting `PDB_CACHE_DIR`, for example:

```sh
TAFFISH_DOCKER_RUN_ARGS="-v $PWD/p2rank-cache:/data/p2rank-cache -e PDB_CACHE_DIR=/data/p2rank-cache" \
  taf-p2rank predict -f protein_with_custom_ligand.pdb -o out
```

This app is built for `linux/amd64`. P2Rank itself is Java-based, but the
bundled `fpocket` helper uses upstream Linux amd64 plugin assets, so the
published image is intentionally not declared as native `linux/arm64`.
`src/main.taf` declares Docker/Podman `--platform linux/amd64`, so arm64 hosts
can use backend emulation without setting that option manually.

## Boundaries

The image includes Fpocket only as a helper for P2Rank's upstream
`fpocket-rescore` command. It does not package or test the full Fpocket suite.
For full Fpocket, mdpocket, dpocket, or tpocket workflows, use the dedicated
`taf-fpocket` app.

If `fpocket-rescore` is used in scientific work, cite Fpocket as well as
P2Rank, following upstream guidance.

Upstream tracking is marked manual because the upstream tag space includes
development and alpha tags in addition to stable GitHub Releases. This package
uses the stable P2Rank 2.5.1 release asset and records the exact upstream
commit and SHA256 in `taffish.toml` and `release.md`.

## Troubleshooting

- If upstream help exits with a nonzero status, that is P2Rank's normal `prank
  help` behavior; the text is still printed.
- If BioJava reports missing chemical component definitions for unusual
  ligands, provide or mount a writable `PDB_CACHE_DIR`, or use structures where
  such ligand details are not needed for the intended prediction workflow.
- For Apple Silicon or other arm64 hosts, Docker/Podman should use amd64
  emulation through the platform option embedded in `src/main.taf`.

## Testing

The smoke test covers:

- wrapper metadata and upstream version identity
- presence of `prank`, Java, and bundled `fpocket`
- model/config/test-data availability
- a minimal offline `prank predict` path on a stripped PDB fixture
- a minimal offline `prank fpocket-rescore` path with bundled Fpocket
- dynamic-library completeness for Fpocket

It does not validate full Fpocket workflows, and it does not replace full
scientific validation on production structures or large benchmark datasets.

## License and Citation

TAFFISH app packaging: Apache-2.0.

P2Rank is distributed under the MIT License. This image also bundles Fpocket
4.2.3 as an MIT-licensed helper with its upstream Qhull notice retained under
`/opt/fpocket/share/licenses/fpocket`.

Primary P2Rank citation:

Krivak R, Hoksza D. P2Rank: machine learning based tool for rapid and accurate
prediction of ligand binding sites from protein structure. Journal of
Cheminformatics. 2018;10:39. <https://doi.org/10.1186/s13321-018-0285-8>

Fpocket citation for `fpocket-rescore` workflows:

Le Guilloux V, Schmidtke P, Tuffery P. Fpocket: an open source platform for
ligand pocket detection. BMC Bioinformatics. 2009;10:168.
<https://doi.org/10.1186/1471-2105-10-168>
