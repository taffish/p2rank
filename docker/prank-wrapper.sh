#!/bin/sh
set -eu

cache_dir=${PDB_CACHE_DIR:-}
if [ -n "$cache_dir" ]; then
    case "$cache_dir" in
        /*) ;;
        *)
            printf >&2 'prank: PDB_CACHE_DIR must be an absolute container path: %s\n' "$cache_dir"
            exit 2
            ;;
    esac
    if [ ! -d "$cache_dir" ] || [ ! -w "$cache_dir" ]; then
        printf >&2 'prank: PDB_CACHE_DIR is not a writable directory: %s\n' "$cache_dir"
        exit 2
    fi
else
    cache_dir=$(mktemp -d /tmp/taffish-p2rank-chemcomp.XXXXXX)
fi

mkdir -p "$cache_dir/chemcomp"
for source_file in /opt/p2rank/cache/chemcomp/*.cif.gz; do
    target_file="$cache_dir/chemcomp/${source_file##*/}"
    if [ ! -s "$target_file" ]; then
        cp "$source_file" "$target_file"
    fi
done

PDB_CACHE_DIR=$cache_dir
PDB_DIR=$cache_dir
JAVA_OPTS="${JAVA_OPTS:-} -DPDB_CACHE_DIR=$cache_dir -DPDB_DIR=$cache_dir"
export PDB_CACHE_DIR PDB_DIR JAVA_OPTS

exec /opt/p2rank/prank "$@"
