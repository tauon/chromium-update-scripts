#!/bin/bash
# chromium_update.sh v1
# A script to download and unzip the latest chromium nightly (OSX).
# --
# Copyright (c) 2010 Jeff Bidzos <jbidzos@gatech.edu>
# All rights reserved.

CHROME_DIR="${HOME}/chromium"
CHROME_TEMP="${CHROME_DIR}/.chromium_update"
LOGFILE="${CHROME_DIR}/update.log"

LATEST="0"

if [ ! -d ${CHROME_DIR} ]; then
    mkdir ${CHROME_DIR}
fi

function log() {
    if [[ ! -e ${LOGFILE} ]];then
		touch $LOGFILE
    fi
    message="$@"
    echo $(date)" > "${message}
    echo $(date)" > "${message} >> ${LOGFILE}
}

log "[**] Chromium Updater running... [**]"

if [ ! -d ${CHROME_TEMP} ]; then
    log "Creating temp directory."
    mkdir ${CHROME_TEMP}
fi

if [[ -e "${CHROME_TEMP}/STATUS" ]];then
    STATUS=`cat ${CHROME_TEMP}/STATUS`
else
    STATUS="255" # first run
    echo ${STATUS} > ${CHROME_TEMP}/STATUS
fi

log "Current status is: ${STATUS}"

if [[ -e "${CHROME_TEMP}/CURRENT" ]];then
    CURRENT=`cat ${CHROME_TEMP}/CURRENT`
else
    CURRENT="0" # no current
    echo ${CURRENT} > ${CHROME_TEMP}/STATUS
fi

log "Local build is: ${CURRENT}"

function remove_local_archive() {
    if [[ -e "${CHROME_DIR}/chrome-mac.zip" ]];then
        rm ${CHROME_DIR}/chrome-mac.zip
        log "Local build archive removed."
    fi
}

function fetch_latest_build_number() {
    log "Fetching latest build number..."
    curl -L http://build.chromium.org/f/chromium/snapshots/Mac/LATEST -o ${CHROME_TEMP}/LATEST
    LATEST=`cat ${CHROME_TEMP}/LATEST`
    log "Latest is: ${LATEST}"
}

function fetch_latest_build() {
    log "Fetching build: ${LATEST} ..."
    url="http://build.chromium.org/f/chromium/snapshots/Mac/${LATEST}/chrome-mac.zip"
    curl -L "${url}" -o ${CHROME_TEMP}/chrome-mac.zip
    if [[ $? -eq 0 ]];then
		log "GOOD. Update fetch completed sucessfully."
    else
		log "FAIL. Update fetch failed."
		echo "1" > ${CHROME_TEMP}/STATUS
		exit 1
    fi
    unzip -o ${CHROME_TEMP}/chrome-mac.zip -d "${CHROME_DIR}"
    if [[ $? -eq 0 ]];then
        log "GOOD. Update archive extracted sucessfully."
    else
        log "FAIL. Archive extraction failed"
        echo "2" > ${CHROME_TEMP}/STATUS
        exit 2
    fi
    echo ${LATEST} > ${CHROME_TEMP}/CURRENT
    echo "0" > ${CHROME_TEMP}/STATUS
    log "SUCCESS. Local archive updated to ${LATEST} from ${CURRENT}."
    exit 0
}

if (( ${STATUS} == 0 ));then
    fetch_latest_build_number
    if (( ${LATEST} > ${CURRENT} ));then
		log "Local build is outdated ${CURRENT} < ${LATEST}"
		echo "1" > ${CHROME_TEMP}/STATUS
		fetch_latest_build
    else
		log "UPTODATE. Build ${CURRENT} is current and no update needed."
    fi
else
    log "Non-zero status. Fetching latest build."
    fetch_latest_build_number
    fetch_latest_build
fi
