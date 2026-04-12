"""Patch weewx.conf to use console logging instead of syslog."""
import re
import sys

CONSOLE_BLOCK = """\
        [[[console]]]
            level = DEBUG
            formatter = standard
            class = logging.StreamHandler
            stream = ext://sys.stdout"""

path = sys.argv[1]
with open(path, "r") as f:
    text = f.read()

# Replace syslog handler with console (handle varying whitespace)
text = re.sub(r'handlers\s*=\s*syslog\s*,', 'handlers = console,', text)

# Add console handler definition if not already present
if "[[[console]]]" not in text:
    text = text.replace(
        "facility = user",
        "facility = user\n" + CONSOLE_BLOCK,
    )

with open(path, "w") as f:
    f.write(text)
