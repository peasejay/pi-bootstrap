if [ $(id -u) -ne 0 ]; then
  printf "Script must be run as root. Exiting..."
  echo
  echo
  exit 1
fi


WIFI_CONFIG=/etc/wpa_supplicant/wpa_supplicant.conf
HOSTS_CONFIG=/etc/hosts
LOCALE_CONFIG=/etc/locale.gen
KB_LOCALE_CONFIG=/etc/default/keyboard


. ./config.dat
if [ -e ./localconfig.dat ]; then
  . ./localconfig.dat
fi


if grep -q "$WIFI_SSID" $WIFI_CONFIG ; then
  echo "Found $WIFI_SSID... skipping wifi setup"
  echo
else
  echo "Could not find network $WIFI_SSID... adding it"
  echo
  cat <<WIFI >> $WIFI_CONFIG 

network={
   ssid="$WIFI_SSID"
   psk="$WIFI_PSK"
}
WIFI
  
  echo "Restarting wifi..."
  sleep 5
  ifdown wlan0
  sleep 5
  ifup wlan0
  sleep 5
  echo "Giving system a bit more time to resolve DNS..."
  sleep 20
  echo
fi

echo "Current wifi status:"
iwconfig
echo

echo "Updating system software components..."
apt-get update
apt-get upgrade -y
echo

echo "Installing essential software components..."
apt-get install -y vim git

echo "Updating system locales..."
# deactivate pi defaults 
sed -i "s/^\(en_GB.UTF-8.*\)/# \1/" $LOCALE_CONFIG
# activate preferred defaults
sed -i "s/^# \($LOCALE.*\)/\1/" $LOCALE_CONFIG
locale-gen
echo

echo "Updating keyboard locales..."
sed -i "s/^XKBLAYOUT.*/XKBLAYOUT=\"$KB_LOCALE\"/" $KB_LOCALE_CONFIG
invoke-rc.d keyboard-setup start
udevadm trigger --subsystem-match=input --action=change
echo

echo "Updating hostname..."
echo $HOSTNAME > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/g" $HOSTS_CONFIG
echo


echo "Setting up git configurations"
sudo -H -u pi bash -c 'git config --global user.name "$GIT_NAME"'
sudo -H -u pi bash -c 'git config --global user.email "$GIT_EMAIL"'
sudo -H -u pi bash -c 'git config --global push.default $GIT_PUSH_DEFAULT'
echo

echo "Configurations complete."
echo "You may need to restart for some options to take effect."
echo
echo "Please have a nice day."
echo
