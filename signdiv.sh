#!/bin/bash
set -Eeuxo pipefail

SIGNATURES=$1
TMPDIR=$(mktemp -d -t falsisign-XXXXXXXXXX)
SIGNATURES_BN=$(basename "${SIGNATURES}" .pdf)

convert -density 576 -resize 2480x3508! -transparent white "${SIGNATURES}" "${TMPDIR}/${SIGNATURES_BN}.png"
file "${TMPDIR}/${SIGNATURES_BN}.png" | grep ' PNG image data, 2480 x 3508'  # We must have exactly the right resolution

mkdir -p "${SIGNATURES_BN}"
for start_y in $(seq 0 390 3507)
do
    for start_x in 0 750 1500
    do
        convert "${TMPDIR}/${SIGNATURES_BN}.png" -crop "750x390+${start_x}+${start_y}" +repage \
                "${SIGNATURES_BN}/${SIGNATURES_BN}_${start_x}x${start_y}".png
    done
done
rm -rf ${TMPDIR}
