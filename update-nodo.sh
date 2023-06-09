#!/bin/bash
#Create/ammend debug file for handling update errors:
#shellcheck source=home/nodo/common.sh
. /home/nodo/common.sh
cd /root/moneronodo || exit 1
OLD_VERSION_PI="${1:-$(getvar "versions.pi")}"
touch "$DEBUG_LOG"
echo "
####################
Start update-nodo.sh script $(date)
####################
" | tee -a "$DEBUG_LOG"

#RELEASE="$(curl -s https://raw.githubusercontent.com/monero-ecosystem/MoneroNodo/master/release.txt)"
RELEASE="alpha" # TODO remove when live

if [ "$RELEASE" == "$OLD_VERSION_PI" ]; then
	showtext "No update for Nodo"
	exit 0
fi

git pull

HTMLPASSWORDREQUIRED=$(getvar "htmlpasswordrequired")
log "HTML Password Required set to: $HTMLPASSWORDREQUIRED"

##Update and Upgrade systemhtac
showtext "Receiving and applying Ubuntu updates to the latest version..."
{
	apt-get update
	apt-get --yes upgrade
	apt-get --yes dist-upgrade
	apt-get autoremove -y
} 2>&1 | tee -a "$DEBUG_LOG"

##Auto remove any obsolete packages

##Installing dependencies for Web Interface
showtext "Installing dependencies for Web Interface..."
apt-get install apache2 shellinabox php php-common avahi-daemon -y 2>&1 | tee -a "$DEBUG_LOG"

##Installing dependencies for Monero
showtext "Installing dependencies for Monero..."
apt-get update && sudo apt-get install build-essential cmake pkg-config libssl-dev libzmq3-dev libunbound-dev libsodium-dev libunwind8-dev liblzma-dev libreadline6-dev libldns-dev libexpat1-dev libpgm-dev qttools5-dev-tools libhidapi-dev libusb-1.0-0-dev libprotobuf-dev protobuf-compiler libudev-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev libboost-system-dev libboost-thread-dev ccache doxygen graphviz -y 2>&1 | tee -a "$DEBUG_LOG"

##Checking all dependencies are installed for miscellaneous (security tools-fail2ban-ufw, menu tool-dialog, screen, mariadb)
showtext "Checking all other dependencies are installed..."
apt-get install git mariadb-client mariadb-server screen fail2ban ufw dialog jq libcurl4-openssl-dev libpthread-stubs0-dev exfat-fuse -y 2>&1 | tee -a "$DEBUG_LOG"
#Download update files

##Replace file /etc/sudoers to set global sudo permissions/rules (required to add  new permissions to www-data user for interface buttons)
showtext "Downloading and replacing /etc/sudoers file..."
wget https://raw.githubusercontent.com/monero-ecosystem/Nodo/ubuntuServer-20.04/etc/sudoers -O /home/nodo/sudoers
chmod 0440 /home/nodo/sudoers
chown root /home/nodo/sudoers
mv /home/nodo/sudoers /etc/sudoers

#ubuntu /dev/null odd requirment to set permissions
chmod 777 /dev/null
showtext "Global permissions changed"

##Clone Nodo to device from git
showtext "Cloneing Nodo to device from git..."
# Update Link
#FIXME change to real git url once done
git clone -b no-sleep --single-branch https://github.com/abdullahdostkhan/Moneronodo.git

#Backup User values
showtext "Creating backups of any settings you have customised
*****
If a setting did not exist on your previous version you may see some errors here for missing files, these can safely be ignored
*****"
#home dir
mv /home/nodo/config.json /home/nodo/config_retain.json
#variables dir
showtext "User configuration saved"
#Install Update
showtext "Installing update..."
##Add Nodo systemd services
showtext "Adding Nodo systemd services..."
{
	mv /home/nodo/Nodo/etc/systemd/system/*.service /etc/systemd/system/
	chmod 644 /etc/systemd/system/*.service
	chown root /etc/systemd/system/*.service
	systemctl daemon-reload
	systemctl start moneroStatus.service
	systemctl enable moneroStatus.service
} 2>&1 | tee -a "$DEBUG_LOG"
showtext "Success"

##Updating Nodo scripts in home directory
showtext "Updating Nodo scripts in home directory..."
{
	cp -afr /home/nodo/Nodo/home/nodo/* /home/nodo/
	mv /home/nodo/Nodo/home/nodo/.profile /home/nodo/
	chmod -R 777 /home/nodo/*
} 2>&1 | tee -a "$DEBUG_LOG"
showtext "Success"

#Configure apache server for access to monero log file
showtext "Configuring apache server for access to Monero log file..."
{
	mv /home/nodo/Nodo/etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf
	chmod 777 /etc/apache2/sites-enabled/000-default.conf
	chown root /etc/apache2/sites-enabled/000-default.conf
	/etc/init.d/apache2 restart
} 2>&1 | tee -a "$DEBUG_LOG"

showtext "Success"
##Setup local hostname
showtext "Enabling local hostname nodo.local..."
mv /home/nodo/Nodo/etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf 2>&1 | tee -a "$DEBUG_LOG"
/etc/init.d/avahi-daemon restart 2>&1 | tee -a "$DEBUG_LOG"
showtext "Success"

##Update html template
showtext "Configuring Web-UI..."
#First move hidden file specifically .htaccess file then entire directory
mv /home/nodo/Nodo/HTML/.htaccess /var/www/html/ 2>&1 | tee -a "$DEBUG_LOG"
rm -R /var/www/html/*.php
#Preserve user variables (custom ports, hidden service onion address, miningrpc pay address etc). Updater script overwrites/merges all files, this renames them temporarily to avoid merge.
mv /var/www/html/credits.txt /var/www/html/credits_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/difficulty.txt /var/www/html/difficulty_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/i2p-address.txt /var/www/html/i2p-address_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/i2p-port.txt /var/www/html/i2p-port_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/i2p-tx-proxy-port.txt /var/www/html/i2p-tx-proxy-port_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/mining_address.txt /var/www/html/mining_address_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/mining_intensity.txt /var/www/html/mining_intensity_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/monero-free-public-port.txt /var/www/html/monero-free-public-port_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/monero-port-rpc-pay.txt /var/www/html/monero-port-rpc-pay_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/monero-rpc-port.txt /var/www/html/monero-rpc-port_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/onion-address.txt /var/www/html/onion-address_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/payment-address.txt /var/www/html/payment-address_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/user-set-custom.txt /var/www/html/user-set-custom_retain.txt 2> >(tee -a "$DEBUG_LOG" >&2)
#Overwrite /var/www/html with updated contents
rsync -a /home/nodo/Nodo/HTML/* /var/www/html/ 2>&1 | tee -a "$DEBUG_LOG"
chown www-data -R /var/www/html/ 2>&1 | tee -a "$DEBUG_LOG"
chmod 777 -R /var/www/html/ 2>&1 | tee -a "$DEBUG_LOG"
#Restore User variables
mv /var/www/html/credits_retain.txt /var/www/html/credits.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/difficulty_retain.txt /var/www/html/difficulty.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/i2p-address_retain.txt /var/www/html/i2p-address.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/i2p-port_retain.txt /var/www/html/i2p-port.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/i2p-tx-proxy-port_retain.txt /var/www/html/i2p-tx-proxy-port.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/mining_address_retain.txt /var/www/html/mining_address.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/mining_intensity_retain.txt /var/www/html/mining_intensity.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/monero-free-public-port_retain.txt /var/www/html/monero-free-public-port.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/monero-port-rpc-pay_retain.txt /var/www/html/monero-port-rpc-pay.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/monero-rpc-port_retain.txt /var/www/html/monero-rpc-port.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/onion-address_retain.txt /var/www/html/onion-address.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/payment-address_retain.txt /var/www/html/payment-address.txt 2> >(tee -a "$DEBUG_LOG" >&2)
mv /var/www/html/user-set-custom_retain.txt /var/www/html/user-set-custom.txt 2> >(tee -a "$DEBUG_LOG" >&2)
#Full-mode html update complete

#Set correct config for if HTML (Web UI) Password is required.

if [ "$HTMLPASSWORDREQUIRED" = TRUE ]
then
	cp /home/nodo/variables/000-default-passwordAuthEnabled.conf /etc/apache2/sites-enabled/000-default.conf
	chown root /etc/apache2/sites-enabled/000-default.conf
	chmod 777 /etc/apache2/sites-enabled/000-default.conf
	systemctl restart apache2
fi

showtext "Success"

#Restore User Values
showtext "Restoring your personal settings..."
#home dir
mv /home/nodo/variables/config_retain.json /home/nodo/variables/config.json

showtext "User configuration restored"

##Set Swappiness lower
showtext "Decreasing swappiness..."
sysctl vm.swappiness=10 2> >(tee -a "$DEBUG_LOG" >&2)
showtext "Success"
##Update crontab
showtext "Updating crontab tasks..."
crontab /home/nodo/Nodo/var/spool/cron/crontabs/nodo 2> >(tee -a "$DEBUG_LOG" >&2)
showtext "Success"

#Attempt update of tor hidden service settings
{
	if [ -f /usr/bin/tor ]; then #Crude way of detecting tor installed
		showtext "Updating tor hidden service settings..."
		wget https://raw.githubusercontent.com/monero-ecosystem/Nodo/ubuntuServer-20.04/etc/tor/torrc -O /etc/tor/torrc
		showtext "Applying Settings..."
		chmod 644 /etc/tor/torrc
		chown root /etc/tor/torrc
		#Insert user specific local IP for correct hiddenservice redirect (line 73 overwrite)
		sed -i "73s/.*/HiddenServicePort 18081 $(hostname -I | awk '{print $1}'):18081/" /etc/tor/torrc
		showtext "Restarting tor service..."
		service tor restart
	fi
} 2>&1 | tee -a "$DEBUG_LOG"

#Restart statusOutputs script service for changes to take effect
systemctl restart moneroStatus.service


#Update system version number to new one installed
{
	showtext "Updating system version number..."
	putvar "versions.pi" "$RELEASE"
	#ubuntu /dev/null odd requiremnt to set permissions
	chmod 777 /dev/null
} 2>&1 | tee -a "$DEBUG_LOG"

#Clean up files
showtext "Cleaning leftover directories..."

rm -r "/home/nodo/Nodo/"
rm "/home/nodo/new-ver-pi.sh"
showtext "Success"

##End debug log
showtext "
####################
End update-nodo.sh script $(date)
####################
"
