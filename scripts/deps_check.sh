#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
TARGETS=("nrepl" "cider/cider-nrepl" "refactor-nrepl" "iced-nrepl")

for TARGET in ${TARGETS[@]}; do
    EXPECTED_VERSION=$(grep "${TARGET} " ${SCRIPT_DIR}/../deps.edn \
        | head -n1 \
        | sed -e 's/["} ]//g' \
        | sed -e 's/:mvn\/version/!/g' \
        | cut -d! -f2 \
    )
    echo "${TARGET}: Expected version = [${EXPECTED_VERSION}]"

    if [ "${TARGET}" = "nrepl" ]; then
        HIT=$(grep "${TARGET}" ${SCRIPT_DIR}/../doc/vim-iced.txt | grep "${EXPECTED_VERSION}" | grep -v iced-nrepl | wc -l)
        if [ ${HIT} -ne 1 ]; then
            echo "=> Invalid document for ${TARGET} dependency."
            exit 1
        else
            echo "=> OK"
        fi
    else
        HIT=$(grep "${TARGET}" ${SCRIPT_DIR}/../doc/vim-iced.txt | grep "${EXPECTED_VERSION}" | wc -l)
        if [ ${HIT} -ne 3 ]; then
            echo "=> Invalid document for ${TARGET} dependency."
            exit 1
        else
            echo "=> OK"
        fi
    fi
done

echo 'bin/iced: Expected to newer than deps.edn'
if [ ${SCRIPT_DIR}/../deps.edn -nt ${SCRIPT_DIR}/../bin/iced ]; then
    echo '=> NG: iced command seems not up-to-date'
    exit 1
else
    echo '=> OK'
fi

exit 0
