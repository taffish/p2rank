#!/bin/sh
set -eu

mode=${1:-}
tmp=$(mktemp -d /tmp/taf-p2rank-smoke.XXXXXX)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

replay_log() {
    printf >&2 'p2rank smoke failed; bounded log follows: %s\n' "$1"
    sed -n '1,220p' "$1" >&2
}

reject_download_error() {
    if grep -F 'Could not download' "$1" >/dev/null; then
        replay_log "$1"
        exit 1
    fi
}

require_output() {
    if [ ! -s "$1" ]; then
        printf >&2 'p2rank smoke expected a non-empty output: %s\n' "$1"
        replay_log "$2"
        exit 1
    fi
}

grep -v '^HETATM' /opt/p2rank/test_data/1fbl.pdb > "$tmp/1fbl_nohet.pdb"

case "$mode" in
    predict)
        log="$tmp/predict.log"
        status=0
        prank predict -visualizations 0 -threads 1 \
            -o "$tmp/predict" -f "$tmp/1fbl_nohet.pdb" >"$log" 2>&1 || status=$?
        if [ "$status" -ne 0 ]; then
            replay_log "$log"
            exit "$status"
        fi
        require_output "$tmp/predict/1fbl_nohet.pdb_predictions.csv" "$log"
        require_output "$tmp/predict/1fbl_nohet.pdb_residues.csv" "$log"
        if ! grep -F 'pocket1' "$tmp/predict/1fbl_nohet.pdb_predictions.csv" >/dev/null; then
            printf >&2 'p2rank smoke did not find pocket1 in prediction output\n'
            replay_log "$log"
            exit 1
        fi
        reject_download_error "$log"
        ;;
    fpocket-rescore)
        printf 'HEADER: protein\n1fbl_nohet.pdb\n' > "$tmp/mini.ds"
        log="$tmp/fpocket-rescore.log"
        status=0
        prank fpocket-rescore "$tmp/mini.ds" -visualizations 0 -threads 1 \
            -o "$tmp/fpocket_rescore" >"$log" 2>&1 || status=$?
        if [ "$status" -ne 0 ]; then
            replay_log "$log"
            exit "$status"
        fi
        require_output "$tmp/fpocket_rescore/1fbl_nohet.pdb_rescored.csv" "$log"
        require_output "$tmp/fpocket_rescore/1fbl_nohet.pdb_predictions.csv" "$log"
        reject_download_error "$log"
        ;;
    *)
        printf >&2 'usage: taffish-p2rank-smoke {predict|fpocket-rescore}\n'
        exit 2
        ;;
esac
