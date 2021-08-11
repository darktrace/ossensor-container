# Deploying an osSensor on Docker

  * Dockerfile.tpl -- Dockerfile template for osSensor image **provided for reference only**
  * README.md -- Installation Guide
  * docker-entrypoint.sh -- Entrypoint for osSensor image **provided for reference only**
  * environment-file  -- Example environment file to provide env vars for docker run command

## Configuring the osSensor

The osSensor is available on Docker Hub at https://hub.docker.com/r/darktrace/ossensor. It requires two environment variables to run, otherwise the setup will produce an error:

  * `VSENSOR_HOSTNAME` - The host of the vSensor instance e.g. `10.0.0.1`
  * `VSENSOR_HMAC_KEY` - HMAC key for use with the vSensor e.g. `js84ld9vm3hff`

The basic deployment command is:

    docker run -e VSENSOR_HOSTNAME=<your-hostname> -e VSENSOR_HMAC_KEY=<vsensor-hmac> --network=host darktrace/ossensor:latest

+ **Host networking** **must also be enabled** via `--network=host`. If it is not enabled, the osSensor will start as normal but will not ingest all traffic.

+ The latest stable release of the Darktrace osSensor will always be tagged with  `:latest`. Additionally we tag the osSensor with semantic versioning `ossensor:MAJOR.MINOR.PATCH` and `ossensor:MAJOR`.

Further configuration variables can be defined; a full list of available variables can be found below.

Any additional configurations should be provided via environmental variables. These can be passed with the `-e` flag to `docker run`, or with an environment file by using the `--env-file` argument to `docker-run`.

To specify an environment file, deploy the osSensor using the following command:

      docker run --env-file <environment-file> --network=host darktrace/ossensor:latest

The environment file **must** contain the two variables - `VSENSOR_HOSTNAME` and `VSENSOR_HMAC_KEY` - or the container will not start.

  Specifying environment variables with an `-e` flag **overrides environment variables specified in the environment file**.

**Example Environment file**:
```
VSENSOR_HOSTNAME=192.168.0.1
VSENSOR_HMAC_KEY=js84ld9vm3hff
OSSENSOR_DEBUG=3
ANTIGENA_ENABLED=true
NETWORK_DEVICE_EXCLUDELIST=^veth
NETWORK_DEVICE_INCLUDELIST=^en
BPF=not port 80
```
Please note, environment variables cannot be modified after the osSensor is initialized. To modify environment variables, please redeploy the osSensor with your changes.

## Example Invocations

**Please note that if you would like the container to run in the background you should also provide the `-d` flag**

Run docker image, passing in environment variables with the `-e` flag:  

    docker run -e VSENSOR_HOSTNAME=10.0.2.15 -e VSENSOR_HMAC_KEY=js84ld9vm3hff darktrace/ossensor:latest

Run docker image, passing in environment variables with an environment file and `--env-file` flag:  

    docker run --env-file environment-file darktrace/ossensor:latest

Run docker image, passing in environment variables to monitor host network traffic and specifying which device to listen to via the `OSSENSOR_NETWORK_DEVICE` environment variable:

    docker run --env-file environment-file --network=host -e OSSENSOR_NETWORK_DEVICE=eth0 darktrace/ossensor:latest
> Note that specifying environment variables with an `-e` flag overrides environment variables specified in the environment file.

## Network Include list and Exclude list

The osSensor allows for an include list and exclude list to limit listening interfaces. If no exclude list/include list is provided, the osSensor will listen on all interfaces except loopback; in some environments this may result in duplicated traffic and therefore an increase in bandwidth usage. The exclude list and include list support `egrep` Regular Expression syntax. Where the scope of the include list and exclude list overlap, the exclude list will take priority.

+ Where an include list is provided, the osSensor will disregard all traffic other than that passing through the included interfaces.

  For example: `NETWORK_DEVICE_INCLUDELIST="^eth"` will discard all traffic that is not directed at interfaces beginning with `eth`.

+ Where an exclude list is provided, all traffic will be forwarded apart from traffic to the excluded interfaces.

  For example: `NETWORK_DEVICE_EXCLUDELIST="^veth"` will discard all traffic to interfaces beginning with `veth`.

+ Where an include list and an exclude list are provided, the exclude list can be used to remove specific interfaces from the scope of the include list.

  For example: `NETWORK_DEVICE_EXCLUDELIST="eth7"` and `NETWORK_DEVICE_INCLUDELIST="^eth"` will forward all traffic from interfaces beginning with eth, apart from eth7 which will be disregarded.

## Network Devices Appearing after Container Startup

Some hosts have network devices that may be ephemeral and appear after the osSensor container starts, which is common in Kubernetes hosts. The environment variable `NETWORK_DEVICE_ANY=1` can be used in order to indicate that the osSensor listen to any newly appearing interface after startup. The default behavior is to not listen to newly appearing devices after startup.

## osSensor Environment Variables

The osSensor is configurable by key=value pairs via the use of environment variables.

### Available Variables

| Key                          | Description                                                                                                                                                                                                                     | Default value                 |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `VSENSOR_HOSTNAME`           | The hostname of the vSensor instance. Also accepts IP addresses. Port must not be provided as part of this variable value and instead be supplied using `VSENSOR_PORT`.                                                                                                                                                                                           | `Required`                    |
| `VSENSOR_HMAC_KEY`           | HMAC key for use with the vSensor.                                                                                                                                                                                              | `Required`                    |
| `VSENSOR_PORT`               | The port of the vSensor instance.                                                                                                                                                                                               | 443                           |
| `OSSENSOR_NETWORK_DEVICE`    | Device to capture from.                                                                                                                                                                                                         | Default gateway               |
| `OSSENSOR_CONFIG_PATH`       | Location of generated config file.                                                                                                                                                                                              | /`etc/darktrace/ossensor.cfg` |
| `OSSENSOR_DEBUG`             | Set from level 0 (info level logging) to 5 (full packet data dumped).                                                                                                                                                           | 1                             |
| `ANTIGENA_ENABLED`           | Boolean value to enable Antigena capabilities.                                                                                                                                                                                  | TRUE                          |
| `ANTIGENA_TIME_PERIOD`       | Time period in seconds between sending Antigena actions to the vSensor.                                                                                                                                                         | 5                             |
| `NETWORK_DEVICE_EXCLUDELIST` | Whitespace separated list of network interface regex patterns to ignore.   The exclude list takes priority over the include list. Any interface in the   exclude list will not be monitored, even if it is in the include list. | `''`                          |
| `NETWORK_DEVICE_INCLUDELIST` | Whitespace separated list of network interfaces regex patterns to   include. Any interface not in the include list will not be monitored.                                                                                       | `''`                          |
| `NETWORK_DEVICE_ANY`         | Set to 1 to allow the osSensor to capture traffic on any new network   interface appearing after the osSensor container starts                                                                                                  | 0                             |
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
