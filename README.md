# pdns-recreator
Quick n Dirty Script for Converting some Pi-Hole and/or Custom Blacklists to PowerDNS Recursor LUA Files and also creating HOSTS files. Useful for Ads-Blocking

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

# Features

- Converting Pi-Hole and/or some other Blacklists in the WWW to the PowerDNS Recursor Lua Script Format. See here for more infos: https://blog.powerdns.com/2016/01/19/efficient-optional-filtering-of-domains-in-recursor-4-0-0/
- This scripts makes it more comfortable to handle this above without installing addition sotfware etc.
- Install / Update Function, to keep up to date your blacklists
- You can use you own Blacklist, found on the web
- Additional you can manage your /etc/hosts file
- Update / Install / Reset Hosts-File

# How to use the script
- First, you need a full install of Power DNS Recursor
```
apt install pdns-recursor pdns-backend-lua pdns-tools
```

- Now we are using the default dir /opt/ for cloning and installing the script
```
git clone https://github.com/suuhm/pdns-recreator /opt/pdns-recreator

chmod +x /opt/pdns-recreator/pdns-recreator.sh && ln -s /opt/pdns-recreator/pdns-recreator.sh /usr/bin/
```

# Options 
```
Usage: $_PROG main-mode bl-options [options]>   
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
```

# Examples
- Installing Pdns-lua scripts, with builtin Blacklist
```
pdns-recreator.sh recursor --builtin-bl --install
```

- Installing Pdns-lua scripts, with custom Blacklist
```
pdns-recreator.sh recursor --bl-file=https://www.pihole-something.com/blacklist.list --install
```

- Updating Hosts-File with custom Blacklist
```
pdns-recreator.sh hosts --bl-file=https://www.sunshine.it/blacklist.txt --update
```

# Report Bugs!
This Version is a pure alpha version!
When you find bugs, please let me know.

Thanks.
