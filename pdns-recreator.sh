#!/bin/bash
#
########
# Pdns-Recreator Ver. 0.1 for Linux 
# ---------------------------------
# Quick n Dirty Script for Converting some Pi-Hole and/or Custom Blacklists to 
# PowerDNS Recursor LUA Files and also creating HOSTS files
# Useful for Ads-Blocking
#
# Copyright 2020 - by suuhm - suuhmer@coldwareveryday.com
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
########
#
# Oneliner
# grep -vE "^#|^\W" blacklist_raw_.txt | sed 's/^/"/g;s/\r/\"\,/g' | tr -d '\n' | awk '{print "return: " $1 " }"}'
#
########

_PROG=${0##*/}
_COMMAND_MODE='none'
_BL_FILE=bl_full_row.lst
_LUA_FILE=blocklist.lua
_PDNS_DIR=/etc/powerdns/
_URL_FILE=""
_URI_PH=https://www.sunshine.it/blacklist.txt
_URI_HOSTS=https://raw.githubusercontent.com/suuhm/pdns-recreator/master/yt-adblock.lst
_OPT_DL=0

_usage()
{
    echo "Usage: $_PROG main-mode bl-options [options]>   
    main-mode:               recursor, hostsfile, pihole    
                            
    bl-options:  
    
        -b, --builtin-bl   Using the builtin Balcklist file.
        -f, --bl-file=URL  Download custom extern Blacklist-File. Needs URI-format!

    options:
    
        -C, --convert      Just Converts Blacklist to powerdns *.lua file.
        -i, --install      Setup the Blacklists (includes convert function).
        -u, --update       Updates / Installs the Blacklistfile to PDNS or HOSTS
        -r, --reset        Rsets the PDNS or HOSTS Files which are created
        
        -s, --syslog       Write messages into the system log.
        -v, --version      Prints script-version.
        -h, --help         Print this help message.
    
    " 
}

_version()
{
    echo -e "\nPdns-Recreator Ver. 0.1 for Linux"
    echo -e "Copyright 2020 - by suuhm - it@coldwareveryday.com"
    echo -e "Have fun with your Ad-free browsing and feel free to report Bugs!\n"  
}

_pdns_convert ()
{
    echo 'return{' > $_LUA_FILE
    grep -vE "^#|^\W" $_BL_FILE | sed 's/^/"/g;s/\r/\"\,/g' | head -c -1 >> $_LUA_FILE
    #tail -n1 $_LUA_FILE | tr -d '\n' >> $_LUA_FILE
    printf "\"\n}" >> $_LUA_FILE
    
##    
cat << EOF > adblock.lua
adservers=newDS()
adservers:add(dofile("${_PDNS_DIR}$_LUA_FILE"))

function preresolve(dq)
    if(not adservers:check(dq.qname) or (dq.qtype ~= pdns.A and dq.qtype ~= pdns.AAAA)) then
        return false
    end

    dq:addRecord(pdns.SOA,
        "fake."..dq.qname:toString().." fake."..dq.qname:toString().." 1 7200 900 1209600 86400",
        2)
    return true
end
EOF
##

    echo -e "[*] DONE!"  
    echo -e "\n************************************************************************************************\n"
    echo -e "Now, please set: \n1.\t lua-dns-script=${_PDNS_DIR}adblock.lua in your recursor.conf \n2.\t reload with: rec_control reload-lua-script"
    echo -e "\n************************************************************************************************\n"
    echo -e "[*] Cleaning up temp Blocklist Files...\n"
    cp -ra *.lua $_PDNS_DIR
    rm *.blist
}

_set_update()
{
    if [[ $_COMMAND_MODE == "recursor" ]]; then
        [ $_OPT_DL == 2 ] && _get_bl 1 || _get_bl 2
        _pdns_convert
    elif [[ $_COMMAND_MODE == "hosts" ]]; then
        [ $_OPT_DL == 2 ] && _get_bl 1 || _get_bl 3
        TMP=`grep -vE "0.0.0|YT-A" /etc/hosts`
        echo -e "$TMP\n" > /etc/hosts
        echo -e "\n#### HOSTS CREATED AGAINST YT-ADS <$(wc -l $_BL_FILE) ENTRIES> ####" >> /etc/hosts
        grep -vE "^#|^\W\W" $_BL_FILE | awk -F '\r' '{ print "0.0.0.0\t" $1 }' | head -c -1 >> /etc/hosts
        echo "[*] Hosts successfully updated!"
    elif [[ $_COMMAND_MODE == "pihole" ]]; then
        echo NULL
    else
        exit 222;
    fi  
}

_set_install()
{
    if [[ $_OPT_DL == 2 ]]; then 
        echo "[*] Using URL: $_OPT_DL $_URL_FILE for download" 
        _get_bl 22 
    fi
    #BL CHECK
    [ $_OPT_DL == 0 ] && echo "Not setting Blacklist. Using default $_BL_FILE ..."
    
    if [[ $_COMMAND_MODE == "recursor" ]]; then
        _pdns_convert
    elif [[ $_COMMAND_MODE == "hosts" ]]; then
        [ $_OPT_DL == 2 ] && _get_bl 1 || _get_bl 3
        TMP=`grep -vE "0.0.0|YT-A" /etc/hosts`
        echo -e "$TMP\n" > /etc/hosts
        cp -a /etc/hosts /etc/hosts.bak
        echo -e "\n#### HOSTS CREATED AGAINST YT-ADS <$(wc -l $_BL_FILE) ENTRIES> ####" >> /etc/hosts
        echo "Creating HOSTS LIST..."
        #{ print "127.0.0.1\t" $1 }
        grep -vE "^#|^\W\W" $_BL_FILE | awk -F '\r' '{ print "0.0.0.0\t" $1 }' | head -c -1 >> /etc/hosts
        echo "[*] Hosts successfully created!"
    elif [[ $_COMMAND_MODE == "pihole" ]]; then
        echo NULL
    else
        exit 223;
    fi
}

_reset_m()
{
    if [[ $_COMMAND_MODE == "recursor" ]]; then
        echo -e "Not implemented yet. \nJust comment out in recursor.conf File\n"
    elif [[ $_COMMAND_MODE == "hosts" ]]; then
        TMP=`grep -vE "0.0.0|YT-A" /etc/hosts`
        echo -e "$TMP\n" > /etc/hosts
        echo "[*] Hosts-File successfully resetted"
    elif [[ $_COMMAND_MODE == "pihole" ]]; then
        echo NULL
    else
        exit 224;
    fi  
}

_get_bl()
{
    # 2 - pihole
    # 3 - hosts<-zero
    
    if [[ -z $1 ]]; then
        _t=0
    else
        _t=$1
    fi
    
    if [[ $_t == 1 ]]; then
        echo "[*] Downloading File..."
        curl -sL `echo $_URL_FILE | cut -d "=" -f 2` > $_BL_FILE
    elif [[ $_t == 2 ]]; then
        echo "[*] Downloading File..."
        curl -sL $_URI_PH > $_BL_FILE
    elif [[ $_t == 3 ]]; then
        echo "[*] Downloading File..."
        curl -sL $_URI_HOSTS > $_BL_FILE
        sed -i 's/^0.*0//g' $_BL_FILE  
    else
        echo "[*] Downloading File..."
        curl -sL `echo $_URL_FILE | cut -d "=" -f 2` > $_BL_FILE
    fi  
}

if [[ "$#" == '0' ]]; then
    echo "Argument list empty"
    exit 110
fi

tmppt=${1%%-*}
_COMMAND_MODE="$1"
if [[ "$tmppt" != '' ]]; then
    shift 1
else
    if [[ $_COMMAND_MODE != "-h" && $_COMMAND_MODE != "-v" && $_COMMAND_MODE != "--help" && $_COMMAND_MODE != "--version" ]]; then 
        _usage ; exit 121 
    fi
fi

if [[ ! -e $_BL_FILE ]]; then
    echo "[*] WARNING NO BLACKLIST FILE FOUND!!"
    echo "[*] TRYING TO DOWNLOAD ONE..."
    _get_bl 2
fi

GETOPT=`getopt -T`
if [[ $? != 4 && $? != 1 ]]; then
    echo "Error 111: GETOPT missing"
    exit 111
fi
 
_getopt=$(getopt -o vhCbfi::usr --long version,help,convert,builtin-bl,bl-file::,update,install,reset,syslog -n $_PROG -- "$@")
if [[ $? != 0 ]] ; then 
    echo "bad command line options" >&2 ; exit 13 ; 
fi

eval set -- ${_getopt}

while true; do
        case "$1" in
                -v|--version)
                        _version; exit 0 
                        ;;
                -h|--help)
                        _usage; exit 0 
                        ;;
                -C|--convert)
                        if [[ "$_COMMAND_MODE" == "recursor" ]]; then
                            _pdns_convert; break
                        else
                            echo -e "Only in Recursor mode!\n" 
                            exit 117;
                        fi
                        ;;
                -b|--builtin-bl)
                        if [[ -z "$2" ]]; then
                            _OPT_DL=1
                            shift; 
                        else
                            _usage 
                            exit 116;
                        fi 
                        continue
                        ;;
                -f|--bl-file)
                        if [[ -z "$2" ]]; then
                            echo -e "Missing URL!\n" ; _usage
                            exit 116;
                        else
                            _OPT_DL=2 ; _URL_FILE=$2
                            shift 2;
                        fi
                        continue 
                        ;;
                -u|--update)
                        _set_update; shift; continue  
                        ;;
                -i|--install)
                        #[ $_OPT_DL -gt 0 || "$2" == '' ] && 
                        _set_install; shift; continue 
                        ;;
                -r|--reset)
                      _reset_m; break  
                        ;;
                -s|--syslog)
                        _syslog #TODO 
                        break 
                        ;;
                --)
                        shift; break 
                        ;;
                *)
                        echo "BAD OPTION $1"
                        _usage
                        exit 123
                        ;;
        esac
done
 
exit 0;
