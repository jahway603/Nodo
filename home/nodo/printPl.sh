#!/bin/sh

#shellcheck source=home/nodo/common.sh
. /home/nodo/common.sh

# use temp file
_temp="./dialog.$$"

# Key - Boot_STATUS
# 2 = idle
# 3 = Private node
# 4 = tor
# 5 = Public RPC pay
# 6 = Public free
# 7 = I2P
#Notes on how this works:
#1)Each status command is set as a variable and then on completion this variable is then returned into the file specified...
#The variable step is needed to prevent the previous stats file being overwritten to empty at the start of the command before the new stats are generated thus causing blank stats sections in the UI.
#2)I spent far too much time trying to incorporate 'target height' into the main status section, however this would often sit below the current height once sync'd...
#So next I used 'Current_Sync_Progress:((.result.height/.result.target_height)*100)|floor' to readout a percentage of sync'd rounded down to a whole number. This meant that when the current height was above target sync status read as 100%...
#However in tor mode target height sometimes outputs to 0 and the math fails killing the whole command. In the end the boolean 'Busy_Syncing:.result.busy_syncing' is used but not as pretty.

DEVICE_IP=$(getip)
#Load boot status - what condition was node last run
BOOT_STATUS=$(getvar "boot_status")
#Import Restricted Port Number (external use)
MONERO_PORT=$(getvar "monero_port")
#Import unrestriced port number when running public node for internal use only
MONERO_PUBLIC_PORT=$(getvar "monero_public_port")
#Import RPC username
RPCu=$(getvar "rpcu")
#Import RPC password
RPCp=$(getvar "rpcp")


#Define status functions

	#printFullPeers
BOOT_STATUS=$(getvar "boot_status")

	if [ "$BOOT_STATUS" -eq 2 ]
then
		#System Idle
		echo "-- System Idle --" > /var/www/html/print_pl.txt
fi

	if [ "$BOOT_STATUS" -eq 3 ] || [ "$BOOT_STATUS" -eq 5 ]
then
		#Node Status
			PRINT_PL="$(./monero/build/release/bin/monerod --rpc-bind-ip="${DEVICE_IP}" --rpc-bind-port="${MONERO_PORT}" --rpc-login="${RPCu}:${RPCp}" --rpc-ssl disabled print_pl | sed '1d' | sed 's/\x1b\[[0-9;]*m//g')" && echo "$PRINT_PL" > /var/www/html/print_pl.txt;
			date >> /var/www/html/print_pl.txt
fi

	if [ "$BOOT_STATUS" -eq 4 ]
then
#Adapted command for tor rpc calls (payments) - RPC port and IP fixed due to tor hidden service settings linked in /etc/tor/torrc
			PRINT_PL="$(./monero/build/release/bin/monerod --rpc-bind-ip="${DEVICE_IP}" --rpc-bind-port=18081 --rpc-login="${RPCu}:${RPCp}" --rpc-ssl disabled print_pl | sed '1d' | sed 's/\x1b\[[0-9;]*m//g')" && echo "$PRINT_PL" > /var/www/html/print_pl.txt;
			date >> /var/www/html/print_pl.txt
fi

	if [ "$BOOT_STATUS" -eq 5 ]
then
		#Adapted command for restricted public rpc calls (payments)
			PRINT_PL="$(./monero/build/release/bin/monerod --rpc-bind-ip="$DEVICE_IP" --rpc-bind-port="$MONERO_PORT" --rpc-ssl disabled print_pl | sed '1d' | sed 's/\x1b\[[0-9;]*m//g')" && echo "$PRINT_PL" > /var/www/html/print_pl.txt;
			date >> /var/www/html/print_pl.txt
fi

	if [ "$BOOT_STATUS" -eq 6 ]
then
		#Adapted command for public free (restricted) rpc calls. No auth needed for local.
			PRINT_PL="$(./monero/build/release/bin/monerod --rpc-bind-ip="$DEVICE_IP" --rpc-bind-port="$MONERO_PUBLIC_PORT" --rpc-ssl disabled print_pl | sed '1d' | sed 's/\x1b\[[0-9;]*m//g')" && echo "$PRINT_PL" > /var/www/html/print_pl.txt;
			date >> /var/www/html/print_pl.txt
fi
	if [ "$BOOT_STATUS" -eq 7 ]
then
		#Node Status
			PRINT_PL="$(./monero/build/release/bin/monerod --rpc-bind-ip="$DEVICE_IP" --rpc-bind-port="$MONERO_PORT" --rpc-login="${RPCu}:${RPCp}" --rpc-ssl disabled print_pl | sed '1d' | sed 's/\x1b\[[0-9;]*m//g')" && echo "$PRINT_PL" > /var/www/html/print_pl.txt;
			date >> /var/www/html/print_pl.txt
fi

	if [ "$BOOT_STATUS" -eq 8 ]
then
#Adapted command for tor rpc calls (payments) - RPC port and IP fixed due to tor hidden service settings linked in /etc/tor/torrc
			echo "It is not currently possible to retrieve connected peer information when running a public tor node." > /var/www/html/print_pl.txt
fi
