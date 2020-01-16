# Deploying the osSensor on Kubernetes

  * README.md  -- Installation guide
  * ossensor-daemonset.yaml -- YAML file with an example osSensor Daemonset

## Deploying the osSensors

The following steps outline the configuration process in an environment with an existing Kubernetes cluster, controllable via the commandline utility `kubectl`. The osSensor container is compatible with other cluster management tools.

The best way to deploy osSensors to your Kubernetes cluster is via a _Daemonset_; this will ensure there is an osSensor on each node of your cluster. An example YAML file is provided below.

+ Please Note: `podspec` should have `hostNetwork` set to true.

+ The latest stable release of the Darktrace osSensor will always be tagged with  `:latest`. Additionally we tag the osSensor with semantic versioning `ossensor:MAJOR.MINOR.PATCH` and `ossensor:MAJOR`.

1. The osSensor is available on Docker Hub at https://hub.docker.com/r/darktrace/ossensor.

    First create a _daemonset_ to apply to the cluster using the example YAML file.

    **Example YAML File**:
*ossensor-daemonset.yaml*
    ```
      apiVersion: apps/v1
      kind: DaemonSet
      metadata:
        name: ossensor
      spec:
        selector:
          matchLabels:
            name: ossensor
        template:
          metadata:
            labels:
              name: ossensor
          spec:
            hostNetwork: true
            containers:
            - name: ossensor
              image: darktrace/ossensor:latest
              env:
              - name: VSENSOR_HOSTNAME
                value: "192.168.0.1"
              - name: VSENSOR_HMAC_KEY
                value: "js84ld9vm3hff"
              - name: OSSENSOR_DEBUG
                value: "2"
              - name: ANTIGENA_ENABLED
                value: "false"
              - name: NETWORK_DEVICE_BLACKLIST
                value: "^veth"
              - name: NETWORK_DEVICE_WHITELIST
                value: "^eth"
              - name: BPF
                value: "not port 80"
    ```

2. Ensure that the _daemonset_ contains the two key environment variables, otherwise the setup will fail to start:

    * `VSENSOR_HOSTNAME` - The hostname of the vSensor instance e.g. `10.0.2.15`

    * `VSENSOR_HMAC_KEY` - HMAC key for use with the vsensor e.g. `Y5mSAdHsKcjRuyW6`

    `hostNetwork` **must also be enabled** via `hostNetwork: true`. If it is not enabled, the osSensor install will not ingest all traffic.

3. Apply the osSensor daemonset to your cluster via `kubectl apply -f ossensor-daemonset-yaml`

    Applying the _osSensor daemonset_ will create one _osSensor pod_ for each node in your cluster. Pods may be located with `kubectl get pods`.

    osSensor logs can be located with `kubectl logs <ossensor-pod-name>`

Further configuration variables can be defined; a full list of available variables can be found below. Any additional configurations should be  provided via environmental variables. These can be passed using the **env selector** in the YAML file.

Please note, environment variables cannot be modified after the osSensor is initialized. To modify environment variables, please redeploy the osSensor with your changes.

To shell into the container for troubleshooting (for example, testing network connectivity to the vSensor) use `kubectl exec -it <ossensor-pod-name> /bin/bash`. The osSensor image is a streamlined image and does not contain any network troubleshooting tools as standard.

## Network Whitelist and Blacklist

The osSensor allows for a whitelist and blacklist to limit listening interfaces. If no blacklist/whitelist is provided, the osSensor will listen on all interfaces except loopback; in some environments this may result in duplicated traffic and therefore an increase in bandwidth usage. The blacklist and whitelist support `egrep` Regular Expression syntax. Where the scope of the whitelist and blacklist overlap, the blacklist will take priority.

+ Where a whitelist is provided, the osSensor will disregard all traffic other than that passing through the whitelisted interfaces.

  For example: `NETWORK_DEVICE_WHITELIST="^eth"` will discard all traffic that is not directed at interfaces beginning with `eth`.

+ Where a blacklist is provided, all traffic will be forwarded apart from traffic to the blacklisted interfaces.

  For example: `NETWORK_DEVICE_BLACKLIST="^veth"` will discard all traffic to interfaces beginning with `veth`.

+ Where a whitelist and a blacklist are provided, the blacklist can be used to remove specific interfaces from the scope of the whitelist

  For example: `NETWORK_DEVICE_BLACKLIST="eth7"` and `NETWORK_DEVICE_WHITELIST="^eth"` will forward all traffic from interfaces beginning with eth, apart from eth7 which will be disregarded.

## osSensor Environment Variables

The osSensor is configurable by key=value pairs via the use of environment variables.

### Available Variables

|            Key             |                                                                                                     Description                                                                                                     |        Default value        |
|:--------------------------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:---------------------------:|
|     VSENSOR\_HOSTNAME      |                                                                                        The hostname of the vSensor instance.                                                                                        |        **REQUIRED**         |
|     VSENSOR\_HMAC\_KEY     |                                                                                         HMAC key for use with the vSensor.                                                                                          |        **REQUIRED**         |
|       VSENSOR\_PORT        |                                                                                          The port of the vSensor instance.                                                                                          |             443             |
| OSSENSOR\_NETWORK\_DEVICE  |                                                                                               Device to capture from.                                                                                               |       Default gateway       |
|   OSSENSOR\_CONFIG\_PATH   |                                                                                         Location of generated config file.                                                                                          | /etc/darktrace/ossensor.cfg |
|      OSSENSOR\_DEBUG       |                                                          Set from level 0 (info level logging) to 5 (full packet data dumped).                                                          |              1              |
|     ANTIGENA\_ENABLED      |                                                                                   Boolean value to enable Antigena capabilities.                                                                                    |            true             |
|   ANTIGENA\_TIME\_PERIOD   |                                                                       Time period in seconds between sending Antigena actions to the vSensor.                                                                       |              5              |
| NETWORK\_DEVICE\_BLACKLIST | Whitespace separated list of network interface regex patterns to ignore. The blacklist takes priority over the whitelist. Any interface in the blacklist will not be monitored, **even if it is in the whitelist**. |             ''              |
| NETWORK\_DEVICE\_WHITELIST |                                        Whitespace separated list of network interfaces regex patterns to include. Any interface not in the whitelist will not be monitored.                                         |             ''              |
|     BPF      |                                                                                        Berkeley Packet Filter to apply.                                                                                        |        **''**         |

### Debug levels

| Level |                                                       Description                                                       |
|:-----:|:-----------------------------------------------------------------------------------------------------------------------:|
|   0   |                                                       Basic info.                                                       |
|   1   |                                         Packet capture stats / Antigena stats.                                         |
|   2   | Print info such as sending (number / size) or not sending, and the response. Sent packets stat will work in this level. |
|   3   |                                                     Antigena info.                                                      |
|   4   |                                 Print summary of each chunk of packets (time and size).                                 |
|   5   |                                   Print all packet contents as hex (very verbose!).                                     |
