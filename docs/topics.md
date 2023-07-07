# Topics

## `{topic_prefix}/state`

Information about the machine state is published to this topic.  Each message
contains a JSON dictionary, which will contain the following fields:

* `online`

  Boolean.  True when the tablet is connected to the MQTT broker, and false
  when the tablet is disconnected.  This field is always present.

* `de1_connected`

  Boolean.  True if the tablet is successfully connected to the DE1+, or false
  if the bluetooth connection is not established.  This field is always
  present.  If it is false only the `online` and `de1_connected` fields will be
  present in the message, no other fields will be present since the DE1+ state
  is not available.

* `scale_connected`

  Boolean.  True if the scale is connected, and false otherwise.

* `state`

  String.  The state of the device (e.g. "Sleep", "Idle", "Espresso", etc.)
  For a full list of states, see the `de1_num_state` array in
  [de1plus/machine.tcl](https://github.com/decentespresso/de1app/blob/b3e3a01ce9019623746c36c96313976489c48a2b/de1plus/machine.tcl#L506)

* `substate`

  String.  The substate of the device (e.g. "ready", "heating", "pouring", etc.)
  For a full list of states, see the `de1_substate_types` array in
  [de1plus/machine.tcl](https://github.com/decentespresso/de1app/blob/b3e3a01ce9019623746c36c96313976489c48a2b/de1plus/machine.tcl#L537)

* `profile`

  String.  The title of the currently configured shot profile.

* `profile_filename`

  String.  The filename of the currently configured shot profile.

* `espresso_count`

  Integer.  The total number of espresso shots this machine has ever poured.

* `steaming_count`

  Integer.  The total number of times the steam function has been used on this
  machine.

* `head_temperature`

  Float.  The group head temperature, in degrees Celsius.

* `mix_temperature`

  Float.  The water mix temperature, in degrees Celsius.

* `steam_heater_temperature`

  Float.  The steam heater temperature, in degrees Celsius.

* `water_level_mm`

  Float.  The water level in the water tank, in millimeters.

* `water_level_ml`

  Integer.  The water level in the water tank, in milliliters.  (This is
  calculated in software based on the millimeter water height measurement.)

* `wake_state`

  Boolean.  This is false when the DE1 state is "Sleep", and true in any other
  state.  This is provided as a convenience in order to make it easier for
  other MQTT clients to treat the DE1+ as a binary switch that can be toggled
  on or off.

## `{topic_prefix}/command`

The plugin takes action based on messages sent to the `command` topic.
Currently the following are supported:

* `wake`

  Wakes the machine from sleep.

* `sleep`

  Puts the machine to sleep, if it is not actively pouring.

* `profile PROFILE`

  Sets the current machine profile.

  The profile name may contain spaces (and any other special characters).  All
  data following the space after `profile` is treated as the profile name,
  without any escaping.

* `profile_filename PROFILE_FILENAME`

  Sets the current machine profile to the specified profile, by profile
  filename.

  The file name may contain spaces (and any other special characters).  All
  data following the space after `profile_filename` is treated as the file
  name, without any escaping.
