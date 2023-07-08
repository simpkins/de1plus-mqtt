# Settings

Here are more detailed descriptions of the settings configurable in the
settings UI dialog:

* Broker Host and Port

  The hostname (or IP address) and port of the MQTT broker to connect to.

  The default MQTT ports for most brokers are 8883 when using TLS encryption,
  or 1883 when not using TLS.

* Username and Password

  The username and password for authenticating to the MQTT broker.

* Client ID

  The Client ID to use when connecting to the MQTT broker.  Every client must
  have a unique ID, so if you have multiple DE1+ machines, each one should have
  a unique ID.

  If this setting is empty (which is the default the first time you run the
  plugin), a unique ID will be chosen and the prefix will be saved as
  `de1plus_<unique_id>`.  This allows a unique ID to be assigned to each
  machine to prevent client ID conflicts if you have multiple DE1+ machines.

* Topic Prefix

  The topic prefix to use.  State updates will be published to
  `{topic_prefix}/state`, and wake/sleep commands will be listened for on the
  `{topic_prefix}/command` prefix.

  If this setting is empty (which is the default the first time you run the
  plugin), a unique ID will be chosen and the prefix will be saved as
  `de1plus/<unique_id>`.  This allows a unique ID to be assigned to each
  machine to prevent topic name conflicts if you have multiple DE1+ machines.

* Use TLS

  Whether to communicate with the broker using TLS encryption or not.

* TLS CA File

  This setting lists the path name to Certificate Authority file to use for
  verifying the MQTT broker's TLS certificate.

  This setting cannot be edited via the UI--you will need to upload a CA
  file to the tablet using a USB connection to a computer.  After uploading a
  CA file, edit the `ca_file` setting in `de1plus/plugins/mqtt/settings.tdb` to
  contain the path where you have placed the CA file.  This path should be
  relative to the `de1plus` directory.  e.g., if you put the CA file at
  `de1plus/plugins/mqtt/ca.crt`, then edit `settings.tdb` to include the line
  `ca_file {plugins/mqtt/ca.crt}`

* TLS Client Certificate

  If you want to authenticate to the MQTT server by sending a TLS client
  certificate, the certificate and key files must be uploaded to the tablet.
  After placing these files inside the de1plus directory, edit `settings.tdb`
  and set the `client_cert` and `client_key` fields to contain the path of
  these files, relative to the `de1plus` directory.

  The client key file should be unencrypted, so it can be loaded without
  needing a password.

* Publish Interval (ms)

  The `publish_interval` setting controls how frequently updates are published
  to the `{topic_prefix}/state` topic, in milliseconds.  The default interval
  is 60 seconds.

  Updates are published whenever the device state changes, or when at least
  `publish_interval` seconds have elapsed since the last update.  This allows
  temperature values updates to be published regularly even when the device
  state has not changed.

* Enable HomeAssistant Auto-Discovery

  If you enable this setting, the plugin will publish
  [HomeAssistant discovery messages](https://www.home-assistant.io/integrations/mqtt/#discovery-messages)
  each time it establishes a connection to the MQTT broker.

  This allows HomeAssistant to automatically know about the sensors and switch
  provided by the plugin, without having to manually configure it in
  HomeAssistant.

* HA Device Name

  The device name to use for the machine in HomeAssistant.

* HA Entity Name Prefix

  A string prefix to use for all of the HomeAssistant entity names in the
  auto-discovery configuration messages.  e.g., if you set the prefix to
  `DE1XXL `, the sensor names will be `DE1XXL Water Level`,
  `DE1XXL Steam Temperature`, etc.

* HA Auto-discovery Prefix

  The MQTT topic prefix to use when publishing HomeAssistant auto-discovery
  messages.  The default is `homeassistant`, which is the default value for
  HomeAssistant.  You should only need to change this if you have manually
  edited the topic prefix in your
  [HomeAssistant configuration](https://www.home-assistant.io/integrations/mqtt/#discovery-options)

* Unique ID

  This is a string to include as part of the
  [`unique_id`](https://www.home-assistant.io/integrations/sensor.mqtt/#unique_id)
  field for each entity published to HomeAssistant.  A unique ID will be
  randomly generated for you the first time you use the plugin.
