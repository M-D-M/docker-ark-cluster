#!/bin/bash

_ARKBINLOC="/ARK"
_ARKBIN=${_ARKBINLOC}/ShooterGame/Binaries/Linux/ShooterGameServer
_ARKCONFIGSTRING="${__ARKMAP}?SessionName=${__ARKINSTANCE}?Port=${__ARKPORT}?QueryPort=${__ARKQPORT}?AltSaveDirectoryName=${__ARKINSTANCE}?OverrideStructurePlatformPrevention=True -NoTransferFromFiltering -servergamelog -server -log -clusterid=${__ARKCLUSTER}"
_ARKBACKUPDIR="/ARK_BACKUP"
# _ARKSCREEN="${__ARKINSTANCE}-screen"
_ARKWORLDDIR="/ARK/ShooterGame/Saved"

STEAM_bin=/home/steam/steamcmd
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
			backupARKServer &
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
	echo "Backing up server files in background..."
	zip -qr "/tmp/${__ARKINSTANCE}_Saved.zip" ${_ARKWORLDDIR}/

	echo "Copying files to remote backup..."
	#rclone -q sync /tmp/${__ARKINSTANCE}_Saved.zip ${_ARKBACKUPDIR}
	rsync -a "/tmp/${__ARKINSTANCE}_Saved.zip" ${_ARKBACKUPDIR}/

	echo "Removing backup file..."
	rm "/tmp/${__ARKINSTANCE}_Saved.zip"
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

		# Backup logs
		# backupLogsForWorld
        fi

	echo "Instance shut down...."
}

updateARKServer() {
	if [ ! -e "${SYS_lockfile}" ]; then
		touch "${SYS_lockfile}"

		$STEAM_updateCmd

		while [ $? -ne 0 ]
		do
			$STEAM_updateCmd
		done

		rm "${SYS_lockfile}"
	else
		echo "Update already in progress. Exiting."
	fi
}

backupLogsForWorld() {
	if [ -r ${_ARKWORLDDIR}/Logs ]; then
		zip -q ${_ARKWORLDDIR}/Logs.zip ${_ARKWORLDDIR}/Logs/*
		rm ${_ARKWORLDDIR}/Logs/*
	fi
}

main "$@"
exit 0
