#!/bin/bash
#(1) Define variables and updater functions
#shellcheck source=home/nodo/common.sh
. /home/nodo/common.sh
NEW_VERSION_LWS="${1:-$(getvar "versions.lws")}"

#Error Log:
touch "$DEBUG_LOG"
showtext "
####################
Start setup-update-monero-lws.sh script $(date)
####################
"

##Delete old version
showtext "Delete old version"
rm -rf /home/nodo/monero-lws 2>&1 | tee -a "$DEBUG_LOG"
showtext "Downloading VTNerd Monero-LWS"
{
	git clone --recursive https://github.com/vtnerd/monero-lws.git
	cd monero-lws || exit 1
	git checkout release-v0.2_0.18
	git pull
	mkdir build
	cd build || exit 1
	cmake -DMONERO_SOURCE_DIR=/home/nodo/monero -DMONERO_BUILD_DIR=/home/nodo/monero/build/release ..
	showtext "Building VTNerd Monero-LW"
	make
} 2>&1 | tee -a "$DEBUG_LOG"
cd || exit 1
#Update system reference current LWS version number to New version number
putvar "versions.lws" "$NEW_VERSION_LWS"

##End debug log
showtext "Monero-LWS Updated
####################
End setup-update-monero-lws.sh script $(date)
####################"
