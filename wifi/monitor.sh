#!/bin/bash

sudo ifconfig ${INTERFACE} down
sudo iwconfig ${INTERFACE} mode monitor
sudo ifconfig ${INTERFACE} up

iwconfig ${INTERFACE}
