#!/bin/sh

# Load the specific crontab file
crontab /etc/cron.d/date_appender

# Start the cron daemon
exec crond -f -d 8
