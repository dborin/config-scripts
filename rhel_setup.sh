#!/bin/bash

usage() {
  echo -e "\nUsage: $0 [-i IP address] [-n hostname] [-u username]\n" 1>&2
  echo -e "    -i    Static IP address of the machine [REQUIRED]"
  echo -e "    -n    Hostname of the machine [REQUIRED]"
  echo -e "    -u    Username for autologin (default: cliosoft) [OPTIONAL]"
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

    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [[ -z $opt_i ]] || [[ -z $opt_n ]];then
  usage
elif [[ -z $(echo $opt_i | grep -E "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$") ]];then
  echo -e "\nYour IP address $opt_i looks malformed\n"
  usage
fi

if [[ -z $opt_u ]];then
  opt_u="cliosoft"
fi

if [[ -z $(grep AutomaticLoginEnable /etc/gdm/custom.conf) ]];then
  sudo sed -i.orig "s/\(\[daemon\]\)/\1\nAutomaticLoginEnable=true\nAutomaticLogin=$opt_u\n/" /etc/gdm/custom.conf
  echo ''
  cat /etc/gdm/custom.conf
  echo ''
else
  echo -e "\nNothing was changed in /etc/gdm/custom.conf (auto login already enabled?)\n"
fi


if [[ -z $(grep "HOSTNAME=$opt_n" /etc/sysconfig/network) ]];then
  sudo sed -i.orig -e "s/HOSTNAME=.*/HOSTNAME=$opt_n/" /etc/sysconfig/network
  echo ''
  cat /etc/sysconfig/network
  echo ''
else
  echo -e "\nNothing wa changed in /etc/sysconfig/network (hostname already set?)\n"
fi

MYGATEWAY=`echo $opt_i | sed 's/\(^[0-9]*\.[0-9]*\.[0-9]*\.\).*/\11/'`
if [[ -z $(grep "BOOTPROTO=STATIC" /etc/sysconfig/network-scripts/ifcfg-eth0) ]];then
  sudo sed -i.orig -e "s/BOOTPROTO.*/BOOTPROTO=STATIC/" /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "IPADDR=$opt_i" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "GATEWAY=$MYGATEWAY" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "DNS1=8.8.8.8" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  sudo echo -e "DNS2=8.8.4.4" >> /etc/sysconfig/network-scripts/ifcfg-eth0

  echo -e ''
  cat /etc/sysconfig/network-scripts/ifcfg-eth0
  echo -e ''

  sudo /etc/init.d/network stop
  sudo /etc/init.d/network start 
else
  echo -e "\nNothing was changed in /etc/sysconfig/network-scripts/ifcfg-eth0 (static IP already set?)\n"
fi
