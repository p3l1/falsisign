#!/bin/bash
set -Eeuxo pipefail

TMPDIR=$(mktemp -d -t falsisign-XXXXXXXXXX)
# https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

cp "${SCRIPT_DIR}/Signature_example.pdf" "${TMPDIR}"/
cp "${SCRIPT_DIR}/document.pdf" "${TMPDIR}"/

cd "${TMPDIR}"

"${SCRIPT_DIR}/signdiv.sh" -d Signature_example.pdf
"${SCRIPT_DIR}/falsisign.sh" -d document.pdf -x 100 -y 100 -s Signature_example -o signed.pdf

rm -rf ${TMPDIR}
