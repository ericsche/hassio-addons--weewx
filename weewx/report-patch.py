#!/usr/bin/env python3
"""Patch weewx.conf report and REST sections using ConfigObj."""
import sys
from configobj import ConfigObj

conf_path = sys.argv[1]
wu_id = sys.argv[2] if len(sys.argv) > 2 else ''
wu_password = sys.argv[3] if len(sys.argv) > 3 else ''
config = ConfigObj(conf_path, encoding='utf-8', indent_type='    ')

# Enable StandardReport (neowx-material skin is installed here by the extension)
if 'StdReport' in config:
    std = config['StdReport']

    # Force neowx-material skin on StandardReport
    # (the extension installer's config merge gets lost when ConfigObj rewrites the file)
    if 'StandardReport' in std:
        std['StandardReport']['skin'] = 'neowx-material'
        std['StandardReport']['enable'] = 'true'
        print(f"  StandardReport: enable=true, skin=neowx-material")

    # Disable all other report skins
    for name in ('SeasonsReport', 'SmartphoneReport', 'MobileReport'):
        if name in std:
            std[name]['enable'] = 'false'

    # Set language and units in Defaults
    if 'Defaults' not in std:
        std['Defaults'] = {}
    std['Defaults']['lang'] = 'fr'
    std['Defaults']['unit_system'] = 'metricwx'

config.write()
print("Report config patched successfully.")

# --- Wunderground posting ---
if wu_id and wu_password:
    if 'StdRESTful' not in config:
        config['StdRESTful'] = {}
    if 'Wunderground' not in config['StdRESTful']:
        config['StdRESTful']['Wunderground'] = {}
    wu = config['StdRESTful']['Wunderground']
    wu['enable'] = 'true'
    wu['station'] = wu_id
    wu['password'] = wu_password
    wu['rapidfire'] = 'false'
    config.write()
    print(f"Wunderground posting enabled for station {wu_id}")
else:
    print("Wunderground posting not configured (no station ID/password).")
