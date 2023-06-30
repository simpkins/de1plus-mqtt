
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
        add_de1_text $page_name 1280 1310 -text [translate "Done"] -font Helv_10_bold -fill "#fAfBff" -anchor "center"
        add_de1_button $page_name {say [translate {Done}] $::settings(sound_button_in); page_to_show_when_off extensions}  980 1210 1580 1410 ""

        # Headline
        add_de1_text $page_name 1280 300 -text [translate "MQTT Plugin"] -font Helv_20_bold -width 1200 -fill "#444444" -anchor "center" -justify "center"

        # The actual content. Here a list of all settings for this plugin
        set content_textfield [add_de1_text $page_name 600 380 -text  "" -font global_font -width 600 -fill "#444444" -anchor "nw" -justify "left" ]
        set description ""
        set description "$description\nBroker: $settings(host):$settings(port)"
        set description "$description\nClient Name: $settings(client_name)"
        set description "$description\nUser Name: $settings(user)"
        set description "$description\nTopic Prefix: $settings(topic_prefix)"
        if { $settings(ca_file) ne "" } {
            set description "$description\nTLS: Enabled"
            if { $settings(verify_server_certificate) == 0 } {
                set description "$description\nVerify Server Certificate: No"
            } else {
                set description "$description\nVerify Server Certificate: Yes"
            }
            if { $settings(client_cert) ne "" && $settings(client_key) ne "" } {
                set description "$description\nClient Certificate: Set"
            } else {
                set description "$description\nClient Certificate: Not in use"
            }
        } else {
            set description "$description\nTLS: Disabled"
        }
        .can itemconfigure $content_textfield -text $description

        add_de1_variable $page_name 1450 720 -font Helv_8 -width 400 -fill "#4e85f4" -anchor "nw" -justify "left" -textvariable {$::plugins::mqtt::current_status}

        return $page_name
    }

    proc on_conn_event {topic data retain} {
        variable mqtt_client
        variable current_status
        # Republish our status each time we reconnect
        if {[dict get $data state] eq "connected"} {
            msg [namespace current] "mqtt connected"
            # Publishing directly inside a CONNACK event callback unfortunately
            # doesn't work, since the mqtt library hasn't stored the fd yet,
            # and it just drops the publish message.  Therefore use an after
            # call to schedule this publish.
            after 1 ::::plugins::mqtt::publish_state
            set current_status "Connected"
        } else {
            # The mqtt2.0 package in the version of Androwish currently
            # shipping with DE1 unfortunately does not seem to send connection
            # status updates for most errors, so this unfortunately does not
            # let us record the error reason properly in most cases.
            msg [namespace current] "mqtt connection status: $data"

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
            msg [namespace current] "mqtt connection status: $current_status"
        }
    }

    proc on_command {topic data retain} {
        switch -- $data {
            "wake" {
                set current_state $::de1_num_state($::de1(state))
                if {$current_state == "Sleep" || \
                    $current_state == "GoingToSleep"} {
                    msg [namespace current] "MQTT wake: waking up"
                    start_idle
                    borg alarm wakeup 1 0 ::plugins::mqtt::on_wake
                } else {
                    msg [namespace current] "MQTT wake: already awake"
                }
            }
            "sleep" {
                set current_state $::de1_num_state($::de1(state))
                if {$current_state == "Idle"} {
                    msg [namespace current] "MQTT sleep: going to sleep"
                    start_sleep
                } elseif {$current_state == "Sleep" || \
                    $current_state == "GoingToSleep"} {
                    msg [namespace current] "MQTT sleep: already sleeping"
                } else {
                    msg [namespace current] \
                        "MQTT sleep: machine in use ($current_state);" \
                        "not sleeping"
                }
            }
            default {
                msg [namespace current] "unknown MQTT command: $data"
            }
        }
    }

    proc on_wake {args} {
        msg [namespace current] "on wake"
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
            if { $type eq "str" } {
                append json "[json_quote_str $value]"
            } elseif { $type eq "bool" || $type eq "num" } {
                append json "$value"
            } elseif { $type eq "null" } {
                append json "null"
            } elseif { $type eq "dict" } {
                append json [dict2json $value]
            } else {
                error "Unknown JSON type \"$value\""
            }
            set sep ", "
        }
        return "{$json}"
    }

    proc publish_state {} {
        variable settings
        variable mqtt_client

        # Androwish ships with a json package that provides a dict2json
        # function, but it doesn't handle empty strings.  In general
        # translating from tcl to json generically is hard without some
        # external knowledge of the data types.  Therefore just manually build
        # our json state.

        set state ""
        dict set state online {bool true}
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

        # TODO: report last ping state
	# dict set state connected [expr {$::de1(device_handle) != 0}]
	# dict set state last_ping [expr {[clock seconds] - $::de1(last_ping)}]
	# dict set state scale_connected [expr {$::de1(scale_device_handle) != 0}]

        set json_state [::plugins::mqtt::dict2json $state]

        mqtt_client publish "$settings(topic_prefix)/state" $json_state 1 1
    }

    proc on_state_change {event_dict} {
        ::plugins::mqtt::publish_state
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
                lassign $args channel msg
                msg -ERROR "MQTT TLS error: $msg"
                set current_status "TLS error: $msg"
            }
            "verify" {
                # TLS certificate verification is unfortunately disabled by
                # default.  Specifying this command callback enables it.
                lassign $args channel depth cert status err
                if { $settings(verify_server_certificate) == 0 } {
                    msg [namespace current]
                        "proceeding with invalid TLS server certificate"
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

        set dead_state {{"online": false}}

        msg [namespace current] "Enabling MQTT plugin"
        mqtt create mqtt_client \
            -username $settings(user) -password $settings(password) \
            -keepalive $settings(keepalive) -retransmit $settings(retransmit) \
           -socketcmd ::plugins::mqtt::create_socket
        mqtt_client will "$settings(topic_prefix)/state" $dead_state 1 1
        msg [namespace current] "Connecting to MQTT broker $settings(host):$settings(port) as $settings(client_name)"
        mqtt_client connect $settings(client_name) $settings(host) $settings(port)

        mqtt_client subscribe {$SYS/local/connection} ::plugins::mqtt::on_conn_event
        mqtt_client subscribe "$settings(topic_prefix)/command" ::plugins::mqtt::on_command

	::de1::event::listener::on_all_state_change_add ::plugins::mqtt::on_state_change

        # register settings gui
        plugins gui mqtt [build_ui]
    }
}
