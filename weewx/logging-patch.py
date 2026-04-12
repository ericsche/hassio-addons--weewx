"""Patch weewx.conf: replace syslog handler with console (stdout).

Uses ConfigObj (same parser WeeWX uses) for reliable config editing
regardless of whitespace or formatting variations.
"""
import sys
from configobj import ConfigObj

path = sys.argv[1]
config = ConfigObj(path, encoding='utf-8', default_encoding='utf-8',
                   write_empty_values=True)

if 'Logging' not in config:
    sys.exit(0)

log_section = config['Logging']

# 1. Replace syslog with console in root logger handlers
if 'loggers' in log_section and 'root' in log_section['loggers']:
    root = log_section['loggers']['root']
    handlers = root.get('handlers', '')
    if isinstance(handlers, list):
        root['handlers'] = [('console' if h.strip() == 'syslog' else h.strip())
                            for h in handlers]
    elif isinstance(handlers, str) and 'syslog' in handlers:
        root['handlers'] = handlers.replace('syslog', 'console')

# 2. Remove syslog handler, add console handler
if 'handlers' in log_section:
    hdlrs = log_section['handlers']
    if 'syslog' in hdlrs:
        del hdlrs['syslog']
    hdlrs['console'] = {}
    hdlrs['console']['level'] = 'DEBUG'
    hdlrs['console']['formatter'] = 'standard'
    hdlrs['console']['class'] = 'logging.StreamHandler'
    hdlrs['console']['stream'] = 'ext://sys.stdout'

config.write()
