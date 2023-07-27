
# Change package name for you extension / plugin
set plugin_name "mqtt"

namespace eval ::plugins::${plugin_name} {

    # These are shown in the plugin selection page
    variable author "Adam Simpkins"
    variable contact "adam@adamsimpkins.net"
    variable version 1.1
    variable description "Report events and allow control via MQTT."
    variable name "MQTT Integration"
    variable current_status "Not connected"
    variable client_started 0
    variable publish_timer_id {}

    proc build_settings_ui {}  {
        build_settings_page1
        build_settings_page2
        return "plugin_mqtt_settings1"
    }

    proc common_page_setup {page_name next_page_name next_page_id}  {
        add_de1_page "$page_name" "settings_message.png" "default"

        # Headline
        add_de1_text $page_name 1280 300 \
            -text [translate "MQTT Settings"] -font Helv_20_bold \
            -width 1200 -fill "#444444" -anchor "center" -justify "center"

        # Add the "Done" button over the center button outline already present
        # in the settings_message.png image.
	dui add dbutton $page_name 1030 1250 1530 1370 \
            -shape round -radius 30 \
            -command { \
                say [translate {Done}] $::settings(sound_button_in); \
                ::plugins::mqtt::apply_settings_changes; \
                page_to_show_when_off extensions \
            } \
            -label [translate "Done"] \
            -label_font Helv_10_bold -label_fill "#fAfBff"

        # Add an extra "Apply" button to the left of the Done button.
        # This applies the settings without leaving the settings page, so
        # users can more easily see the status update after attempting to
        # connect.
	dui add dbutton $page_name 380 1250 880 1370 \
            -shape round -radius 30 \
            -command { \
                say [translate {Apply}] $::settings(sound_button_in); \
                ::plugins::mqtt::apply_settings_changes; \
            } \
            -label [translate "Apply"] \
            -label_font Helv_10_bold -label_fill "#fAfBff"

        # Button to go to the other page
        set other_page_cmd [string cat \
            "say [translate $next_page_name];" \
            "page_to_show_when_off $next_page_id" \
        ]
	dui add dbutton $page_name 1680 1250 2180 1370 \
            -shape round -radius 30 \
            -command $other_page_cmd \
            -label [translate $next_page_name] \
            -label_font Helv_10_bold -label_fill "#fAfBff"

        #
        # Status line
        #

        set status_x 450
        set status_y 1120
        add_de1_text $page_name $status_x $status_y -font Helv_10_bold \
            -width 1000 -anchor "e" -justify "right" \
            -text "Status:"
        add_de1_variable $page_name [expr $status_x + 10] $status_y \
            -font Helv_8 -width 2000 \
            -anchor "w" -justify "left" \
            -textvariable {$::plugins::mqtt::current_status}
    }

    proc build_settings_page1 {}  {
        variable settings

        set page_name "plugin_mqtt_settings1"
        common_page_setup $page_name "Page 2" plugin_mqtt_settings2

        set col1_x 625
        set col1_label_x 650
        set label_width 400
        set col2_x 1725
        set col2_label_x 1750

        set y_start 480
        set y_spacing 80

        set col1_y $y_start
        set col2_y $y_start

        #
        # Left Column
        #

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Broker Host"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(host) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Broker Port"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 10 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(port) \
            -validate key \
            -vcmd [list ::dui::validate_numeric %P 0 0 65535] \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Username"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(user) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Password"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(password) \
            -show "*" \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Client ID"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(client_id) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Topic Prefix"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(topic_prefix) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        #
        # Right Column
        #

        add_de1_text $page_name $col2_x $col2_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Use TLS"
        add_de1_widget $page_name checkbutton $col2_label_x $col2_y \
            {} \
            -variable ::plugins::mqtt::settings(enable_tls) \
            -foreground #4e85f4 -bg #ffffff -activebackground #ffffff \
            -canvas_anchor "w" -relief flat -borderwidth 0 \
            -highlightthickness 0 -highlightcolor #000000 
        set col2_y [expr $col2_y + $y_spacing]

        add_de1_text $page_name $col2_x $col2_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "TLS CA File"
        add_de1_variable $page_name $col2_label_x $col2_y \
            -font Helv_8 -width 400 \
            -anchor "w" -justify "left" \
            -textvariable {[::plugins::mqtt::settings_ca_file_status]}
        set col2_y [expr $col2_y + $y_spacing]

        add_de1_text $page_name $col2_x $col2_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Client Cert"
        add_de1_variable $page_name $col2_label_x $col2_y \
            -font Helv_8 -width 400 \
            -anchor "w" -justify "left" \
            -textvariable {[::plugins::mqtt::settings_client_cert_status]}
        set col2_y [expr $col2_y + $y_spacing]

        # Warning if TLS is enabled with no cert verification
        add_de1_variable $page_name 1450 760 \
            -font Helv_8 -width 425 \
            -anchor "nw" -justify "left" \
            -textvariable {[::plugins::mqtt::settings_ca_status_note]}

        return $page_name
    }

    proc build_settings_page2 {}  {
        variable settings

        set page_name "plugin_mqtt_settings2"
        common_page_setup $page_name "Page 1" plugin_mqtt_settings1

        set col1_x 1225
        set col1_label_x 1250
        set label_width 900
        set col1_y 480
        set y_spacing 80

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Publish Interval (ms)"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -validate key \
            -vcmd [list ::dui::validate_numeric %P 0 0 {}] \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(publish_interval_ms) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Enable HomeAssistant Auto-Discovery"
        add_de1_widget $page_name checkbutton $col1_label_x $col1_y \
            {} \
            -variable ::plugins::mqtt::settings(ha_auto_discovery_enable) \
            -foreground #4e85f4 -bg #ffffff -activebackground #ffffff \
            -canvas_anchor "w" -relief flat -borderwidth 0 \
            -highlightthickness 0 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "HA Device Name"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(ha_device_name) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "HA Entity Name Prefix"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(ha_entity_name_prefix) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "HA Auto-discovery Prefix"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(ha_discovery_prefix) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "Unique ID"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 -canvas_anchor "w" \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(unique_id) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        return $page_name
    }

    proc settings_ca_file_status {} {
        variable settings

        if { $settings(ca_file) ne "" } {
            return $settings(ca_file)
        }
        return "Not set"
    }

    proc settings_client_cert_status {} {
        variable settings

        if { $settings(client_cert) eq "" } {
            return "Not set"
        }
        return $settings(client_cert)
    }

    proc settings_ca_status_note {} {
        variable settings

        if { $settings(enable_tls) && $settings(ca_file) eq "" } {
            return [string cat \
                "Note: TLS is enabled with no CA file. " \
                "Certificate verification is disabled. " \
                "Upload a CA file to enable verification."
            ]
        }
        return ""
    }

    # Helper function that prefixes our plugin name to all messages
    # we log in this namespace.
    proc msg {args} {
        set first_arg [lindex $args 0]
        if { [string index $first_arg 0] == {-} } {
            ::msg $first_arg [namespace current] {*}[lrange $args 1 end]
        } else {
            ::msg [namespace current] {*}$args
        }
    }

    proc on_conn_event {topic data retain} {
        variable current_status
        # Republish our status each time we reconnect
        if {[dict get $data state] eq "connected"} {
            msg "connected"
            # Publishing directly inside a CONNACK event callback unfortunately
            # doesn't work, since the mqtt library hasn't stored the fd yet,
            # and it just drops the publish message.  Therefore use an after
            # call to schedule this publish.
            after 1 ::plugins::mqtt::post_connect_publish
            set current_status "Connected"
        } else {
            # The mqtt package unfortunately does not deliver connection events
            # to us with the TCP connection is refused.  We only mostly only
            # get connection events after the connection is established and the
            # server sends a CONNACK packet.  Therefore on TCP connect errors
            # our current_status will unfortunately just remain as
            # "Connecting..." in most cases.
            msg "connection status: $data"

            switch -- [dict get $data reason] {
              0 {set reason_str "Connection Accepted"}
              1 {set reason_str "Unaccepted MQTT Protocol Version"}
              2 {set reason_str "Client ID Rejected"}
              3 {set reason_str "Server Unavailable"}
              4 {set reason_str "Bad Username or Password"}
              5 {set reason_str "Client Not Authorized"}
              default {set reason_str "MQTT code $data(reason)"}
            }
            set current_status "[dict get $data state]: $reason_str"
            msg "connection status: $current_status"
        }
    }

    proc post_connect_publish {} {
        variable settings
        force_immediate_publish
        if {$settings(ha_auto_discovery_enable)} {
            publish_ha_discovery_messages
        }
    }

    proc publish_ha_discovery_messages {} {
        msg "sending HomeAssistant discovery messages"

        # Sensors
        publish_ha_sensor "State" "state" "state" {} {} {} \
            "hass:state-machine"
        publish_ha_sensor "Substate" "substate" "substate" {} {} {} \
            "hass:state-machine"
        publish_ha_sensor "Water Level" "water_level" "water_level_ml" \
            "volume_storage" "measurement" "mL" "hass:water"
        publish_ha_sensor "Head Temperature" "head_temp" "head_temperature" \
            "temperature" "measurement" "\xc2\xb0C"
        publish_ha_sensor "Mix Temperature" "mix_temp" "mix_temperature" \
            "temperature" "measurement" "\xc2\xb0C"
        publish_ha_sensor "Steam Temperature" "steam_temp" \
            "steam_heater_temperature" \
            "temperature" "measurement" "\xc2\xb0C"
        publish_ha_sensor "Espresso Count" "espresso_count" "espresso_count" \
            {} "total_increasing" {} "hass:coffee"
        publish_ha_sensor "Steaming Count" "steaming_count" "steaming_count" \
            {} "total_increasing" {} "hass:sprinkler"

        # A switch to control the sleep/wake state
        publish_ha_switch

        publish_ha_profile_select
    }

    proc publish_ha_sensor {
        name
        entity_name
        field
        {device_class {}}
        {state_class {}}
        {unit_of_measurement {}}
        {icon {}}
    } {
        variable settings

        set device_id $settings(unique_id)
        set unique_id "de1plus_${device_id}_${entity_name}"
        set state_topic "$settings(topic_prefix)/state"

        # Build the config dict

        set config [common_ha_entity_settings]
        dict set config name [list str "$settings(ha_entity_name_prefix)$name"]
        dict set config unique_id [list str $unique_id]
        dict set config state_topic [list str $state_topic]
        dict set config value_template \
            [list str "\{\{ value_json.$field \}\}"]

        if {$device_class ne ""} {
            dict set config device_class [list str $device_class]
        }
        if {$state_class ne ""} {
            dict set config state_class [list str $state_class]
        }
        if {$unit_of_measurement ne ""} {
            dict set config unit_of_measurement [list str $unit_of_measurement]
        }
        if {$icon ne ""} {
            dict set config icon [list str $icon]
        }

        # Publish the message
        set msg [dict2json $config]
        set topic "$settings(ha_discovery_prefix)/sensor/${unique_id}/config"
        mqtt_client publish $topic $msg 1 1
    }

    proc publish_ha_switch {} {
        variable settings

        set device_id $settings(unique_id)
        set unique_id "de1plus_${device_id}_switch"

        set config [common_ha_entity_settings]
        dict set config name [list str "$settings(ha_entity_name_prefix)On"]
        dict set config unique_id [list str $unique_id]
        dict set config icon [list str "hass:coffee-maker"]
        dict set config state_topic [list str "$settings(topic_prefix)/state"]
        dict set config state_on {bool 1}
        dict set config state_off {bool 0}
        dict set config value_template \
            [list str "\{\{ value_json.wake_state \}\}"]
        dict set config command_topic \
            [list str "$settings(topic_prefix)/command"]
        dict set config payload_on {str "wake"}
        dict set config payload_off {str "sleep"}

        # Publish the message
        set msg [dict2json $config]
        set topic "$settings(ha_discovery_prefix)/switch/${unique_id}/config"
        mqtt_client publish $topic $msg 1 1
    }

    proc publish_ha_profile_select {} {
        variable settings

        set device_id $settings(unique_id)
        set unique_id "de1plus_${device_id}_profile_select"

        set config [common_ha_entity_settings]
        dict set config name \
            [list str "$settings(ha_entity_name_prefix)Profile"]
        dict set config unique_id [list str $unique_id]
        dict set config command_topic \
            [list str "$settings(topic_prefix)/command"]
        dict set config command_template \
            [list str "profile \{\{ value \}\}"]
        dict set config state_topic [list str "$settings(topic_prefix)/state"]
        dict set config value_template \
            [list str "\{\{ value_json.profile \}\}"]
        dict set config icon [list str "hass:chart-bell-curve"]

        set profile_list [build_profile_list_json]
        dict set config options [list list $profile_list]

        # Publish the message
        set msg [dict2json $config]
        set topic "$settings(ha_discovery_prefix)/select/${unique_id}/config"
        mqtt_client publish $topic $msg 1 1
    }

    proc build_profile_list_json {} {
        set results {}

        set profiles [get_profile_filenames]
        foreach fn $profiles {
            set full_fn "[homedir]/profiles/${fn}.tcl"
            unset -nocomplain profile
            catch {
                array set profile \
                [encoding convertfrom utf-8 [read_binary_file $full_fn]]
            }
            if {[info exists profile(profile_title)]} {
                set encoded [encoding convertto utf-8 $profile(profile_title)]
                lappend results [list str $encoded]
            }
        }

        return $results
    }

    proc common_ha_entity_settings {} {
        variable settings

        set config ""

        # The availability information is the same for all entities
        set avail ""
        dict set avail topic [list str "$settings(topic_prefix)/state"]
        dict set avail payload_available {bool 1}
        dict set avail payload_not_available {bool 0}
        dict set avail value_template \
            [list str "\{\{ value_json.de1_connected \}\}"]

        dict set config availability [list "dict" $avail]
        dict set config device [list "dict" [ha_device_info]]
        return $config
    }

    proc ha_device_info {} {
        variable settings

        set device_info ""

        set model_name [de_model_name]
        if {$model_name ne ""} {
            dict set device_info model [list str $model_name]
        }

        dict set device_info name [list str $settings(ha_device_name)]
        dict set device_info manufacturer {str "Decent Espresso"}
        set app_version [package version de1app]
        if {[info exists ::settings(firmware_version_number)]} {
            set fw_version $::settings(firmware_version_number)
            append app_version ", fw=$fw_version"
        }
        dict set device_info sw_version [list str $app_version]
        set ids_list {}
        lappend ids_list [list "str" $settings(unique_id)]
        dict set device_info identifiers [list "list" $ids_list]
        set conns {}
        if {[info exists ::settings(bluetooth_address)]} {
            if {$::settings(bluetooth_address) ne ""} {
                set conn_tuple [list \
                    [list "str" "mac"] \
                    [list "str" $::settings(bluetooth_address)] \
                ]
                lappend conns [list "list" $conn_tuple]
            }
        }
        dict set device_info connections [list "list" $conns]

        return $device_info
    }

    proc de_model_name {} {
	set model_names [dict create \
            1 DE1 2 DE1+ 3 DE1PRO 4 DE1XL 5 DE1CAFE 6 DE1XXL 7 DE1XXXL \
        ]
	if {[info exists ::settings(machine_model)]} {
            set model_id $::settings(machine_model)
            if {[dict exists $model_names $model_id]} {
                return [dict get $model_names $model_id]
            }
        }
        return {}
    }

    proc on_command {topic data retain} {
        if {[catch {process_command $topic $data $retain} result]} {
            msg -ERROR "bug processing MQTT command: $result"
        }
    }

    proc process_command {topic data retain} {
        if {$data eq "wake"} {
            set current_state $::de1_num_state($::de1(state))
            if {$current_state == "Sleep" || \
                $current_state == "GoingToSleep"} {
                msg "wake: waking up"
                start_idle

                # Use `borg alarm wakeup` to attempt to turn on the tablet
                # display.  We send this to the "self" component, which
                # will invoke our on_intent callback.  This seems to work
                # to turn the display on in my limited testing, but I'm not
                # sure if it's 100% reliable.
                borg alarm wakeup 1 0 "action.wakeup" \
                    {} {} {} "self"
            } else {
                msg "wake: already awake"
            }
        } elseif {$data eq "sleep"} {
            set current_state $::de1_num_state($::de1(state))
            if {$current_state == "Idle"} {
                msg "sleep: going to sleep"
                start_sleep
            } elseif {$current_state == "Sleep" || \
                $current_state == "GoingToSleep"} {
                msg "sleep: already sleeping"
            } else {
                msg "sleep: machine in use ($current_state); not sleeping"
            }
        } elseif {[string match {profile_filename *} $data]} {
            # Set profile by filename.
            set profile_fn \
                [string range $data [string length {profile_filename }] end]
            set full_fn "[homedir]/profiles/${profile_fn}.tcl"
            if {[file isfile $full_fn]} {
                msg "setting profile to '$profile_fn'"
                select_profile $profile_fn
            } else {
                msg "ignoring set profile_filename command: no file named" \
                    "\"$profile_fn\""
            }
        } elseif {[string match {profile *} $data]} {
            # Set profile by title.  We have to search through the profile
            # files to find one with this title.
            set argument \
                [string range $data [string length {profile }] end]
            set profile_name [encoding convertfrom utf-8 $argument]
            set profiles [get_profile_filenames]
            foreach fn $profiles {
		set full_fn "[homedir]/profiles/${fn}.tcl"
		unset -nocomplain profile
                catch {
                    array set profile \
                    [encoding convertfrom utf-8 [read_binary_file $full_fn]]
                }
		if {[info exists profile(profile_title)]} {
                    if {$profile(profile_title) eq $profile_name} {
                        msg "setting profile to \"$profile_name\" ($fn)"
                        select_profile $fn
                        return
                    }
                }
            }
            msg "ignoring set profile command: no profile found with the" \
                "title \"$profile_name\""
        } else {
            msg "unknown MQTT command: $data"
        }
    }

    proc on_intent {args} {
        # This method exists purely to handle the borg alarm wakeup we schedule
        # above.  We don't do anything here, we only want the alarm to attempt
        # to wake the tablet display.
    }

    proc json_quote_str {value} {
        set value [string map {"\\" "\\\\" "\"" "\\\""} $value]
        return "\"$value\""
    }

    # Androwish ships with a json package that provides a dict2json
    # function, but it doesn't handle empty strings.  In general serializing
    # JSON requires knowing data type information, so this version accepts
    # dicts where each value is a 2-tuple of {type, data}
    proc dict2json {data} {
        set json ""
        set sep ""
        foreach {key value_info} [lsort -stride 2 $data] {
            append json "$sep[json_quote_str $key]: [value2json $value_info]"
            set sep ", "
        }
        return "{$json}"
    }

    proc list2json {data} {
        set json ""
        set sep ""
        foreach {value_info} $data {
            append json "$sep[value2json $value_info]"
            set sep ", "
        }
        return "\[$json\]"
    }

    proc value2json {value_info} {
        lassign $value_info type value
        switch -- $type {
            "str" { return [json_quote_str $value] }
            "bool" { return [expr $value ? "true" : "false"] }
            "num" { return $value }
            "null" { return "null" }
            "dict" { return [dict2json $value] }
            "list" { return [list2json $value] }
            default { error "Unknown JSON type \"$type\"" }
        }
    }

    proc publish_state {} {
        variable settings
        variable mqtt_client

        set state ""
        dict set state online {bool true}

	if {$::de1(device_handle) == 0} {
            # The tablet cannot connect to the DE1
            dict set state de1_connected {bool false}
        } else {
            dict set state de1_connected {bool true}
            dict set state scale_connected \
                [list bool [expr {$::de1(scale_device_handle) != 0}]]
            dict set state state [list str $::de1_num_state($::de1(state))]
            dict set state substate \
                [list str $::de1_substate_types($::de1(substate))]
            dict set state profile \
                [list str [encoding convertto utf-8 $::settings(profile)]]
            dict set state profile_filename \
                [list str $::settings(profile_filename)]
            dict set state espresso_count [list num $::settings(espresso_count)]
            dict set state steaming_count [list num $::settings(steaming_count)]
            dict set state head_temperature [list num $::de1(head_temperature)]
            dict set state mix_temperature [list num $::de1(mix_temperature)]
            dict set state steam_heater_temperature \
                [list num $::de1(steam_heater_temperature)]
            dict set state water_level_mm [list num $::de1(water_level)]
            dict set state water_level_ml \
                [list num [water_tank_level_to_milliliters $::de1(water_level)]]

            # The wake_state reports if the DE1 is currently asleep or awake.
            # Providing this as a boolean makes it easier to integrate as a
            # switch in home assistant.
            dict set state wake_state \
                [list bool [expr {$::de1_num_state($::de1(state)) ne "Sleep"}]]
        }

        set json_state [::plugins::mqtt::dict2json $state]

        mqtt_client publish "$settings(topic_prefix)/state" $json_state 1 1
    }

    proc on_state_change {event_dict} {
        force_immediate_publish
    }

    proc on_profile_change {args} {
        variable settings

        if {$settings(ha_auto_discovery_enable)} {
            # Re-publish the profile select configuration any time the profile
            # changes, just to help keep the list of available profiles
            # up-to-date if someone has added or deleted profiles.
            publish_ha_profile_select
        }

        force_immediate_publish
    }

    proc force_immediate_publish {} {
        variable client_started
        variable publish_timer_id
        variable settings

        after cancel $publish_timer_id
        if { $client_started == 0 } {
            return
        }

        publish_state
        set publish_timer_id \
            [after $settings(publish_interval_ms) \
            ::plugins::mqtt::force_immediate_publish]
    }

    proc create_socket {args} {
        variable settings
        set channel [socket {*}$args]
        if { $settings(enable_tls) } {
            tls::import $channel \
                -cafile $settings(ca_file) \
                -certfile $settings(client_cert) \
                -keyfile $settings(client_key) \
                -command ::plugins::mqtt::tls_callback
        }
        return $channel
    }

    # We have to define our own custom TLS callback if we want to perform
    # server certificate verification.
    proc tls_callback {option args} {
        variable current_status
        variable settings

        switch -- $option {
            "error" {
                lassign $args channel error_msg
                msg -ERROR "TLS error: $error_msg"
                set current_status "TLS error: $error_msg"
            }
            "verify" {
                lassign $args channel depth cert status err
                if { $settings(ca_file) == "" } {
                    msg "No CA file defined.  " \
                        "Skipping TLS server certificate verification"
                    return 1
                }
                return $status
            }
            "info" {
                # lassign $args channel major minor msg
            }
            default {
                msg -WARN "unknown option in MQTT TLS callback: $option"
            }
        }
    }

    proc apply_settings_changes {} {
        variable client_started
        variable publish_timer_id
        variable settings

        save_plugin_settings mqtt

        after cancel $publish_timer_id
        set publish_timer_id {}
        if {$client_started != 0} {
            msg "closing existing MQTT client"
            # Calling "mqtt_client destroy" will gracefully disconnect the
            # client, which means our last will message will not be processed
            # by the broker, so we have to explicitly send it.
            set dead_state {{"online": false, "de1_connected": false}}
            mqtt_client publish "$settings(topic_prefix)/state" $dead_state 1 1
            set client_started 0
            # Ideally we should wait for the broker to acknowledge the message
            # before we send the disconnect.  Unfortunately this is a bit
            # awkward to do, so we simply wait for 50ms.
            #
            # Alternatively, it would be nice if the mqtt package had a way to
            # destroy the client without sending the DISCONNECT message, so
            # that our will message was processed by the broker.  The mqtt
            # package currently does not provide an option for this.
            after 50 ::plugins::mqtt::finish_client_destroy
        } else {
            start_client
        }
    }

    proc finish_client_destroy {} {
        mqtt_client destroy
        start_client
    }

    proc start_client {} {
        variable current_status
        variable client_started
        variable settings

        if { $settings(host) eq "" } {
            msg "MQTT plugin loaded, " \
                "but disabled because no broker host configured"
            set current_status "Disabled: no broker host configured"
            return
        }
        set current_status "Connecting..."
        set dead_state {{"online": false, "de1_connected": false}}

        # MQTT requires the client to publish packets periodically for
        # keepalive purposes.  The tcl mqtt package will send PINGREQ packets
        # on its own if we don't publish anything within the keepalive
        # interval.  However, it's better for us to just publish a state update
        # rather than sending an empty PINGREQ packet with no state data.
        #
        # Therefore set the keepalive setting slightly higher than our publish
        # interval so that the tcl mqtt package won't ever need to send its
        # own PINGREQ packets.
        set keepalive_sec [expr ($settings(publish_interval_ms) + 3000) / 1000]

        mqtt create mqtt_client \
            -username $settings(user) -password $settings(password) \
            -keepalive $keepalive_sec -retransmit $settings(retransmit_ms) \
           -socketcmd ::plugins::mqtt::create_socket
        set client_started 1
        mqtt_client will "$settings(topic_prefix)/state" $dead_state 1 1
        msg "Connecting to MQTT broker $settings(host):$settings(port) " \
            "as $settings(client_id)"
        mqtt_client connect $settings(client_id) \
            $settings(host) $settings(port)

        mqtt_client subscribe {$SYS/local/connection} \
            ::plugins::mqtt::on_conn_event
        mqtt_client subscribe "$settings(topic_prefix)/command" \
            ::plugins::mqtt::on_command
    }

    proc populate_initial_settings {} {
        variable settings
        set updated_settings 0

        # We generate a unique ID to avoid conflicts if there are multiple
        # DE1+ devices.  On first start-up this value is generally empty, so we
        # pick a new value then save it to the settings.
        if {$settings(unique_id) eq ""} {
            set rand_id [expr int(0xffffffff * rand())]
            set unique_id [format "%08x" $rand_id]
            set settings(unique_id) $unique_id
            set updated_settings 1
        }
        if {$settings(topic_prefix) eq ""} {
            set settings(topic_prefix) "de1plus/$settings(unique_id)"
            set updated_settings 1
        }
        if {$settings(client_id) eq ""} {
            set settings(client_id) "de1plus_$settings(unique_id)"
            set updated_settings 1
        }

        # Set the device name
        if {$settings(ha_device_name) eq ""} {
            set model_name [de_model_name]
            if {$model_name ne ""} {
                set settings(ha_device_name) "Decent Espresso $model_name"
            } else {
                set settings(ha_device_name) "Decent Espresso DE1+"
            }
            set updated_settings 1
        }

        if {$updated_settings} {
            save_plugin_settings mqtt
        }
    }

    proc main {} {
        package require mqtt
        package require tls

        msg "Enabling MQTT plugin"
        plugins gui mqtt [build_settings_ui]
        borg onintent ::plugins::mqtt::on_intent
        populate_initial_settings

        start_client

	::de1::event::listener::on_all_state_change_add \
            ::plugins::mqtt::on_state_change
        trace add variable ::settings(profile) write \
            ::plugins::mqtt::on_profile_change
    }
}
