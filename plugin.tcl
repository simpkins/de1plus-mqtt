
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

    proc build_ui {}  {
        variable settings

        # Unique name per page
        set page_name "plugin_mqtt_page_default"

        # Background image and "Done" button
        add_de1_page "$page_name" "settings_message.png" "default"
        add_de1_text $page_name 1280 1310 -text [translate "Done"] \
            -font Helv_10_bold -fill "#fAfBff" -anchor "center"
        # TODO: save and apply settings when done is clicked
        add_de1_button $page_name \
            { \
                say [translate {Done}] $::settings(sound_button_in); \
                page_to_show_when_off extensions \
            } \
            980 1210 1580 1410 ""

        # Headline
        add_de1_text $page_name 1280 300 \
            -text [translate "MQTT Settings"] -font Helv_20_bold \
            -width 1200 -fill "#444444" -anchor "center" -justify "center"

        set col1_x 315
        set col1_label_x 650
        set label_width 400
        set col2_x 1450

        set y_start 450
        set y_spacing 80

        set col1_y $y_start
        set col2_y $y_start

        #
        # Left Column: Settings
        #

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "nw" -justify "right" \
            -text "Broker Host"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(host) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "nw" -justify "right" \
            -text "Broker Port"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 10 \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(port) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "nw" -justify "right" \
            -text "Username"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(user) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "nw" -justify "right" \
            -text "Password"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(password) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "nw" -justify "right" \
            -text "Client Name"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(client_name) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        add_de1_text $page_name $col1_x $col1_y -font Helv_10_bold \
            -width $label_width -anchor "nw" -justify "right" \
            -text "Topic Prefix"
        add_de1_widget $page_name entry $col1_label_x $col1_y \
            {} \
            -font Helv_8 -width 30 \
            -borderwidth 1 -bg #fbfaff  -foreground #4e85f4 \
            -textvariable ::plugins::mqtt::settings(topic_prefix) \
            -relief flat  -highlightthickness 1 -highlightcolor #000000 
        set col1_y [expr $col1_y + $y_spacing]

        #
        # Right Column: Status
        #

        add_de1_text $page_name $col2_x $col2_y -font Helv_10_bold \
            -width $label_width -anchor "nw" -justify "right" \
            -text "Status:"
        set col2_y [expr $col2_y + $y_spacing]
        add_de1_variable $page_name $col2_x $col2_y \
            -font Helv_8 -width 400 \
            -anchor "nw" -justify "left" \
            -textvariable {$::plugins::mqtt::current_status}

        return $page_name
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
        variable mqtt_client
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
              2 {set reason_str "Client Name Rejected"}
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
        variable settings
        variable publish_timer_id

        after cancel $publish_timer_id
        ::plugins::mqtt::publish_state
        set publish_timer_id \
            [after [expr 1000 * $settings(publish_interval)] \
            ::plugins::mqtt::force_immediate_publish]
    }

    proc create_socket {args} {
        variable settings
        set channel [socket {*}$args]
        if { $settings(ca_file) ne "" } {
            tls::import $channel \
                -cafile $settings(ca_file) \
                -certfile $settings(client_cert) \
                -keyfile $settings(client_key) \
                -command ::plugins::mqtt::tls_callback
        }
        return $channel
    }

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
                # TLS certificate verification is unfortunately disabled by
                # default.  Specifying this command callback enables it.
                lassign $args channel depth cert status err
                if { $settings(verify_server_certificate) == 0 } {
                    msg "proceeding with invalid TLS server certificate"
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

    proc main {} {
        package require mqtt
        package require tls
        variable settings
        variable mqtt_client
        variable publish_timer_id

        set publish_timer_id {}
        set dead_state {{"online": false, "de1_connected": false}}

        msg "Enabling MQTT plugin"
        borg onintent ::plugins::mqtt::on_intent
        mqtt create mqtt_client \
            -username $settings(user) -password $settings(password) \
            -keepalive $settings(keepalive) -retransmit $settings(retransmit) \
           -socketcmd ::plugins::mqtt::create_socket
        mqtt_client will "$settings(topic_prefix)/state" $dead_state 1 1
        msg "Connecting to MQTT broker $settings(host):$settings(port) " \
            "as $settings(client_name)"
        mqtt_client connect $settings(client_name) \
            $settings(host) $settings(port)

        mqtt_client subscribe {$SYS/local/connection} \
            ::plugins::mqtt::on_conn_event
        mqtt_client subscribe "$settings(topic_prefix)/command" \
            ::plugins::mqtt::on_command

	::de1::event::listener::on_all_state_change_add \
            ::plugins::mqtt::on_state_change

        # register settings gui
        plugins gui mqtt [build_ui]
    }
}
