import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: controlCenter

    anchors {
        top: true
        right: true
    }
    margins {
        top: 38
        right: 8
    }

    implicitWidth: 336
    implicitHeight: 530
    color: "#0a0a0a"
    visible: false

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "control-center"

    signal requestSettings()

    property bool wifiEnabled: false
    property string wifiSsid: "Disconnected"
    property bool btEnabled: false
    property bool airplaneMode: false
    property int currentBrightness: 50
    property int audioVolume: 0
    property bool audioMuted: false

    function toggle() {
        controlCenter.visible = !controlCenter.visible
        if (controlCenter.visible)
            pollState()
    }

    function localPath(fileName) {
        const resolved = Qt.resolvedUrl(fileName).toString()
        return resolved.startsWith("file://") ? decodeURIComponent(resolved.substring(7)) : resolved
    }

    function pollState() {
        statePoller.running = false
        statePoller.running = true
    }

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function pctText(value) {
        return Number.isFinite(value) ? Math.round(value) + "%" : "0%"
    }

    function setVolumeFromMouse(mouseX, trackWidth) {
        const pct = Math.round(clamp(mouseX / trackWidth, 0, 1) * 100)
        audioVolume = pct
        setVolume.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct + "%"]
        setVolume.running = false
        setVolume.running = true
        refreshSoon.restart()
    }

    function setBrightnessFromMouse(mouseX, trackWidth) {
        const pct = Math.round(clamp(mouseX / trackWidth, 0, 1) * 100)
        currentBrightness = pct
        setBrightness.command = ["brightnessctl", "set", pct + "%"]
        setBrightness.running = false
        setBrightness.running = true
        refreshSoon.restart()
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
        border.color: "#333333"
        border.width: 1
    }

    Process {
        id: statePoller
        command: ["sh", controlCenter.localPath("control_state.sh")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const state = JSON.parse(text.trim())
                    controlCenter.wifiEnabled = !!state.wifiEnabled
                    controlCenter.wifiSsid = state.wifiSsid || "Disconnected"
                    controlCenter.btEnabled = !!state.btEnabled
                    controlCenter.airplaneMode = !!state.airplaneMode
                    controlCenter.currentBrightness = controlCenter.clamp(Number(state.brightness) || 0, 0, 100)
                    controlCenter.audioVolume = controlCenter.clamp(Number(state.audioVolume) || 0, 0, 150)
                    controlCenter.audioMuted = !!state.audioMuted
                } catch(e) {
                    console.warn("Failed to parse control center state:", e)
                }
            }
        }
    }

    Timer { interval: 4000; running: true; repeat: true; onTriggered: controlCenter.pollState() }
    Timer { id: refreshSoon; interval: 700; repeat: false; onTriggered: controlCenter.pollState() }

    Process { id: toggleWifi; command: ["nmcli", "radio", "wifi", controlCenter.wifiEnabled ? "off" : "on"]; running: false }
    Process { id: toggleBt; command: ["rfkill", controlCenter.btEnabled ? "block" : "unblock", "bluetooth"]; running: false }
    Process { id: toggleAirplane; command: ["sh", "-c", controlCenter.airplaneMode ? "nmcli radio all on; rfkill unblock all" : "nmcli radio all off; rfkill block all"]; running: false }
    Process { id: toggleMute; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]; running: false }
    Process { id: setVolume; running: false }
    Process { id: setBrightness; running: false }
    Process { id: lockScreen; command: ["hyprlock"]; running: false }
    Process { id: openPowerMenu; command: ["wlogout"]; running: false }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: 8

            Text {
                text: "▲ TERMINAL NOIR"
                color: "#ffffff"
                font.family: "JetBrains Mono"
                font.bold: true
                font.pixelSize: 11
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
            }

            HeaderButton { icon: ""; onClicked: controlCenter.pollState() }
            HeaderButton { icon: ""; onClicked: controlCenter.requestSettings() }
            HeaderButton { icon: ""; onClicked: { openPowerMenu.running = false; openPowerMenu.running = true } }
        }

        GridLayout {
            columns: 2
            rowSpacing: 8
            columnSpacing: 8
            Layout.fillWidth: true
            Layout.preferredHeight: 164

            ControlTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                active: controlCenter.wifiEnabled
                icon: controlCenter.wifiEnabled ? "" : "󰤮"
                title: "Network"
                subtitle: controlCenter.wifiEnabled ? controlCenter.wifiSsid : "Off"
                onClicked: {
                    toggleWifi.running = false
                    toggleWifi.running = true
                    controlCenter.wifiEnabled = !controlCenter.wifiEnabled
                    refreshSoon.restart()
                }
            }

            ControlTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                active: controlCenter.btEnabled
                icon: ""
                title: "Bluetooth"
                subtitle: controlCenter.btEnabled ? "On" : "Off"
                onClicked: {
                    toggleBt.running = false
                    toggleBt.running = true
                    controlCenter.btEnabled = !controlCenter.btEnabled
                    refreshSoon.restart()
                }
            }

            ControlTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                active: !controlCenter.audioMuted && controlCenter.audioVolume > 0
                icon: controlCenter.audioMuted || controlCenter.audioVolume === 0 ? "󰝟" : ""
                title: "Audio"
                subtitle: controlCenter.audioMuted ? "Muted" : controlCenter.pctText(controlCenter.audioVolume)
                onClicked: {
                    toggleMute.running = false
                    toggleMute.running = true
                    controlCenter.audioMuted = !controlCenter.audioMuted
                    refreshSoon.restart()
                }
            }

            ControlTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                active: controlCenter.airplaneMode
                icon: ""
                title: "Airplane"
                subtitle: controlCenter.airplaneMode ? "On" : "Off"
                onClicked: {
                    toggleAirplane.running = false
                    toggleAirplane.running = true
                    controlCenter.airplaneMode = !controlCenter.airplaneMode
                    refreshSoon.restart()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 170
            color: "#0d0d0d"
            border.color: "#1c1c1c"
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    Text {
                        text: "0 NOTIFICATIONS"
                        color: "#888888"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 9
                        Layout.fillWidth: true
                    }
                    Text {
                        text: ""
                        color: "#888888"
                        font.pixelSize: 13
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: "#444444"
                        font.pixelSize: 36
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "No new notifications"
                    color: "#555555"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            spacing: 14

            SliderRow {
                Layout.fillWidth: true
                icon: controlCenter.audioMuted ? "󰝟" : ""
                value: controlCenter.clamp(controlCenter.audioVolume / 100, 0, 1)
                label: controlCenter.audioMuted ? "MUTE" : controlCenter.pctText(controlCenter.audioVolume)
                onDragged: (x, w) => controlCenter.setVolumeFromMouse(x, w)
            }

            SliderRow {
                Layout.fillWidth: true
                icon: "󰃠"
                value: controlCenter.currentBrightness / 100
                label: controlCenter.pctText(controlCenter.currentBrightness)
                onDragged: (x, w) => controlCenter.setBrightnessFromMouse(x, w)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 8

            FooterButton {
                icon: ""
                onClicked: { lockScreen.running = false; lockScreen.running = true }
            }
            FooterButton {
                icon: ""
                onClicked: controlCenter.requestSettings()
            }
            FooterButton {
                icon: ""
                onClicked: { openPowerMenu.running = false; openPowerMenu.running = true }
            }
        }
    }

    component HeaderButton: Rectangle {
        signal clicked()
        property string icon: ""
        width: 22
        height: 22
        color: mouse.containsMouse ? "#1c1c1c" : "transparent"
        border.color: "transparent"

        Text {
            anchors.centerIn: parent
            text: icon
            color: "#888888"
            font.pixelSize: 13
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component ControlTile: Rectangle {
        signal clicked()
        property bool active: false
        property string icon: ""
        property string title: ""
        property string subtitle: ""

        color: active ? "#e0e0e0" : "#101010"
        border.color: active ? "#e0e0e0" : "#333333"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: icon
                color: active ? "#000000" : "#888888"
                font.pixelSize: 18
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: title
                    color: active ? "#000000" : "#e0e0e0"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: subtitle
                    color: active ? "#333333" : "#888888"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component SliderRow: RowLayout {
        signal dragged(real mouseX, real trackWidth)
        property string icon: ""
        property real value: 0
        property string label: "0%"

        spacing: 12
        Text {
            text: icon
            color: "#888888"
            font.pixelSize: 15
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            height: 4
            color: "#1c1c1c"
            clip: true

            Rectangle {
                height: parent.height
                width: parent.width * Math.max(0, Math.min(1, value))
                color: "#e0e0e0"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: (mouse) => {
                    if (mouse.buttons & Qt.LeftButton)
                        dragged(mouse.x, width)
                }
                onPressed: (mouse) => dragged(mouse.x, width)
            }
        }

        Text {
            text: label
            color: "#888888"
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 42
        }
    }

    component FooterButton: Rectangle {
        signal clicked()
        property string icon: ""
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: mouse.containsMouse ? "#1c1c1c" : "#0d0d0d"
        border.color: "#1c1c1c"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: icon
            color: "#888888"
            font.pixelSize: 16
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
