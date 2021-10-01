#!/bin/bash

_ARKBINLOC="/ARK"
_ARKBIN=${_ARKBINLOC}/ShooterGame/Binaries/Linux/ShooterGameServer
_ARKCONFIGSTRING="${__ARKMAP}?SessionName=${__ARKINSTANCE}?Port=${__ARKPORT}?QueryPort=${__ARKQPORT}?AltSaveDirectoryName=${__ARKINSTANCE}?OverrideStructurePlatformPrevention=True -NoTransferFromFiltering -servergamelog -server -log -clusterid=${__ARKCLUSTER}"
_ARKBACKUPDIR="/ARK_BACKUP"
# _ARKSCREEN="${__ARKINSTANCE}-screen"
_ARKWORLDDIR="${_ARKBINLOC}/ShooterGame/Saved"

STEAM_bin=/home/steam/steamcmd/steamcmd.sh
STEAM_updateCmd="${STEAM_bin} +login anonymous +force_install_dir ${_ARKBINLOC} +app_update 376030 validate +quit"

SYS_lockfile=/tmp/${__ARKINSTANCE}_lockfile
SYS_stopfile=/tmp/${__ARKINSTANCE}_stopfile

main() {
	if [ $# -lt 1 ]; then
		printUsageMessage "$@"
	else
		echo "Running command: $1..."

		case "$1" in
		"start")
			startARKServer
			;;	
		"stop")
			stopARKServer
			;;
		"restart")
			stopARKServer
			startARKServer
			;;
		"update")
			updateARKServer
			;;
		"updateAndRestart")
			updateARKServer
			stopARKServer
			startARKServer
			;;
		"backup")
			backupARKServer
			;;
		"info")
			getInfo
			;;
		*)
			printUsageMessage "$@"
		esac
	fi
}

getARKInstance() {
	pgrep -f "${__ARKINSTANCE}"
}

getInfo() {
	echo "

	ARK Instance: $(getARKInstance)
	Current ARK Map: ${__ARKMAP}
	Launch config string: ${_ARKCONFIGSTRING}
	World Directory: ${_ARKWORLDDIR}
	"
}

printUsageMessage() {
	echo "Usage: $0 [start|stop|update|updateAndRestart|restart|backup]"	
}

backupARKServer() {
	# Backup logs
	echo "Backing up logs..."
	backupLogs

	Backup_Name=${__ARKINSTANCE}
	if [[ -z "${__ARKINSTANCE}" ]]; then
		echo "No ARKINSTANCE name passed; using generic term CLUSTER..."
		Backup_Name="CLUSTER"
	fi

	echo "Backing up server files..."
	zip -qr "/tmp/${Backup_Name}_Saved.zip" ${_ARKWORLDDIR}/

	echo "Copying files to remote backup..."
	#rclone -q sync /tmp/${Backup_Name}_Saved.zip ${_ARKBACKUPDIR}
	rsync -a "/tmp/${Backup_Name}_Saved.zip" ${_ARKBACKUPDIR}/

	echo "Removing backup file..."
	rm "/tmp/${Backup_Name}_Saved.zip"
}

startARKServer() {
	ARKInstance=$(getARKInstance)

	# Output some beginning information to help with any debugging
	env
	ps faux

	if [[ ${ARKInstance} ]]; then
		echo "ARK already running (pid ${ARKInstance})..."
	else
		echo "Starting ARK Server..."

		# screen -dmS ${_ARKSCREEN} ${_ARKBIN} ${_ARKCONFIGSTRING}
        ${_ARKBIN} "${_ARKCONFIGSTRING}"

		if [ -e "${SYS_stopfile}" ]; then
			rm "${SYS_stopfile}"
		fi
	fi
}

stopARKServer() {
	ARKInstance=$(getARKInstance)

	touch "${SYS_stopfile}"
	
	if [[ ${ARKInstance} ]]; then
		echo "Current running ARK instance: ${ARKInstance}"
		echo "Attempting to kill instance..."
		kill "$ARKInstance" && sleep 2

		# System takes a bit to actually remove the running instance
		while [[ $(getARKInstance) ]]
		do
				echo "Instance still running..."
				sleep 2
		done
    fi

	echo "Instance shut down...."
}

updateARKServer() {
	if [ ! -e "${SYS_lockfile}" ]; then
		echo "Beginning update..."
		touch "${SYS_lockfile}"

		retVal=$($STEAM_updateCmd)

		while [[ $retVal -ne 0 ]]
		do
			retVal=$($STEAM_updateCmd)
		done

		rm "${SYS_lockfile}"
	else
		echo "Update already in progress. Exiting."
	fi
}

backupLogs() {
	retVal=$(ls ${_ARKWORLDDIR}/Logs/* &> /dev/null)
	if [[ $retVal ]]; then
		zip -q ${_ARKWORLDDIR}/Logs.zip ${_ARKWORLDDIR}/Logs/*
		rm -vf ${_ARKWORLDDIR}/Logs/*
	else 
		echo "No logs present! Nothing to archive."
	fi
}

main "$@"
exit 0
