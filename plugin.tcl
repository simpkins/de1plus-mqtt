
# Change package name for you extension / plugin
set plugin_name "mqtt"

namespace eval ::plugins::${plugin_name} {

    # These are shown in the plugin selection page
    variable author "Adam Simpkins"
    variable contact "adam@adamsimpkins.net"
    variable version 1.3
    variable description "Report events and allow control via MQTT."
    variable name "MQTT Integration"
    variable current_status "Not connected"
    variable client_started 0
    variable publish_timer_id {}
    variable supports_mqtt5 0
    variable published_ha_auto_discovery 0

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
            "say {[translate $next_page_name]} $::settings(sound_button_in);" \
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
        variable supports_mqtt5

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

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "e" -justify "right" \
            -text "MQTT Version"
        add_de1_widget $page_name radiobutton $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 5 -canvas_anchor "w" -anchor "w" \
            -borderwidth 0 -bg #ffffff  -foreground #4e85f4 \
            -text "3.1" -value 3 \
            -variable ::plugins::mqtt::settings(mqtt_protocol) \
            -relief flat  -highlightthickness 0 -highlightcolor #000000 
        add_de1_widget $page_name radiobutton \
            [expr $col1_label_x + 200] $col1_y \
            {} \
            -font Helv_8 -width 5 -canvas_anchor "w" -anchor "w" \
            -borderwidth 0 -bg #ffffff  -foreground #4e85f4 \
            -text "3.1.1" -value 4 \
            -variable ::plugins::mqtt::settings(mqtt_protocol) \
            -relief flat  -highlightthickness 0 -highlightcolor #000000 
        if {$supports_mqtt5} {
            add_de1_widget $page_name radiobutton \
                [expr $col1_label_x + 400] $col1_y \
                {} \
                -font Helv_8 -width 5 -canvas_anchor "w" -anchor "w" \
                -borderwidth 0 -bg #ffffff  -foreground #4e85f4 \
                -text "5" -value 5 \
                -variable ::plugins::mqtt::settings(mqtt_protocol) \
                -relief flat  -highlightthickness 0 -highlightcolor #000000 
        }
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

    proc on_conn_event {topic data retain {properties {}}} {
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
        variable published_ha_auto_discovery

        send_ha_discovery_messages 1
        set published_ha_auto_discovery 1
    }

    proc retract_ha_discovery_messages {} {
        variable published_ha_auto_discovery

        send_ha_discovery_messages 0
        set published_ha_auto_discovery 0
    }

    proc send_ha_discovery_messages {publish} {
        msg "sending HomeAssistant discovery messages"

        # Sensors
        send_ha_sensor $publish "State" "state" "state" {} {} {} \
            "hass:state-machine"
        send_ha_sensor $publish "Substate" "substate" "substate" {} {} {} \
            "hass:state-machine"
        send_ha_sensor $publish "Water Level" "water_level" "water_level_ml" \
            "volume_storage" "measurement" "mL" "hass:water"
        send_ha_sensor $publish "Head Temperature" "head_temp" \
            "head_temperature" "temperature" "measurement" "\xc2\xb0C"
        send_ha_sensor $publish "Mix Temperature" "mix_temp" \
            "mix_temperature" "temperature" "measurement" "\xc2\xb0C"
        send_ha_sensor $publish "Steam Temperature" "steam_temp" \
            "steam_heater_temperature" "temperature" "measurement" "\xc2\xb0C"
        send_ha_sensor $publish "Espresso Count" "espresso_count" \
            "espresso_count" {} "total_increasing" {} "hass:coffee"
        send_ha_sensor $publish "Steaming Count" "steaming_count" \
            "steaming_count" {} "total_increasing" {} "hass:sprinkler"

        # Only bother publishing the "Steam Mode" sensor if eco mode is
        # enabled.  For users that don't use eco mode (which is probably most
        # users), having this extra entity in addition to the simple Steam On
        # boolean will probably just be confusing
	if {[is_eco_steam_enabled] || ! $publish} {
            send_ha_sensor $publish "Steam Heater Mode" "steam_mode" \
                "steam_mode" {} {} {} "hass:heat-wave"
        }

        # Switches
        send_ha_switch $publish "On" "switch" "wake_state" \
            "wake" "sleep" "hass:coffee-maker"
        send_ha_switch $publish "Steam Heater On" "steam_switch" \
            "steam_state" "steam_on" "steam_off" "hass:heat-wave"


        send_ha_profile_select $publish
    }

    proc send_ha_sensor {
        publish
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
        set topic "$settings(ha_discovery_prefix)/sensor/${unique_id}/config"

        if {$publish} {
            # Build the config dict
            set config [common_ha_entity_settings]
            dict set config name \
                [list str "$settings(ha_entity_name_prefix)$name"]
            dict set config unique_id [list str $unique_id]
            set state_topic "$settings(topic_prefix)/state"
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
                dict set config unit_of_measurement \
                    [list str $unit_of_measurement]
            }
            if {$icon ne ""} {
                dict set config icon [list str $icon]
            }

            set msg [dict2json $config]

            mqtt_client publish $topic $msg 1 1
        } else {
            # Retract the retained information by publishing an empty message
            mqtt_client publish $topic {} 1 1
        }
    }

    proc send_ha_switch {
        publish
        name
        entity_name
        field
        on_command
        off_command
        {icon {}}
    } {
        variable settings

        set device_id $settings(unique_id)
        set unique_id "de1plus_${device_id}_${entity_name}"
        set topic "$settings(ha_discovery_prefix)/switch/${unique_id}/config"

        if {$publish} {
            set config [common_ha_entity_settings]
            dict set config name \
                [list str "$settings(ha_entity_name_prefix)$name"]
            dict set config unique_id [list str $unique_id]
            dict set config state_topic \
                [list str "$settings(topic_prefix)/state"]
            dict set config state_on {bool 1}
            dict set config state_off {bool 0}
            dict set config value_template \
                [list str "\{\{ value_json.$field \}\}"]
            dict set config command_topic \
                [list str "$settings(topic_prefix)/command"]
            dict set config payload_on [list str $on_command]
            dict set config payload_off [list str $off_command]
            if {$icon ne ""} {
                dict set config icon [list str $icon]
            }

            # Publish the message
            set msg [dict2json $config]
            mqtt_client publish $topic $msg 1 1
        } else {
            # Retract the message
            mqtt_client publish $topic {} 1 1
        }
    }

    proc publish_ha_profile_select {} {
        send_ha_profile_select 1
    }

    proc send_ha_profile_select {publish} {
        variable settings

        set device_id $settings(unique_id)
        set unique_id "de1plus_${device_id}_profile_select"
        set topic "$settings(ha_discovery_prefix)/select/${unique_id}/config"

        if {$publish} {
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
            mqtt_client publish $topic $msg 1 1
        } else {
            mqtt_client publish $topic {} 1 1
        }
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
            wake_if_needed "wake"
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
        } elseif {$data eq "steam_on"} {
            wake_if_needed "steam_on"
            if {$::settings(steam_disabled) || [is_eco_steam_on]} {
                msg "steam_on: turning steam on"
                set ::de1(in_eco_steam_mode) 0
                set ::settings(steam_disabled) 0
                set ::de1(steam_disable_toggle) 1
                reset_eco_steam_timer
                de1_send_steam_hotwater_settings
            } else {
                msg "steam_on: steam already on"
            }
        } elseif {$data eq "steam_off"} {
            if {! $::settings(steam_disabled)} {
                msg "steam_off: turning steam off"
                set ::settings(steam_disabled) 1
                set ::de1(steam_disable_toggle) 0
                de1_send_steam_hotwater_settings
            } else {
                msg "steam_off: steam already off"
            }
        } elseif {[string match {profile_filename *} $data]} {
            # Set profile by filename.
            set argument \
                [string range $data [string length {profile_filename }] end]
            set profile_fn [encoding convertfrom utf-8 $argument]
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

    proc wake_if_needed {cmd} {
        set current_state $::de1_num_state($::de1(state))
        if {$current_state == "Sleep" || \
            $current_state == "GoingToSleep"} {
            msg "$cmd: waking up"
            start_idle

            # Use `borg alarm wakeup` to attempt to turn on the tablet
            # display.  We send this to the "self" component, which
            # will invoke our on_intent callback.  This seems to work
            # to turn the display on in my limited testing, but I'm not
            # sure if it's 100% reliable.
            borg alarm wakeup 1 0 "action.wakeup" \
                {} {} {} "self"
        } else {
            msg "$cmd: already awake"
        }
    }

    proc reset_eco_steam_timer {} {
        # We just use delay_screen_saver to do this for now.
        # This resets both the eco steam timer and the screen saver timer.
        # It would be nicer if we had a method to reset just the eco steam
        # timer without affecting the screen saver timer, but it doesn't seem
        # like that big of a deal to reset the screen saver timer for now too.
	if {[is_eco_steam_enabled]} {
            delay_screen_saver
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

        set state ""
        dict set state online {bool true}

	if {$::de1(device_handle) == 0} {
            # The tablet cannot connect to the DE1
            dict set state de1_connected {bool false}
        } else {
            dict set state de1_connected {bool true}
            dict set state scale_connected \
                [list bool [expr {$::de1(scale_device_handle) != 0}]]
            dict set state state \
                [list str \
                [encoding convertto utf-8 $::de1_num_state($::de1(state))]]
            dict set state substate \
                [list str $::de1_substate_types($::de1(substate))]
            dict set state profile \
                [list str [encoding convertto utf-8 $::settings(profile)]]
            if [info exists ::settings(profile_filename)] {
                dict set state profile_filename \
                    [list str \
                    [encoding convertto utf-8 $::settings(profile_filename)]]
            }
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
            set is_awake [expr {$::de1_num_state($::de1(state)) ne "Sleep"}]
            dict set state wake_state [list bool $is_awake]

            # Report the steam mode / state.
            if {! $is_awake} {
                set steam_mode "Off"
                set steam_state 0
            } elseif {$::settings(steam_disabled)} {
                set steam_mode "Off"
                set steam_state 0
            } elseif {[is_eco_steam_on]} {
                set steam_mode "Eco"
                set steam_state 1
            } else {
                set steam_mode "On"
                set steam_state 1
            }
            dict set state steam_mode [list str $steam_mode]
            dict set state steam_state [list bool $steam_state]
        }

        set json_state [::plugins::mqtt::dict2json $state]

        mqtt_client publish "$settings(topic_prefix)/state" $json_state 1 1
    }

    proc on_state_change {event_dict} {
        force_immediate_publish
    }

    proc on_steam_state_change {args} {
        force_immediate_publish
    }

    proc on_steam_eco_setting_change {args} {
        variable settings

        # We only publish the steam_mode sensor when eco_steam is enabled,
        # so re-publish the HA sensors whenever it is turned on, in case we
        # never published it before.
        if {$settings(ha_auto_discovery_enable) && $::settings(eco_steam)} {
            # For simplicity just republish all sensors, rather than
            # adding a separate method for just this one sensor.
            publish_ha_discovery_messages
        }
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
        variable published_ha_auto_discovery

        save_plugin_settings mqtt

        after cancel $publish_timer_id
        set publish_timer_id {}
        if {$client_started != 0} {
            # If HA auto-discover was previously enabled and is now disabled,
            # retract our auto-discovery messages
            if {
                $published_ha_auto_discovery &&
                $settings(ha_auto_discovery_enable) == 0
            } {
                msg "retracting HA auto-discovery topics"
                retract_ha_discovery_messages
            }

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
            -protocol $settings(mqtt_protocol) \
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
        variable supports_mqtt5
        set updated_settings 0

        # We generate a unique ID to avoid conflicts if there are multiple
        # DE1+ devices.  On first start-up this value is generally empty, so we
        # pick a new value then save it to the settings.
        if {
            ! [info exists settings(unique_id)] || $settings(unique_id) == ""
        } {
            set rand_id [expr int(0xffffffff * rand())]
            set unique_id [format "%08x" $rand_id]
            set settings(unique_id) $unique_id
            set updated_settings 1
        }

        # Set the device name based on the model name
        if {! [info exists settings(ha_device_name)]} {
            set model_name [de_model_name]
            if {$model_name ne ""} {
                set settings(ha_device_name) "Decent Espresso $model_name"
            } else {
                set settings(ha_device_name) "Decent Espresso DE1+"
            }
            set updated_settings 1
        }

        # Default values for other settings
        array set defaults {
            host {}
            port 8883
            user {}
            password {}
            unique_id {}
            publish_interval_ms 60000
            retransmit_ms 5000
            enable_tls 1
            ca_file {}
            client_cert {}
            client_key {}
            ha_auto_discovery_enable 0
            ha_entity_name_prefix {DE1+ }
            ha_discovery_prefix {homeassistant}
        }
        set defaults(topic_prefix) "de1plus/$settings(unique_id)"
        set defaults(client_id) "de1plus_$settings(unique_id)"
        if {$supports_mqtt5} {
            set defaults(mqtt_protocol) 5
        } else {
            set defaults(mqtt_protocol) 4
        }

        foreach {name default_value} [array get defaults] {
            if {! [info exists settings($name)]} {
                set settings($name) $default_value
                set updated_settings 1
            }
        }

        if {$updated_settings} {
            save_plugin_settings mqtt
        }
    }

    proc is_eco_steam_enabled {} {
        # Provide compatibility with older versions of the de1plus
        # app which do not have the eco_steam setting.
        if {! [info exists ::settings(eco_steam)]} {
            return 0
        }
        return $::settings(eco_steam)
    }

    proc is_eco_steam_on {} {
        if {! [info exists ::de(in_eco_steam_mode)]} {
            return 0
        }
        return ::de1(in_eco_steam_mode)
    }

    proc main {} {
        variable supports_mqtt5

        set mqtt_pkg_version [package require mqtt]
        package require tls

        # Uncomment the following to enable logging from the mqtt package.
        # ::mqtt::logpfx { msg "mqtt==>" }

        msg "Enabling MQTT plugin: using Tcl mqtt $mqtt_pkg_version"
        # Set supports_mqtt5 to true if we are have mqtt package version 3.0
        # or higher
        set supports_mqtt5 [expr [package vcompare $mqtt_pkg_version 3.0] >= 0]

        populate_initial_settings
        plugins gui mqtt [build_settings_ui]
        borg onintent ::plugins::mqtt::on_intent

        start_client

	::de1::event::listener::on_all_state_change_add \
            ::plugins::mqtt::on_state_change
        trace add variable ::settings(profile) write \
            ::plugins::mqtt::on_profile_change
        trace add variable ::settings(steam_disabled) write \
            ::plugins::mqtt::on_steam_state_change
        trace add variable ::de1(in_eco_steam_mode) write \
            ::plugins::mqtt::on_steam_state_change
        trace add variable ::settings(eco_steam) write \
            ::plugins::mqtt::on_steam_eco_setting_change
    }
}
