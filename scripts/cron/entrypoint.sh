#!/bin/sh

# Load the specific crontab file
crontab /etc/cron.d/date_appender
crontab /etc/cron.d/init_koios_lite_cron

# Start the cron daemon
exec crond -f -d 8
