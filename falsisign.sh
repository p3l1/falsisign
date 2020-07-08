#!/bin/bash
set -Eeuxo pipefail

usage(){
    cat <<EOF
Falsisign.

Usage:
    falsisign -d <input_pdf> -x <X> -y <Y> [-p <pages>] -s <sign_dir> [-i <init_dir> -z <Z> -t <T> [-q <pages>]] -o <output_pdf>

Options:
    -d <input_pdf>   The PDF document you want to sign
    -x <X>           The horizontal position in pixels of where the signature will be
    -y <Y>           The vertical position in pixels of where the signature will be
    -p <pages>       Optional space-separated list of pages to sign, e.g. '2 4 10'
                     Defaults to all or only the last if -i is specified
    -s <sign_dir>    Directory where the signatures will be randomly chosen
    -i <init_dir>    Optional directory where the initials will be randomly chosen
    -z <Z>           Optional horizontal position in pixels of the initials
    -t <T>           Optional vertical position in pixels of the initials
    -q <pages>       Optional space-separated list of pages to initial
                     Defaults to all but the last
    -o <output_pdf>  The output file name
EOF
    exit "$1"
}

while getopts :hd:x:y:p:s:i:z:t:q:o: flag
do
    case "${flag}" in
        d ) DOCUMENT="${OPTARG}";;
        x ) X="${OPTARG}";;
        y ) Y="${OPTARG}";;
        p ) SIGN_PAGES="${OPTARG}";;
        s ) SIGNATURES_DIR="${OPTARG}";;
        i ) INITIALS_DIR="${OPTARG}";;
        z ) Z="${OPTARG}";;
        t ) T="${OPTARG}";;
        q ) INITIAL_PAGES="${OPTARG}";;
        o ) OUTPUT_FNAME="${OPTARG}";;
        h ) usage 0 ;;
        * ) usage 1 ;;
    esac
done

if [ -z "${DOCUMENT:-}" ] || [ -z "${X:-}" ] || [ -z "${Y:-}" ] || [ -z "${SIGNATURES_DIR:-}" ] || [ -z "${OUTPUT_FNAME}" ]
then
    usage 1
fi

DOCUMENT_BN=$(basename "${DOCUMENT}" .pdf)
TMPDIR=$(mktemp -d --t falsisign-XXXXXXXXXX)

# Extract and convert each page of the PDF
convert +profile '*' "${DOCUMENT}" "${TMPDIR}/${DOCUMENT_BN}.pdf"  # Some PDF trigger errors with their shitty profiles
pdftk "${TMPDIR}/${DOCUMENT_BN}.pdf" burst output "${TMPDIR}/${DOCUMENT_BN}-%04d.pdf"
for page in "${TMPDIR}/${DOCUMENT_BN}"-*.pdf
do
    page_bn=$(basename ${page} .pdf)
    convert "${page}" -density 576 -resize 2480x3508! "${TMPDIR}/${page_bn}.png"
done

# Set which pages are to sign, to initial, or to leave alone
NUMBER_OF_PAGES=$(grep NumberOfPages "${TMPDIR}/"doc_data.txt | grep -E -o '[[:digit:]]+')
ALL_PAGES=$(seq 1 "${NUMBER_OF_PAGES}")
if [ -z "${SIGN_PAGES:-}" ]
then  # SIGN_PAGES default depends on whether we have to initial some pages (-i option)
    if [ -z "${INITIALS_DIR:-}" ]
    then  # If not, we sign all the pages
        SIGN_PAGES="${ALL_PAGES}"
    else  # If so, we sign only the last pages
        SIGN_PAGES="${NUMBER_OF_PAGES}"
    fi
fi
if [ -z "${INITIAL_PAGES:-}" ] && [ -n "${INITIALS_DIRS:-}" ]
then  # The default is to initial all the pages but the last
    INITIAL_PAGES=$(seq 1 $(( "${NUMBER_OF_PAGES}" - 1 )) )
fi

# Sign all the pages to be signed
for PAGE_NB in ${SIGN_PAGES}
do
    page=${TMPDIR}/${DOCUMENT_BN}-$(printf "%04d" "${PAGE_NB}").png
    PAGE_BN=$(basename "${page}" .png)
    SIGNATURE=$(find "${SIGNATURES_DIR}" -name '*.png' | shuf -n 1)
    convert "${page}" "${SIGNATURE}" -geometry "+${X}+${Y}" +profile '*' -composite "${TMPDIR}/${PAGE_BN}"-signed.png
done
# Initial all the pages to be initialed
if [ -n "${INITIAL_PAGES:-}" ]
then
    for PAGE_NB in ${INITIAL_PAGES}
    do
        page=${TMPDIR}/${DOCUMENT_BN}-$(printf "%04d" "${PAGE_NB}").png
        PAGE_BN=$(basename "${page}" .png)
        SIGNATURE=$(find "${INITIALS_DIR}" -name '*.png' | shuf -n 1)
        convert "${page}" "${SIGNATURE}" -geometry "+${Z}+${T}" +profile '*' -composite "${TMPDIR}/${PAGE_BN}"-signed.png
    done
fi
# "Scan" every page
for PAGE_NB in ${ALL_PAGES}
do
    page="${TMPDIR}/${DOCUMENT_BN}"-$(printf "%04d" "${PAGE_NB}").png
    PAGE_BN=$(basename "${page}" .png)
    PAGE_IN="${TMPDIR}/${PAGE_BN}"-signed.png
    if [[ ! -f "${PAGE_IN}" ]]
    then  # This page was neither signed nor initialed
        PAGE_IN="${page}"
    fi
    # https://tex.stackexchange.com/a/94541
    ROTATION=$(shuf -n 1 -e '-' '')$(shuf -n 1 -e $(seq 0 .1 2))
    convert -density 150 "${PAGE_IN}" -linear-stretch 3.5%x10% -blur 0x0.5 -attenuate 0.25 -rotate "${ROTATION}" +noise Gaussian "${TMPDIR}/${PAGE_BN}-scanned.pdf"
done
convert "${TMPDIR}/${DOCUMENT_BN}"-*-scanned.pdf -density 150 -colorspace RGB "${TMPDIR}/${DOCUMENT_BN}"_large.pdf
convert "${TMPDIR}/${DOCUMENT_BN}"_large.pdf -compress Zip "${OUTPUT_FNAME}"
rm -rf ${TMPDIR}
