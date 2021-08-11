#!/bin/bash

# Set Debug from level 0 (info level logging) to 5 (full packet data dumped)
# 5 = Print all packet contents as hex (very verbose!)
# 4 = Print summary of each chunk of packets (time and size)
# 3 = Antigena info
# 2 = Print info such as sending (number / size) or not sending, and the response. Sent packets stat will work in this level
# 1 = Packet capture stats & Antigena stats
# 0 = Basic info

# Backwards compatibility
NETWORK_DEVICE_INCLUDELIST=${NETWORK_DEVICE_INCLUDELIST:-$NETWORK_DEVICE_WHITELIST}
NETWORK_DEVICE_EXCLUDELIST=${NETWORK_DEVICE_EXCLUDELIST:-$NETWORK_DEVICE_BLACKLIST}

Debug=${OSSENSOR_DEBUG:-1}

# The host and port of the vSensor instance
vSensor=${VSENSOR_HOSTNAME:?"VSENSOR_HOSTNAME not set."}:${VSENSOR_PORT:-443}

# Check if hostname contains a colon
if [[ $VSENSOR_HOSTNAME =~ .*:.* ]]; then
  echo "VSENSOR_HOSTNAME should not contain a ':'."
  echo "If you wish to set a port use the VSENSOR_PORT environment variable."
  exit 1
fi

# HMAC key for use with the vsensor
key=${VSENSOR_HMAC_KEY:?"VSENSOR_HMAC_KEY not set."}

# Boolean value to enable Antigena capabilities
ANTIGENA_ENABLED=${ANTIGENA_ENABLED:-true}

# Time period in seconds between sending Antigena actions to the vSensor
ANTIGENA_TIME_PERIOD=${ANTIGENA_TIME_PERIOD:-5}

# Devices to capture from

# Initialise outputdevices to ALL devices
alldevices=`cat /proc/net/dev | grep : | cut -d : -f 1 | tr -d '[:blank:]'`
outputdevices=${alldevices}


# Get rid of loopback device
outputdevices=`echo "$outputdevices" | grep -wv "lo"`

#Generating explicit blacklist
BLACKLIST=
# whitespace separated list of network interfaces to ignore
if [ -z "$NETWORK_DEVICE_EXCLUDELIST" ]
then
  echo Network excludelist is blank
else
  echo Network excludelist: $NETWORK_DEVICE_EXCLUDELIST
  # remove excludelist entries
  for excludelist_entry in `echo $NETWORK_DEVICE_EXCLUDELIST`; do
    outputdevices=`echo "$outputdevices" | egrep -v "$excludelist_entry"`
    echo $excludelist_entry
  done
  echo "Generating blacklist:"
  for excludelist_entry in `echo $NETWORK_DEVICE_EXCLUDELIST`; do
    BLACKLIST="$BLACKLIST"`echo "$alldevices" | egrep "$excludelist_entry"`$'\n'
  done
  BLACKLIST=`echo "$BLACKLIST" | sort | uniq | awk NF | paste -s -d ','`
fi

# whitespace separated list of network interfaces to include
if [ -z "$NETWORK_DEVICE_INCLUDELIST" ]
then
  echo Network includelist is blank
  devices=`echo "$outputdevices" | sort | uniq | awk NF | paste -s -d ','`
else
  echo Network includelist: $NETWORK_DEVICE_INCLUDELIST
  finaldevices=
  # keep includelist entries
  for includelist_entry in $NETWORK_DEVICE_INCLUDELIST; do
    finaldevices="$finaldevices"`echo "$outputdevices" | egrep "$includelist_entry"`$'\n'
  done
  finaldevices=`echo "$finaldevices" | sort | uniq | awk NF | paste -s -d ','`
  devices="$finaldevices"
  echo "$devices"
fi

devices="$devices"

# Check that devices were set properly
if [ -z "$devices" ]
then
  echo "Failed to configure devices, doublecheck network interfaces excludelist and includelist"
  exit 1
fi

# Check to see if should attach to 'any' new device

if [ "$NETWORK_DEVICE_ANY" = "1" ]; then
  devices="$devices,any"
  echo "listening to newly created devices"
else
  echo "listening to listed devices only"
fi

echo "Listening on: " "$devices"

# Check if a BPF was provided
if [ -z "$BPF" ]
then
  echo "No BPF found from config"
fi

# File to send logs to
logfile=${OSSENSOR_LOGFILE_PATH:-/dev/stdout}

# File to create config, osSensor expects
# /etc/darktrace/ossensor.cfg by default
config_file=${OSSENSOR_CONFIG_PATH:-/etc/darktrace/ossensor.cfg}

# Now generate the config file

cat <<-EOL > "$config_file"
[osSensor]
Debug=$Debug
vSensor=$vSensor
key=$key
device=$devices
logfile=$logfile
useAntigena=$ANTIGENA_ENABLED
useWebsocket=$ANTIGENA_ENABLED
sendAntigenaActionDelta=$ANTIGENA_TIME_PERIOD
blacklist_device=$BLACKLIST
bpf=${BPF}
EOL

# Usage: osSensor -c /path/to/ossensor.cfg
exec /usr/bin/osSensor -c "$config_file"
