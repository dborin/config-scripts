#!/bin/bash

# Last-modified: Fri Aug 05, 2016 08:54:37 PDT

# Written by David Borin borin8765 at gee mail dot com
# The script is provided "as-is".  USE AT YOUR OWN RISK.  The author takes no/zero/nada/zilch responsibility
# if the script totally hoses your Linux machine.  Works for me, YMMV!

# Sets up RHEL / CentOS for autologin (defaults to user "cliosoft" since I wrote this while working there).
# Configures for static IP from default DHCP, and adds Google DNS servers by default.
# Configures correct hostname for machine.
#
# This will NOT work on Debian / Ubuntu

usage() {
  echo -e "\nUsage: $0 [-i IP address] [-n hostname] [-u username] [-1 DNS IP address] [-2 DNS IP address]\n" 1>&2
  echo -e "    -i    Static IP address of the machine [REQUIRED]"
  echo -e "    -n    Hostname of the machine [OPTIONAL]"
  echo -e "    -u    Username for autologin (default: cliosoft) [OPTIONAL]"
  echo -e "    -1    Set DNS server 1 (default: 8.8.8.8) [OPTIONAL]"
  echo -e "    -2    Set DNS server 2 (default: 8.8.4.4) [OPTIONAL]"
  echo -e "\n"
  exit 1
}


while getopts ":i:n:u:" o; do
  case "${o}" in
    i)
      opt_i=${OPTARG}
      ;;

    n)
      opt_n=${OPTARG}
      ;;

    u)
      opt_u=${OPTARG}
      ;;

    1)
      opt_1=${OPTARG}
      ;;

    2)
      opt_2=${OPTARG}
      ;;

    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [[ -z $opt_i ]]; then
  usage
elif [[ -z $(echo $opt_i | grep -E "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$") ]]; then
  echo -e "\nYour IP address $opt_i looks malformed\n"
  usage
fi

if [[ -z $opt_u ]]; then
  opt_u="cliosoft"
fi

if [[ -z $opt_1 ]]; then
  opt_1="8.8.8.8"
fi

if [[ -z $opt_2 ]]; then
  opt_2="8.8.4.4"
fi

if [[ -z $(grep AutomaticLoginEnable /etc/gdm/custom.conf) ]];then
  sudo sed -i.orig "s/\(\[daemon\]\)/\1\nAutomaticLoginEnable=true\nAutomaticLogin=$opt_u\n/" /etc/gdm/custom.conf
  echo ''
  cat /etc/gdm/custom.conf
  echo ''
else
  echo -e "\nNothing was changed in /etc/gdm/custom.conf (auto login already enabled?)\n"
fi


if [[ -n $opt_n ]];then
  sudo sed -i.orig -e "s/HOSTNAME=.*/HOSTNAME=$opt_n/" /etc/sysconfig/network
  echo ''
  cat /etc/sysconfig/network
  echo ''
fi

# Set the gateway using the supplied IP: xxx.xxx.xxx.1
# To change it, modify the regex below (probably change the very last "1" to your preferred gateway)

MYGATEWAY=`echo $opt_i | sed 's/\(^[0-9]*\.[0-9]*\.[0-9]*\.\).*/\11/'`

if [[ -z $(grep "BOOTPROTO=STATIC" /etc/sysconfig/network-scripts/ifcfg-eth0) ]];then
  sudo sed -i.orig -e "s/BOOTPROTO.*/BOOTPROTO=STATIC/" /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "IPADDR=$opt_i" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "GATEWAY=$MYGATEWAY" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "DNS1=$opt_1" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "DNS2=$opt_2" >> /etc/sysconfig/network-scripts/ifcfg-eth0

  echo -e ''
  cat /etc/sysconfig/network-scripts/ifcfg-eth0
  echo -e ''

  sudo /etc/init.d/network stop
  sudo /etc/init.d/network start
else
  echo -e "\nNothing was changed in /etc/sysconfig/network-scripts/ifcfg-eth0 (static IP already set?)\n"
fi

echo -e "\nYou may need to restart the machine for all changes to take effect.  YMMV!\n"
