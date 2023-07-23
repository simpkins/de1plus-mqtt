# MQTT plugin for the Decent Espresso DE1+

This plugin adds MQTT support to [Decent Espresso](https://decentespresso.com/)
machines.  It supports publishing the current device state, temperature
sensors, water level, and usage counts, and also allows remotely waking or
putting the machine to sleep via MQTT messages.

See [docs/topics.md](docs/topics.md) for a description of the MQTT topics used
by the plugin.  [docs/settings.md](docs/settings.md) contains some details
about the configuration settings.

This is built using the
[tcl mqtt package](https://chiselapp.com/user/schelte/repository/mqtt/index)
that is already included by default in [AndroWish](https://www.androwish.org/).

## HomeAssistant Auto-Discovery

This plugin can automatically publish
[HomeAssistant auto-discovery](https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery)
messages, making it very easy to use with HomeAssistant with minimal manual
configuration.

Currently it publishes configuration for 9 different sensors, as well as 1
switch to allow remotely turning on or off the machine.

## Installation

To install, connect your Decent's tablet to a computer with a USB cable so you
can transfer files to it.  Inside the `de1plus/plugins` directory on the
tablet, create a folder named `mqtt` and copy both the `plugin.tcl` and
`settings.tdb` files into this directory.

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

These settings should allow the MQTT plugin to successfully maintain its
connection to the broker as long as the tablet is plugged in to power (which is
normally the case when connected to your espresso machine).  Android may still
disconnect the background MQTT connection if the tablet is on battery power and
the tablet display is off.
