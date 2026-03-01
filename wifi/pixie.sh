#!/bin/bash

sudo ifconfig ${INTERFACE} down
sudo iwconfig ${INTERFACE} mode managed # OneShot needs the adapter to be in managed
sudo ifconfig ${INTERFACE} up

sleep 1

sudo python ../.scripts/ose/ose.py -i ${INTERFACE} -K -F -X -w
