#!/usr/bin/env python3
"""Patch weewx.conf report sections using ConfigObj (reliable, no fragile sed)."""
import sys
from configobj import ConfigObj

conf_path = sys.argv[1]
config = ConfigObj(conf_path, encoding='utf-8', indent_type='    ')

# Enable StandardReport (neowx-material skin is installed here by the extension)
if 'StdReport' in config:
    std = config['StdReport']
    if 'StandardReport' in std:
        std['StandardReport']['enable'] = 'true'
        print(f"  StandardReport: enable=true, skin={std['StandardReport'].get('skin', '?')}")
    if 'SeasonsReport' in std:
        std['SeasonsReport']['enable'] = 'false'
    if 'SmartphoneReport' in std:
        std['SmartphoneReport']['enable'] = 'false'
    if 'MobileReport' in std:
        std['MobileReport']['enable'] = 'false'

config.write()
print("Report config patched successfully.")
