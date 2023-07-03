# MQTT plugin for the Decent Espresso DE1+

This plugin adds MQTT support to DE1+ machines.  It supports publishing status
information to MQTT, as well as receiving commands to wake the device or put it
to sleep.

See [docs/topics.md](docs/topics.md) for a description of the topics.

## Settings

Most settings are configurable through the settings UI in the app.

A few settings can only be configured by manually uploading files or editing
the `settings.tdb` file by plugging the tablet into a computer.

See [docs/settings.md](docs/settings.md) for more detailed documentation of the
settings.

## Overriding Android Doze Mode

By default, Android puts background applications to sleep, and prevents them
from using the network.  If this happens, it will close the connection to the
MQTT broker, meaning that it cannot publish updates, and more importantly it
cannot receive MQTT commands to wake up.

If you find that device disconnects and reports itself as offline after you
turn the tablet display off for several minutes, try applying the following
changes in the Android settings:

* Ensure the Androwish application settings allow unrestricted battery usage,
  and that android is not configured to put Androwish to sleep when not in use.

* Disable the "Adaptive Battery" setting
