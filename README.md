# Darktrace osSensor Docker Image

## Introduction

Darktrace osSensors are lightweight, host-based server agents that extend Darktrace’s visibility into third-party cloud environments, including AWS and Microsoft Azure. Available for any system that can run the Docker Engine, Darktrace osSensors are robust and resilient, allowing organizations to enhance visibility and deliver Enterprise Immune System monitoring to cloud environments, wherever they are hosted.

The Darktrace vSensor coordinates with the osSensors associated with it, ensuring traffic is captured only once when osSensor devices communicate to each other. Each osSensor registers with a vSensor using a shared HMAC token which should be supplied to both ends. It is recommended that the associated vSensor is configured in advance of osSensor setup, in order to ensure the necessary HMAC token and IP Address or hostname for the vSensor have been collected.

Upon registration with the vSensor, the osSensor is provided with a packet filter which instructs it to ignore the flows to selected other osSensor IPs and data traffic to the vSensor (port 80/tcp and port 443/tcp). These packets are sent onward to the vSensor, where they are processed by the deep packet inspection engine and forwarded on to a physical Darktrace Enterprise Immune System (EIS) appliance or hosted Darktrace Cloud master.

Please note, the osSensor will only process traffic from non-loopback interfaces.

## Requirements

These elements are required to perform the installation process for a Darktrace osSensor.

  * A Darktrace Master Appliance running Darktrace v4.0+

  * The IP or hostname of a configured vSensor reachable from the intended osSensor location.

  * The shared HMAC secret key between the osSensor and vSensor required for installation. Set this on the vSensor in the `confconsole` or with `set_ossensor_hmac.sh <token>` on the vSensor command line.

  * Access to Docker Hub at https://hub.docker.com/r/darktrace/ossensor to download the osSensor image.

We recommend that the Darktrace osSensor image is run in an environment with a minimum of 1GB free Ram and 2+ CPU cores. The impact on disk space should be negligible. Please note, unusually large traffic throughput will impact performance and may require more resources.

Please note, the osSensor image is a streamlined image and does not contain any network troubleshooting tools as standard.

## Supported Platforms

Any platform that supports the Docker Engine **with host networking privileges** can run the osSensor Docker image.

This guide will cover deployment on the following platforms:

* Docker Engine on Linux hosts

* Kubernetes:
    - Azure AKS
    - Amazon EKS
    - Google GCP

* AWS ECS Fargate (_host networking not necessary_) via an osSensor Sidecar.


## [FAQ](FAQ.md)
## [Docker](docker/)
## [Fargate](fargate/)
## [Kubernetes](kubernetes/)
