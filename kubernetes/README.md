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
              - name: NETWORK_DEVICE_EXCLUDELIST
                value: "^veth"
              - name: NETWORK_DEVICE_INCLUDELIST
                value: "^eth"
              - name: NETWORK_DEVICE_ANY
                value: "1"
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

## Network Include list and Exclude list

The osSensor allows for an include list and exclude list to limit listening interfaces. If no exclude list/include list is provided, the osSensor will listen on all interfaces except loopback; in some environments this may result in duplicated traffic and therefore an increase in bandwidth usage. The exclude list and include list support `egrep` Regular Expression syntax. Where the scope of the include list and exclude list overlap, the exclude list will take priority.

+ Where an include list is provided, the osSensor will disregard all traffic other than that passing through the included interfaces.

  For example: `NETWORK_DEVICE_INCLUDELIST="^eth"` will discard all traffic that is not directed at interfaces beginning with `eth`.

+ Where an exclude list is provided, all traffic will be forwarded apart from traffic to the excluded interfaces.

  For example: `NETWORK_DEVICE_EXCLUDELIST="^veth"` will discard all traffic to interfaces beginning with `veth`.

+ Where an include list and an exclude list are provided, the exclude list can be used to remove specific interfaces from the scope of the include list

  For example: `NETWORK_DEVICE_EXCLUDELIST="eth7"` and `NETWORK_DEVICE_INCLUDELIST="^eth"` will forward all traffic from interfaces beginning with eth, apart from eth7 which will be disregarded.

## Network Devices Appearing after Container Startup

Some hosts have network devices that may be ephemeral and appear after the osSensor container starts, which is common in Kubernetes hosts. The environment variable `NETWORK_DEVICE_ANY=1` can be used in order to indicate that the osSensor listen to any newly appearing interface after startup. The default behavior is to not listen to newly appearing devices after startup.


## osSensor Environment Variables

The osSensor is configurable by key=value pairs via the use of environment variables.

### Available Variables

| Key                          | Description                                                                                                                                                                                                                     | Default value                 |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `VSENSOR_HOSTNAME`           | The hostname of the vSensor instance. Also accepts IP addresses. Port must not be provided as part of this variable value and instead be supplied using `VSENSOR_PORT`.                                                                                                                                                                                           | **Required**                  |
| `VSENSOR_HMAC_KEY`           | HMAC key for use with the vSensor.                                                                                                                                                                                              | **Required**                  |
| `VSENSOR_PORT`               | The port of the vSensor instance.                                                                                                                                                                                               | 443                           |
| `OSSENSOR_NETWORK_DEVICE`    | Device to capture from.                                                                                                                                                                                                         | Default gateway               |
| `OSSENSOR_CONFIG_PATH`       | Location of generated config file.                                                                                                                                                                                              | `/etc/darktrace/ossensor.cfg` |
| `OSSENSOR_DEBUG`             | Set from level 0 (info level logging) to 5 (full packet data dumped).                                                                                                                                                           | 1                             |
| `ANTIGENA_ENABLED`           | Boolean value to enable Antigena capabilities.                                                                                                                                                                                  | true                          |
| `ANTIGENA_TIME_PERIOD`       | Time period in seconds between sending Antigena actions to the vSensor.                                                                                                                                                         | 5                             |
| `NETWORK_DEVICE_EXCLUDELIST` | Whitespace separated list of network interface regex patterns to ignore. The exclude list takes priority over the include list. Any interface in the exclude list will not be monitored, **even if it is in the include list**. | `''`                          |
| `NETWORK_DEVICE_INCLUDELIST` | Whitespace separated list of network interfaces regex patterns to include. Any interface not in the include list will not be monitored.                                                                                         | `''`                          |
| `NETWORK_DEVICE_ANY`         | Set to 1 to allow the osSensor to capture traffic on any new network interface appearing after the osSensor container starts                                                                                                    | 0                             |
| `BPF`                        | Berkeley Packet Filter to apply.                                                                                                                                                                                                | `''`                          |

### Debug levels

| Level | Description                                                                                                             |
| ----- | ----------------------------------------------------------------------------------------------------------------------- |
| 0     | Basic info.                                                                                                             |
| 1     | Packet capture stats / Antigena stats.                                                                                  |
| 2     | Print info such as sending (number / size) or not sending, and the response. Sent packets stat will work in this level. |
| 3     | Antigena info.                                                                                                          |
| 4     | Print summary of each chunk of packets (time and size).                                                                 |
| 5     | Print all packet contents as hex (very verbose!).                                                                       |
