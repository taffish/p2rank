# p2rank

`p2rank` packages P2Rank for TAFFISH.

Package identity:

- name: `p2rank`
- command: `taf-p2rank`
- kind: `tool`
- version: `2.5.1-r2`
- license: Apache-2.0
- upstream: <https://github.com/rdk/p2rank>

## What This App Packages

P2Rank is a command-line program for predicting protein ligand-binding sites
from PDB, mmCIF, BinaryCIF, and compressed structure files. The default
upstream command is `prank`.

The image contains the upstream P2Rank 2.5.1 binary release, OpenJDK 17, all
models and configuration profiles shipped in that release, and Fpocket 4.2.3
for the upstream `prank fpocket-rescore` workflow.

## Same-Upstream Backend Repair

Release `2.5.1-r2` is a same-upstream successor to the immutable
`2.5.1-r1` release. In a read-only Apptainer SIF, BioJava rejected
`/opt/p2rank/cache` because the image root was not writable, silently changed
its cache root to `/tmp`, and then tried to download common chemical
components. The old prediction smoke also lacked fail-fast shell semantics, so
a missing output could be hidden by its final cleanup command.

The r2 launcher now copies the 56 reduced BioJava definitions from the
read-only image into a unique writable directory under `/tmp`, sets both the
environment variables and Java system properties to that directory, and then
executes the unmodified upstream launcher. The smoke paths now preserve command
status, assert non-empty outputs, reject download errors, and replay bounded
logs on failure.

## Scope

This app supports:

- `prank predict` on individual structures and P2Rank dataset files.
- `prank rescore`, `fpocket-rescore`, `eval-predict`, and
  `eval-rescore`.
- The upstream `default`, `alphafold`, `default_rescore`,
  `rescore_2024`, and conservation-oriented profiles.
- Optional persistence of BioJava's on-demand chemical-component cache through
  an app-managed host bind.

This app does not:

- Package a desktop viewer. PyMOL and ChimeraX are optional upstream viewers
  for generated `.pml` and `.cxc` scripts.
- Package PrankWeb; that is a separate companion web service.
- Package P2Rank's source-training environment or provide a general interface
  for project-specific trained models.
- Replace the dedicated full `taf-fpocket` app.

## Container Contents

- `prank`: app launcher followed by the unmodified P2Rank 2.5.1 launcher.
- `fpocket`: Fpocket 4.2.3 helper for `prank fpocket-rescore`.
- `java`: OpenJDK 17 runtime.
- `/opt/p2rank/models`: six upstream model directories plus score transforms.
- `/opt/p2rank/config`: upstream configuration profiles.
- `/opt/p2rank/cache/chemcomp`: 56 read-only reduced BioJava definitions.
- `taffish-p2rank-smoke`: packaging smoke helper used by the Index contract.

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

Use the AlphaFold profile:

```sh
taf-p2rank predict -f alphafold_model.cif -c alphafold -o alphafold_out
```

Run Fpocket and rescore its pockets:

```sh
taf-p2rank fpocket-rescore proteins.ds -fpocket_keep_output 0 -o fpocket_rescore_out
```

## Backend Usage and Capability Matrix

| Capability | Docker | Podman | Apptainer | Validation and boundary |
| --- | --- | --- | --- | --- |
| Standard CLI and bundled models | `TAFFISH_CONTAINER_BACKEND=docker taf-p2rank predict ...` | `TAFFISH_CONTAINER_BACKEND=podman taf-p2rank predict ...` | `TAFFISH_CONTAINER_BACKEND=apptainer taf-p2rank predict ...` | Exact normal and read-only-root smoke passed for r2. |
| Optional writable chemcomp cache | `TAFFISH_P2RANK_CHEMCOMP_CACHE_PATH=/absolute/cache TAFFISH_CONTAINER_BACKEND=docker taf-p2rank ...` | Same with `podman` | Same with `apptainer` | `src/main.taf` emits an actual read-write bind to `/p2rank-cache`; the path must already exist and be writable. |
| `linux/amd64` image | Native on amd64; app-encoded emulation on arm64 | Native on amd64; app-encoded emulation on arm64 | Native amd64 host required | Fpocket is the architecture-limiting component. Use Docker or Podman emulation on an arm64 host. |
| Writable executable temporary space | Standard container `/tmp` | Standard container `/tmp` | Standard SIF `/tmp` | Required for the chemcomp working copy and Java zstd native extraction; a site `noexec` policy on `/tmp` is incompatible. |

The Docker/Podman `--platform linux/amd64` requirement is encoded in
`src/main.taf`; users should not repeat it in global run arguments.

## Command Mode

`taf-p2rank` defaults to `prank`, so `taf-p2rank predict ...` runs the
upstream prediction command. Automatic command mode remains available for
packaged executables.

Use `taf-p2rank -- -v` for an option-leading argument to the default command.
Use `taf-p2rank prank help` for explicit upstream help. The `--` separator
does not turn a P2Rank subcommand into a wrapper option.

## Inputs

| Input | Meaning | Notes |
| --- | --- | --- |
| PDB/mmCIF/BCIF structure | Protein structure for prediction | `.gz` and `.zst` compressed inputs are supported upstream. |
| P2Rank dataset file | List of structures or prediction/protein pairs | See the upstream dataset-file-format manual. |
| Fpocket predictions | Existing pockets for rescoring | `fpocket-rescore` can create them with the bundled helper. |
| Custom config | P2Rank parameter overrides | Pass a file with `-c path/to/config.groovy`. |

## Output Notes

Prediction writes `*_predictions.csv` and `*_residues.csv`. Rescoring
writes `*_rescored.csv` and prediction-compatible pocket tables. Unless
`-visualizations 0` is used, P2Rank also writes visualization scripts and SAS
point data.

P2Rank writes to the `-o` directory. Keep that directory in the wrapper's
bound working directory so the result persists on the host.

## Resources, Databases, and Platform

### Bundled models

The upstream release asset contains all six model directories used by the
packaged profiles. They occupy about 199 MiB and are covered by the pinned
P2Rank release SHA256. They are immutable image content, require no runtime
download, and need no host model mount. Training outputs are project-specific
inputs and are outside this runtime app's supported surface.

### Chemical-component definitions

Normal offline prediction uses 56 reduced definitions extracted from the
pinned BioJava jar. The image copy stays read-only; every `prank` process
seeds a unique writable runtime cache under `/tmp`.

BioJava can request additional RCSB component definitions for uncommon input.
Those individual files are an optional mutable convenience cache, not a fixed
P2Rank model or a release-pinned production database. To persist them, create
an empty writable directory and set the app-specific host path:

```sh
mkdir -p "$HOME/.cache/taffish/p2rank/chemcomp/2.5.1"
TAFFISH_P2RANK_CHEMCOMP_CACHE_PATH="$HOME/.cache/taffish/p2rank/chemcomp/2.5.1" \
  taf-p2rank predict -f protein_with_ligand.pdb -o out
```

The app validates the host directory and binds it read-write at
`/p2rank-cache` on Docker, Podman, and Apptainer. Missing reduced definitions
are copied without overwriting existing files. Additional definitions may be
downloaded only if the selected backend permits network access and BioJava
actually requests them. There is no bulk app downloader: upstream BioJava
2.5.1's integration resolves individual components lazily and exposes no fixed
P2Rank cache bundle. For a reproducible project, preserve and checksum the
resulting directory or run offline with only the bundled definitions.

Paths containing whitespace, commas, colons, or glob characters are rejected
because they cannot be represented safely and consistently by all three
backend bind syntaxes.

### Runtime write map

| Path | Writer | Lifetime |
| --- | --- | --- |
| `/tmp/taffish-p2rank-chemcomp.*` | launcher/BioJava | Per container when no persistent cache is selected |
| Backend `/tmp` | Java native extraction and smoke scratch | Per container |
| Wrapper working directory / `-o` | P2Rank and Fpocket | Host-persistent project output |
| `/p2rank-cache` | BioJava | Optional actual host bind selected by `TAFFISH_P2RANK_CHEMCOMP_CACHE_PATH` |

No runtime path writes to `/opt`, `/usr`, or another image-root directory.

## GUI and Companion Boundary

Official P2Rank documents optional PyMOL and ChimeraX viewers and the separate
PrankWeb companion. This app generates the upstream visualization scripts but
does not start a GUI, browser service, VNC/noVNC session, port, or long-running
helper. The GUI/service rules are therefore not part of this CLI release's
runtime surface; open generated scripts in a separately installed viewer, or
use PrankWeb independently.

## Boundaries

The bundled Fpocket binary exists to satisfy P2Rank's documented
`fpocket-rescore` subprocess. Use `taf-fpocket` for the full Fpocket suite.

The image is declared only for `linux/amd64`. Docker and Podman arm64 hosts
can use the app-encoded amd64 emulation. Apptainer does not provide that
emulation contract, so an arm64 Apptainer host should use Docker/Podman instead.

## Troubleshooting

- `PDB_CACHE_DIR is not a writable directory`: use the app-specific
  `TAFFISH_P2RANK_CHEMCOMP_CACHE_PATH` host variable and an existing writable
  directory; do not point Java directly at the read-only image cache.
- `Could not download ... chemcomp`: normal common-residue parsing should not
  emit this. For an uncommon ligand, allow network for one run with a persistent
  cache, or preserve the required definition before an offline run.
- Native library extraction failure under `/tmp`: remove a site `noexec`
  policy for this container or provide a backend configuration with writable,
  executable container temporary space.
- On arm64, use Docker or Podman so the app-encoded amd64 platform emulation is
  applied.

## Testing

Candidate image identity:

- `sha256:f50e1b469729566e70eab05ecf868ce529ef8979eeeffe5bb170941982d5fdd0`
- `linux/amd64`, 657,689,342 bytes
- P2Rank content: about 293 MiB, including about 199 MiB models and 69 MiB jars
- OpenJDK runtime: about 184 MiB
- Fpocket runtime: about 1.8 MiB
- the initial 308 MB recursive-permission duplicate layer was removed before
  final validation

Exact direct-smoke status for the final candidate:

- Docker: 8/8 `exist` and 5/5 `test` PASS in normal containers; the same
  13/13 PASS in read-only-root, non-root proxies with only executable
  `/tmp` writable.
- Podman 5.2.5: the same normal and read-only-root matrices PASS.
- Apptainer 1.4.2: an actual SIF built from the same final OCI content passed
  all 8 `exist` and 5 `test` commands in separate clean, contained,
  network-isolated executions.
- Real `taf-p2rank` wrapper cache binds were exercised for Docker, Podman, and
  Apptainer; each actual host directory received all 56 bundled definitions,
  including `chemcomp/PHE.cif.gz`. Podman and Apptainer wrapper prediction and
  `fpocket-rescore` paths also completed successfully.
- `taf publish --build --release --dry-run` completed with the remote checked:
  the latest published release is still `v2.5.1-r1`, while the r2 tag and
  GitHub Release are absent as expected.
- Approved backend exception: none.

The smoke covers release identity, help, Fpocket linkage, offline prediction,
prediction outputs, and `fpocket-rescore`. It does not replace scientific
validation on production structures.

## License and Citation

TAFFISH app packaging: Apache-2.0.

P2Rank is MIT-licensed. Fpocket 4.2.3 is MIT-licensed, and the Qhull notice is
retained in the image.

Primary P2Rank citation:

Krivak R, Hoksza D. P2Rank: machine learning based tool for rapid and accurate
prediction of ligand binding sites from protein structure. Journal of
Cheminformatics. 2018;10:39. <https://doi.org/10.1186/s13321-018-0285-8>

When using `fpocket-rescore`, also cite Fpocket according to its upstream
guidance.
