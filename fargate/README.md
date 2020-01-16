# Deploying osSensor on AWS ECS Fargate

AWS ECS Fargate, being a serverless container deployment service, requires a different approach in order to capture traffic. Instead of requiring host network privileges, the osSensor container should be run as a sidecar that shares a network namespace with your application containers.

Please note: the osSensor must be incorporated into the task definition at the point of deployment for any containers or scaling container groups intended for monitoring. Any existing task definitions must be redeployed with the osSensor included in the definition.

The osSensor is available on Docker Hub at https://hub.docker.com/r/darktrace/ossensor.

  1. Log into the Amazon ECS console as an administrator and select **Task Definitions** on the left hand side.

  2. Create your task definition and ensure that you add an additional container definition for the osSensor image.

  3. Add any relevant environment variables to the osSensor container definition. The osSensor **requires** the `VSENSOR_HOSTNAME` and `VSENSOR_HMAC_KEY` variables to be set, otherwise the osSensor will fail to start.

Further configuration variables can be defined; a full list of available variables can be found below.

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
|   5   |                                   Print all packet contents as hex (very verbose!).    
