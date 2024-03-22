# Changelog

## Version 1.3

- Added support for controlling the steam heater state
- Automatically remove the retained Home Assistant auto-discovery messages when
  the auto-discovery setting is disabled.

## Version 1.2

- Fixed a bug preventing Home Assstant auto-discovery from working on tablets
  running newer versions of Androwish.
- Updated the code to automatically populate the settings with default values
  if any plugin settings are missing, removing the need to install the
  settings.tdb file.
- Fixed a bug handling non-ASCII characters in profile names.
