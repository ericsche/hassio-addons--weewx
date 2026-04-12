#!/usr/bin/env python3
"""Patch weewx.conf report sections using ConfigObj (reliable, no fragile sed)."""
import sys
from configobj import ConfigObj

conf_path = sys.argv[1]
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
