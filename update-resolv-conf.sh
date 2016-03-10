#!/bin/bash -x 
#
# Parses DHCP options from openvpn to update resolv.conf
# To use set as 'up' and 'down' script in your openvpn *.conf:
# up /etc/openvpn/update-resolv-conf
# down /etc/openvpn/update-resolv-conf
#
# Used snippets of resolvconf script by Thomas Hood <jdthood@yahoo.co.uk>
# and Chris Hanson
# Licensed under the GNU GPL.  See /usr/share/common-licenses/GPL.
# 07/2013 colin@daedrum.net Fixed intet name
# 05/2006 chlauber@bnc.ch
#
# Example envs set from openvpn:
# foreign_option_1='dhcp-option DNS 193.43.27.132'
# foreign_option_2='dhcp-option DNS 193.43.27.133'
# foreign_option_3='dhcp-option DOMAIN be.bnc.ch'
# foreign_option_4='dhcp-option DOMAIN-SEARCH bnc.local'

## You might need to set the path manually here, i.e.
RESOLVCONF=/usr/bin/resolvconf
RESOLV_FILE=/etc/resolv.conf


resolvconf_up() {
  for optionname in ${!foreign_option_*} ; do
    option="${!optionname}"
    echo $option
    part1=$(echo "$option" | cut -d " " -f 1)
    if [ "$part1" == "dhcp-option" ] ; then
      part2=$(echo "$option" | cut -d " " -f 2)
      part3=$(echo "$option" | cut -d " " -f 3)
      if [ "$part2" == "DNS" ] ; then
        IF_DNS_NAMESERVERS="$IF_DNS_NAMESERVERS $part3"
      fi
      if [[ "$part2" == "DOMAIN" || "$part2" == "DOMAIN-SEARCH" ]] ; then
        IF_DNS_SEARCH="$IF_DNS_SEARCH $part3"
      fi
    fi
  done
  R=""
  if [ "$IF_DNS_SEARCH" ]; then
    R="search "
    for DS in $IF_DNS_SEARCH ; do
      R="${R} $DS"
    done
  R="${R}
"
  fi

  for NS in $IF_DNS_NAMESERVERS ; do
    R="${R}nameserver $NS
"
  done
  #echo -n "$R" | $RESOLVCONF -x -p -a "${dev}"
  echo -n "$R" | $RESOLVCONF -x -a "${dev}.inet"
}

resolvconf_down() {
  $RESOLVCONF -d "${dev}.inet"
}


vanilla_up() {
    cp /etc/resolv.conf /etc/resolv.conf-prevpn
    sed -i 's/^/#</' $RESOLV_FILE

	for opt in ${!foreign_option_*}
	do
        ip=$(echo ${!opt} | perl -ne 'm|dhcp-option\s+DNS\s+(\d+\.\d+\.\d+\.\d+)| && print "$1"' )
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
	    then
            echo nameserver $ip >> $RESOLV_FILE
	    fi
    done

}

vanilla_down() {
    cp /etc/resolv.conf-prevpn /etc/resolv.conf
#	for opt in ${!foreign_option_*}
#	do
#        ip=$(echo ${!opt} | perl -ne 'm|dhcp-option\s+DNS\s+(\d+\.\d+\.\d+\.\d+)| && print "$1"' )
#        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
#	    then
#            sed -i "s/nameserver $dns/d"  $RESOLV_FILE
#	    fi
#    done
#    sed -i 's/^#<//' $RESOLV_FILE

}

case $script_type in
up)
    if [ -x "$RESOLVCONF" ]
    then
        resolvconf_up
    else
        vanilla_up
    fi
  ;;
down)
    if [ -x "$RESOLVCONF" ]
    then
        resolvconf_down
    else
        vanilla_down
    fi
  ;;
esac
