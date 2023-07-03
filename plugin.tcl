
# Change package name for you extension / plugin
set plugin_name "mqtt"

namespace eval ::plugins::${plugin_name} {

    # These are shown in the plugin selection page
    variable author "Adam Simpkins"
    variable contact "adam@adamsimpkins.net"
    variable version 0.1
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

        # Warning if TLS is enabled with no cert validation
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

        # TODO: future use to support publishing auto-discovery messages
        if {0} {
            add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
                -width $label_width -anchor "e" -justify "right" \
                -text "Enable HomeAssistant Auto-Discovery"
            add_de1_widget $page_name checkbutton $col1_label_x $col1_y \
                {} \
                -variable ::plugins::mqtt::settings(enable_tls) \
                -foreground #4e85f4 -bg #ffffff -activebackground #ffffff \
                -canvas_anchor "w" -relief flat -borderwidth 0 \
                -highlightthickness 0 -highlightcolor #000000 
            set col1_y [expr $col1_y + $y_spacing]
        }

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
                "Certificate validation is disabled. " \
                "Upload a CA file to enable validation."
            ]
        }
        return ""
    }

    # Helper function that prefixes our plugin name to all messages
    # we log in this namespace.
    proc msg {args} {
        set first_arg [lindex $args 0]
        if { [string index $first_arg 0] == {-} } {
            ::msg $first_arg [namespace current] [lrange $args 1 end]
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
            after 1 ::::plugins::mqtt::force_immediate_publish
            set current_status "Connected"
        } else {
            # The mqtt2.0 package in the version of Androwish currently
            # shipping with DE1 unfortunately does not seem to send connection
            # status updates for most errors, so this unfortunately does not
            # let us record the error reason properly in most cases.
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

    proc on_command {topic data retain} {
        switch -- $data {
            "wake" {
                set current_state $::de1_num_state($::de1(state))
                if {$current_state == "Sleep" || \
                    $current_state == "GoingToSleep"} {
                    msg "wake: waking up"
                    start_idle

                    # It would be nice if we could also turn on the tablet
                    # display if it was off.  This alarm wakeup call is an
                    # attempt to do that, but it doesn't seem to work and I
                    # haven't spent much time investigating how to wake the
                    # display from within Androwish.
                    borg alarm wakeup 1 0 "action.wakeup" \
                        {} {} {} "self"
                } else {
                    msg "wake: already awake"
                }
            }
            "sleep" {
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
            }
            default {
                msg "unknown MQTT command: $data"
            }
        }
    }

    proc on_intent {args} {
        msg "on intent"
    }

    proc on_wake {args} {
        msg "on wake"
    }

    proc json_quote_str {value} {
        set value [string map {"\\" "\\\\" "\"" "\\\""} $value]
        return "\"$value\""
    }

    # Androwish ships with a json package that provides a dict2json
    # function, but it doesn't handle empty strings.  In general serializing
    # JSON requires knowing data type information, so this version accepts
    # dicts where each value is a 2-tuple of {type, data}
    proc dict2json { data } {
        set json ""
        set sep ""
        foreach {key value_info} [lsort -stride 2 $data] {
            lassign $value_info type value
            append json "$sep[json_quote_str $key]: "
            switch -- $type {
                "str" { append json [json_quote_str $value] }
                "bool" { append json [expr $value ? "true" : "false"] }
                "num" { append json $value }
                "null" { append json "null" }
                "dict" { append json [dict2json $value] }
                default { error "Unknown JSON type \"$value\"" }
            }
            set sep ", "
        }
        return "{$json}"
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
            dict set state profile [list str $::settings(profile_title)]
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
    # server certificate validation.
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
        set keepalive_sec [expr ($settings(publish_interval_ms) + 10000) / 1000]

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

    proc main {} {
        package require mqtt
        package require tls

        msg "Enabling MQTT plugin"
        plugins gui mqtt [build_settings_ui]
        borg onintent ::plugins::mqtt::on_intent

        start_client

	::de1::event::listener::on_all_state_change_add \
            ::plugins::mqtt::on_state_change
    }
}
