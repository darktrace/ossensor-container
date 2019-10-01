# FAQ

## How does the osSensor de-duplicate traffic when two machines with an osSensor communicate with each other?

The vSensor sends each osSensor a packet filter which excludes IPs of other osSensor registered devices to avoid duplication.

Additionally, in environments where the osSensor may encounter duplicate traffic, a blacklist and/or whitelist can be provided to exclude duplicate traffic.

### How do I know if osSensors can’t connect?

Check port 80/TCP and 443/TCP is open between the osSensor and vSensor.

The number of active osSensors can be verified on the `/status` page of the associated Darktrace master.

### How do I add a custom bpf filter?

The `bpf=` config option allows adding a filter which uses the Berkley packet filter syntax. This takes the form of `and` combined with the dynamic filter from the vSensor to make a new string which the osSensor uses

Example:

    vSensor filter: not (host 10.2.4.6 and tcp port 80) and not host 10.2.4.90

    custom filter in config: tcp port 3389 or tcp port 22

    combined filter: (not (host 10.2.4.6 and tcp port 80) and not host 10.2.4.90) and (tcp port 3389 or tcp port 22)
