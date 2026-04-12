"""Patch weewx.conf: override logging to use console (stdout) instead of syslog.

WeeWX has a hardcoded LOGGING_STR default with syslog handlers.
It merges any [Logging] section from weewx.conf on top of that default.
So we just need to add/overwrite the [Logging] section with the console handler
and point the root logger at it instead of syslog.
"""
import sys
from configobj import ConfigObj

path = sys.argv[1]
config = ConfigObj(path, encoding='utf-8', default_encoding='utf-8',
                   write_empty_values=True)

# Create or overwrite the [Logging] section with console-only logging.
# WeeWX merges this on top of its LOGGING_STR defaults.
config['Logging'] = {
    'root': {
        'handlers': ['console'],
    },
    'handlers': {
        'console': {
            'level': 'DEBUG',
            'formatter': 'standard',
            'class': 'logging.StreamHandler',
            'stream': 'ext://sys.stdout',
        },
    },
}

config.write()
