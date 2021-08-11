# Deploying osSensor on AWS ECS Fargate

AWS ECS Fargate, being a serverless container deployment service, requires a different approach in order to capture traffic. Instead of requiring host network privileges, the osSensor container should be run as a sidecar that shares a network namespace with your application containers.

Please note: the osSensor must be incorporated into the task definition at the point of deployment for any containers or scaling container groups intended for monitoring. Any existing task definitions must be redeployed with the osSensor included in the definition.

The osSensor is available on Docker Hub at https://hub.docker.com/r/darktrace/ossensor.

  1. Log into the Amazon ECS console as an administrator and select **Task Definitions** on the left hand side.

  2. Create your task definition and ensure that you add an additional container definition for the osSensor image.

  3. Add any relevant environment variables to the osSensor container definition. The osSensor **requires** the `VSENSOR_HOSTNAME` and `VSENSOR_HMAC_KEY` variables to be set, otherwise the osSensor will fail to start.

Further configuration variables can be defined; a full list of available variables can be found below.

## Network Include list and Exclude list

The osSensor allows for an include list and exclude list to limit listening interfaces. If no exclude list/include list is provided, the osSensor will listen on all interfaces except loopback; in some environments this may result in duplicated traffic and therefore an increase in bandwidth usage. The exclude list and include list support `egrep` Regular Expression syntax. Where the scope of the include list and exclude list overlap, the exclude list will take priority.

+ Where an include list is provided, the osSensor will disregard all traffic other than that passing through the include listed interfaces.

  For example: `NETWORK_DEVICE_INCLUDELIST="^eth"` will discard all traffic that is not directed at interfaces beginning with `eth`.

+ Where an exclude list is provided, all traffic will be forwarded apart from traffic to the exclude listed interfaces.

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
