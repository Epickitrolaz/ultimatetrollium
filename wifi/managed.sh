#!/bin/bash

sudo ifconfig ${INTERFACE} down
sudo iwconfig ${INTERFACE} mode managed
sudo ifconfig ${INTERFACE} up

iwconfig ${INTERFACE}
