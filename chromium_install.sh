#!/bin/bash
# chromium_install.sh v1
# A script to install a downloaded chromium nightly build
# to Applications directory (OSX).
# --
# Copyright (c) 2010 Jeff Bidzos <jbidzos@gatech.edu>
# All rights reserved.


CHROME_DIR="${HOME}/chromium"
CHROME_TEMP="${CHROME_DIR}/.chromium_update"
LOGFILE="${CHROME_DIR}/update.log"
APP_DIR="/Applications/"
CHROME_DOWNLOAD_DIR="${CHROME_DIR}/chrome-mac"
PROCNAME="Chromium.app"

if [ ! -d ${CHROME_DIR} ]; then
    echo "Chrome download directory not found. Exiting."
    exit 1
fi

function log() {
    if [[ ! -e ${LOGFILE} ]];then
		touch $LOGFILE
    fi
    message="$@"
    echo $(date)" > "${message}
    echo $(date)" > "${message} >> ${LOGFILE}
}

function ask()
{
    echo -n "$@" '[y/n] '
    read ans
    case "$ans" in y*|Y*) return 0 ;; *) return 1 ;; esac
}

function kill_running() {
    pidnos=$(ps ax | grep -v "ps ax" | grep -v grep | grep ${PROCNAME} | awk '{ print $1 }')
    if [ -z "$pidnos" ];then
		return 0
    else
		if ask "Kill running Chromium and proceed?";then
	    	for pid in $pidnos; do
				kill $pid
            done
		else
	    	return 1
		fi
    fi
}

log "[**] Chromium Installer running... [**]"

if [ ! -d ${CHROME_TEMP} ]; then
    log "FAIL. No download directory found. Quitting."
    exit 1
fi

if [[ -e "${CHROME_TEMP}/INSTALLED" ]];then
    INSTALLED=`cat ${CHROME_TEMP}/INSTALLED`
else
    INSTALLED="0" # first run
fi

if [[ -e "${CHROME_TEMP}/STATUS" ]];then
    STATUS=`cat ${CHROME_TEMP}/STATUS`
else
    log "FAIL. Unknown download status. Quitting."
    exit 1
fi

if [[ ! ${STATUS} -eq 0 ]];then
    log "FAIL. Bad download status (${STATUS}). Quitting."
    exit 1
fi

log "Current installed version is: ${INSTALLED}"

if [[ -e "${CHROME_TEMP}/CURRENT" ]];then
    CURRENT=`cat ${CHROME_TEMP}/CURRENT`
else
    log "FAIL. No current version to install. Quitting."
    exit 1
fi

log "Local downloaded build is: ${CURRENT}"

function remove_local_archive() {
    if [[ -e "${CHROME_DIR}/chrome-mac.zip" ]];then
        rm ${CHROME_DIR}/chrome-mac.zip
        log "Local build archive removed."
    fi
}

if [[ ${CURRENT} -gt ${INSTALLED} ]];then
    log "More recent version downloaded. Installing..."
    if [[ ! -d ${CHROME_DOWNLOAD_DIR} ]];then
	log "FAIL. No local download directory found. Quitting."
	exit 1
    else
	if kill_running; then
	    cp -r ${CHROME_DOWNLOAD_DIR}/Chromium.app ${APP_DIR}
	    if [[ $? -eq 0 ]];then
		echo ${CURRENT} > ${CHROME_TEMP}/INSTALLED
		remove_local_archive
		log "SUCCESS. Latest download installed."
	    else
		log "FAIL. Error when copying to app directory."
		exit 1
	    fi
	else
	    log "ABORT. Chromium running and install cannot complete."
	    exit 1
	fi
    fi
else
    log "No need to install. Quitting."
    exit 0
