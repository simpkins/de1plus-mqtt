# Settings

## Main settings

* Broker Host and Port

  The hostname (or IP address) and port of the MQTT broker to connect to.

  The default MQTT ports for most brokers are 8883 when using TLS encryption,
  or 1883 when not using TLS.

* Username and Password

  The username and password for authenticating to the MQTT broker.

* Client ID

  The Client ID to use when connecting to the MQTT broker.  Every client must
  have a unique ID, so if you have multiple DE1+ machines, give each one a
  unique ID.

* Topic Prefix

  The topic prefix to use.  State updates will be published to
  `{topic_prefix}/state`, and wake/sleep commands will be listened for on the
  `{topic_prefix}/command` prefix.

  If you have multiple DE1+ machines, you will want to give each one a unique
  prefix.

* Use TLS

  Whether to communicate with the broker using TLS encryption or not.

## Advanced Settings

These settings are only configurable by connecting your tablet to a computer
and manually editing the `settings.tdb` file and/or uploading other files.

* TLS CA File

  To enable TLS server certificate validation, a Certificate Authority file
  must be uploaded.  The `ca_file` setting in settings.tdb should then be
  updated to contain the path to the CA file, relative to the `de1plus`
  directory.  e.g., if you put the CA file at `de1plus/plugins/mqtt/ca.crt`,
  then edit `settings.tdb` to include the line `ca_file {plugins/mqtt/ca.crt}`

* TLS Client Certificate

  If you want to authenticate to the MQTT server by sending a TLS client
  certificate, the certificate and key files must be uploaded.  After placing
  these files inside the de1plus directory, edit `settings.tdb` and set the
  `client_cert` and `client_key` fields to contain the path of these files,
  relative to the `de1plus` directory.

  The client key file should be unencrypted, so it can be loaded without
  needing a password.

  ```
  client_cert {plugins/mqtt/de1.crt}
  client_key {plugins/mqtt/de1.key}
  ```

* Publish Interval

  The `publish_interval` setting controls how frequently updates are published
  to the `{topic_prefix}/state` topic (in seconds).  The default interval is 60
  seconds.

  Updates are published whenever the device state changes, or when at least
  `publish_interval` seconds have elapsed since the last update.  This allows
  temperature values updates to be published regularly even when the device
  state has not changed.
