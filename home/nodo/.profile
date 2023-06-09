# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

. common.sh
# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

export PATH=$PATH:/home/nodo/

#Reset SDCard filesystem size
BOOT_STATUS=$(getvar "boot_status")

if [ "$BOOT_STATUS" -eq -1 ] ; then
echo -e "\e[32mPiNodeXMR detects this is first boot - attempting to expand filesystem\e[0m"
sudo systemctl start armbian-resize-filesystem
echo -e "\e[32mComplete\e[0m"
putvar "boot_status" "0"
fi
