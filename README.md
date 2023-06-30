# MQTT plugin for the Decent Espresso DE1+

# Topics

* `{topic_prefix}/state`

  Changes to the machine state are published to this topic.

* `{topic_prefix}/command`

  The plugin takes action based on messages sent to the `command` topic:

  * `wake`: Wakes the machine from sleep.
  * `sleep`: Puts the machine to sleep, if it is not actively pouring.

# TLS Settings

TLS encryption will be used if the `ca_file` setting is non-empty.
If the `client_cert` and `client_key` settings are non-empty, they specify the
path to the client certificate to use for authentication.

```
ca_file {plugins/mqtt/ca.crt}
client_cert {plugins/mqtt/de1.crt}
client_key {plugins/mqtt/de1.key}
```
