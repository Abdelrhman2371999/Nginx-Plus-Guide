#!/bin/bash
# Script to log keepalived state changes

STATE=$1
DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)

case $STATE in
    "master")
        echo "$DATE - $HOST became MASTER - Taking over VIP 172.20.20.51" >> /var/log/keepalived-state.log
        # Optional: Send alert via webhook
        # curl -X POST https://your-monitoring-server/alert -d "status=master&host=$HOST"
        ;;
    "backup")
        echo "$DATE - $HOST became BACKUP - Releasing VIP" >> /var/log/keepalived-state.log
        ;;
    "fault")
        echo "$DATE - $HOST entered FAULT state - Check Nginx!" >> /var/log/keepalived-state.log
        ;;
esac
