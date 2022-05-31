#!/bin/bash
set -Eeuxo pipefail

usage(){
    cat <<EOF
Signdiv.

Divide a page full of signatures into 27 individual signature files to be used by falsisign.

Usage:
    signdiv [-X <offset_x>] [-Y <offset_y>] [-x <margin_x>] [-y <margin_y] -d <input_file>

Options:
    -d <input_pdf>   The PDF document you scanned your signatures to.
    -X <offset_x>    The horizontal position in pixels of the start of the grid.
    -Y <offset_y>    The vertical position in pixels of the start of the grid.
    -x <margin_x>    The number of pixels to remove from the vertical borders of each signature.
    -y <margin_y>    The number of pixels to remove from the horizontal borders of each signature.
EOF
    exit "$1"
}

while getopts :hd:x:y:X:Y: flag
do
    case "${flag}" in
        d ) SIGNATURES="${OPTARG}";;
        X ) OFFSET_X="${OPTARG}";;
        Y ) OFFSET_Y="${OPTARG}";;
        x ) MARGIN_X="${OPTARG}";;
        y ) MARGIN_Y="${OPTARG}";;
        h ) usage 0 ;;
        * ) usage 1 ;;
    esac
done

if [ -z ${OFFSET_X+x} ]
then
    OFFSET_X=0
fi
if [ -z ${OFFSET_Y+x} ]
then
    OFFSET_Y=0
fi
if [ -z ${MARGIN_X+x} ]
then
    MARGIN_X=5
fi
if [ -z ${MARGIN_Y+x} ]
then
    MARGIN_Y=5
fi


TMPDIR=$(mktemp -d -t falsisign-XXXXXXXXXX)
SIGNATURES_BN=$(basename "${SIGNATURES}" .pdf)

convert -density 576 -resize 2480x3508! -transparent white "${SIGNATURES}" "${TMPDIR}/${SIGNATURES_BN}.png"
file "${TMPDIR}/${SIGNATURES_BN}.png" | grep ' PNG image data, 2480 x 3508'  # We must have exactly the right resolution

mkdir -p "${SIGNATURES_BN}"
width=$(( 750 - "${MARGIN_X}" * 2 ))
height=$(( 390 - "${MARGIN_Y}" * 2 ))
for start_y in $(seq 0 390 3507)
do
    actual_start_y=$(( "${start_y}" + "${OFFSET_Y}" + "${MARGIN_Y}" ))
    for start_x in 0 750 1500
    do
        actual_start_x=$(( "${start_x}" + "${OFFSET_X}" + "${MARGIN_X}" ))
        convert "${TMPDIR}/${SIGNATURES_BN}.png" -crop \
            "${width}x${height}+${actual_start_x}+${actual_start_y}" +repage \
            "${SIGNATURES_BN}/${SIGNATURES_BN}_${start_x}x${start_y}".png
    done
done
rm -rf ${TMPDIR}
