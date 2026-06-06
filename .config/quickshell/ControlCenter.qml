import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications

PanelWindow {
    id: controlCenter

    anchors {
        top: true
        right: true
    }
    margins {
        top: 0
        right: 0
    }

    implicitWidth: 336
    implicitHeight: detailPage === "" ? 640 : 760
    color: "#0a0a0a"
    visible: false
    onVisibleChanged: if (visible) panelRoot.forceActiveFocus()

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "control-center"
    WlrLayershell.keyboardFocus: controlCenter.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    signal requestSettings()

    property var settings: null
    property bool wifiEnabled: false
    property string wifiSsid: "Disconnected"
    property bool btEnabled: false
    property bool airplaneMode: false
    property int currentBrightness: 50
    property int audioVolume: 0
    property bool audioMuted: false
    property string userName: "user"
    property string hostName: "host"
    property var notifications: []
    property string detailPage: ""
    property bool wifiBusy: false
    property bool bluetoothBusy: false
    property bool bluetoothScanning: false
    property string wifiPassword: ""
    property string wifiStatus: ""
    property string bluetoothStatus: ""
    property var wifiNetworks: []
    property var bluetoothDevices: []

    function toggle() {
        if (controlCenter.visible) {
            controlCenter.closePanel()
            return
        }

        controlCenter.visible = true
        controlCenter.refreshVisibleState()
    }

    function closePanel() {
        controlCenter.detailPage = ""
        controlCenter.wifiPassword = ""
        controlCenter.visible = false
    }

    function openFromBar(page) {
        const targetDetail = page === "network" || page === "bluetooth" ? page : ""

        if (controlCenter.visible && controlCenter.detailPage === targetDetail) {
            controlCenter.closePanel()
            return
        }

        controlCenter.visible = true
        controlCenter.detailPage = targetDetail
        controlCenter.refreshVisibleState()
    }

    function detailsEnabled() {
        return !controlCenter.settings || controlCenter.settings.quickPanelDetailsEnabled
    }

    function openDetail(page) {
        if (!controlCenter.detailsEnabled())
            return false

        controlCenter.detailPage = page
        controlCenter.refreshVisibleState()
        return true
    }

    function refreshVisibleState() {
        controlCenter.pollState()
        if (controlCenter.detailPage === "network")
            controlCenter.refreshWifiDetails()
        else if (controlCenter.detailPage === "bluetooth")
            controlCenter.refreshBluetoothDetails()
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

    function refreshWifiDetails() {
        if (wifiState.running)
            wifiState.running = false
        controlCenter.wifiBusy = true
        wifiState.running = true
    }

    function runWifiAction(command, status) {
        controlCenter.wifiStatus = status
        controlCenter.wifiBusy = true
        wifiAction.command = command
        wifiAction.running = false
        wifiAction.running = true
    }

    function toggleWifiRadio() {
        const nextState = controlCenter.wifiEnabled ? "off" : "on"
        const command = nextState === "on" ? ["sh", "-c", "rfkill unblock wifi 2>/dev/null; nmcli radio wifi on"] : ["nmcli", "radio", "wifi", "off"]
        controlCenter.runWifiAction(command, nextState === "on" ? "Enabling Wi-Fi" : "Disabling Wi-Fi")
    }

    function connectWifi(ssid, password, saved, secured) {
        if (!ssid || ssid.length === 0)
            return
        if (secured && !saved && (!password || password.length === 0)) {
            controlCenter.wifiStatus = "Password required"
            return
        }

        const command = ["nmcli", "device", "wifi", "connect", ssid]
        if (password && password.length > 0) {
            command.push("password")
            command.push(password)
        }
        controlCenter.runWifiAction(command, saved ? "Connecting saved network" : "Connecting")
    }

    function disconnectWifi(ssid) {
        if (!ssid || ssid.length === 0)
            return
        controlCenter.runWifiAction(["nmcli", "connection", "down", ssid], "Disconnecting")
    }

    function forgetWifi(ssid) {
        if (!ssid || ssid.length === 0)
            return
        controlCenter.runWifiAction(["nmcli", "connection", "delete", ssid], "Forgetting network")
    }

    function refreshBluetoothDetails() {
        if (bluetoothState.running)
            bluetoothState.running = false
        controlCenter.bluetoothBusy = true
        bluetoothState.running = true
    }

    function runBluetoothAction(command, status) {
        controlCenter.bluetoothStatus = status
        controlCenter.bluetoothBusy = true
        bluetoothAction.command = command
        bluetoothAction.running = false
        bluetoothAction.running = true
    }

    function toggleBluetoothPower() {
        const nextState = controlCenter.btEnabled ? "off" : "on"
        const command = nextState === "on" ? ["sh", "-c", "rfkill unblock bluetooth 2>/dev/null; bluetoothctl power on"] : ["sh", "-c", "bluetoothctl power off; rfkill block bluetooth 2>/dev/null"]
        controlCenter.runBluetoothAction(command, nextState === "on" ? "Powering on" : "Powering off")
    }

    function scanBluetooth() {
        controlCenter.bluetoothStatus = "Scanning"
        controlCenter.bluetoothScanning = true
        bluetoothScanOn.running = false
        bluetoothScanOn.running = true
        bluetoothScanTimer.restart()
    }

    function connectBluetooth(mac) {
        if (!mac || mac.length === 0)
            return
        controlCenter.runBluetoothAction(["bluetoothctl", "connect", mac], "Connecting")
    }

    function disconnectBluetooth(mac) {
        if (!mac || mac.length === 0)
            return
        controlCenter.runBluetoothAction(["bluetoothctl", "disconnect", mac], "Disconnecting")
    }

    function pairBluetooth(mac) {
        if (!mac || mac.length === 0)
            return
        controlCenter.runBluetoothAction(["bluetoothctl", "pair", mac], "Pairing")
    }

    function linkBluetooth(mac) {
        if (!mac || mac.length === 0)
            return
        controlCenter.runBluetoothAction(["sh", "-c", "bluetoothctl pair \"$1\"; bluetoothctl trust \"$1\"; bluetoothctl connect \"$1\"", "sh", mac], "Linking")
    }

    function trustBluetooth(mac) {
        if (!mac || mac.length === 0)
            return
        controlCenter.runBluetoothAction(["bluetoothctl", "trust", mac], "Trusting")
    }

    function removeBluetooth(mac) {
        if (!mac || mac.length === 0)
            return
        controlCenter.runBluetoothAction(["bluetoothctl", "remove", mac], "Removing")
    }

    function dismissNotification(id) {
        const item = controlCenter.notifications.find(n => n.id === id)
        if (item && item.notification && item.notification.dismiss) {
            try {
                item.notification.dismiss()
            } catch(e) {
                console.warn("Failed to dismiss notification:", e)
            }
        }
        controlCenter.notifications = controlCenter.notifications.filter(n => n.id !== id)
    }

    function dismissAllNotifications() {
        for (let i = 0; i < controlCenter.notifications.length; i++) {
            const item = controlCenter.notifications[i]
            if (item && item.notification && item.notification.dismiss) {
                try {
                    item.notification.dismiss()
                } catch(e) {
                    console.warn("Failed to dismiss notification:", e)
                }
            }
        }
        controlCenter.notifications = []
    }

    function hideNotificationPopup(id) {
        controlCenter.notifications = controlCenter.notifications.map(n => {
            if (n.id !== id)
                return n

            const updated = Object.assign({}, n)
            updated.shownInPopup = false
            return updated
        })
    }

    function focusNotificationSource(item) {
        if (!item)
            return

        focusApp.command = ["sh", controlCenter.localPath("focus_notification_source.sh"), item.desktopEntry || "", item.appName || "", item.title || ""]
        focusApp.running = false
        focusApp.running = true
    }

    function openNotification(index) {
        const item = controlCenter.notifications[index]
        if (!item)
            return

        const notification = item.notification
        if (notification && notification.actions) {
            for (let i = 0; i < notification.actions.length; i++) {
                const action = notification.actions[i]
                if (action.identifier === "default") {
                    action.invoke()
                    controlCenter.dismissNotification(item.id)
                    return
                }
            }
        }

        controlCenter.focusNotificationSource(item)
        controlCenter.dismissNotification(item.id)
    }

    function openNotificationById(id) {
        const index = controlCenter.notifications.findIndex(n => n.id === id)
        if (index >= 0)
            controlCenter.openNotification(index)
    }

    Rectangle {
        id: panelRoot
        anchors.fill: parent
        color: "#0a0a0a"
        border.color: "#333333"
        border.width: 1
        focus: true
        Keys.onEscapePressed: {
            if (controlCenter.detailPage !== "")
                controlCenter.detailPage = ""
            else
                controlCenter.closePanel()
        }
    }

    Process {
        id: statePoller
        command: ["sh", controlCenter.localPath("control_state.sh")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rawState = text.trim()
                    if (!rawState.startsWith("{") || !rawState.endsWith("}"))
                        return

                    const state = JSON.parse(rawState)
                    controlCenter.userName = state.userName || "user"
                    controlCenter.hostName = state.hostName || "host"
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
    Process { id: lockScreen; command: ["hyprlock", "--immediate-render", "--no-fade-in"]; running: false }
    Process { id: openPowerMenu; command: ["wlogout"]; running: false }
    Process { id: focusApp; running: false }

    Process {
        id: wifiState
        command: ["sh", controlCenter.localPath("wifi_state.sh")]
        running: false
        onRunningChanged: if (!running) controlCenter.wifiBusy = false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rawState = text.trim()
                    if (!rawState.startsWith("{") || !rawState.endsWith("}"))
                        return

                    const state = JSON.parse(rawState)
                    controlCenter.wifiEnabled = !!state.enabled
                    controlCenter.wifiSsid = state.connectedSsid && state.connectedSsid.length > 0 ? state.connectedSsid : "Disconnected"
                    controlCenter.wifiNetworks = state.networks || []
                    controlCenter.wifiStatus = controlCenter.wifiNetworks.length > 0 ? "" : (controlCenter.wifiEnabled ? "No networks found" : "Wi-Fi is off")
                } catch(e) {
                    controlCenter.wifiStatus = "Could not read Wi-Fi state"
                    console.warn("Failed to parse Wi-Fi state:", e)
                }
                controlCenter.wifiBusy = false
            }
        }
    }

    Process {
        id: wifiAction
        running: false
        onRunningChanged: {
            if (!running) {
                controlCenter.wifiBusy = false
                controlCenter.wifiPassword = ""
                refreshSoon.restart()
                controlCenter.refreshWifiDetails()
            }
        }
    }

    Process {
        id: bluetoothState
        command: ["sh", controlCenter.localPath("bluetooth_state.sh")]
        running: false
        onRunningChanged: if (!running) controlCenter.bluetoothBusy = false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rawState = text.trim()
                    if (!rawState.startsWith("{") || !rawState.endsWith("}"))
                        return

                    const state = JSON.parse(rawState)
                    controlCenter.btEnabled = !!state.powered
                    controlCenter.bluetoothScanning = !!state.scanning
                    controlCenter.bluetoothDevices = state.devices || []
                    controlCenter.bluetoothStatus = controlCenter.bluetoothDevices.length > 0 ? "" : (controlCenter.btEnabled ? "No devices found" : "Bluetooth is off")
                } catch(e) {
                    controlCenter.bluetoothStatus = "Could not read Bluetooth state"
                    console.warn("Failed to parse Bluetooth state:", e)
                }
                controlCenter.bluetoothBusy = false
            }
        }
    }

    Process {
        id: bluetoothAction
        running: false
        onRunningChanged: {
            if (!running) {
                controlCenter.bluetoothBusy = false
                refreshSoon.restart()
                controlCenter.refreshBluetoothDetails()
            }
        }
    }

    Process { id: bluetoothScanOn; command: ["bluetoothctl", "scan", "on"]; running: false }
    Process {
        id: bluetoothScanOff
        command: ["bluetoothctl", "scan", "off"]
        running: false
        onRunningChanged: {
            if (!running) {
                controlCenter.bluetoothScanning = false
                controlCenter.refreshBluetoothDetails()
            }
        }
    }
    Timer {
        id: bluetoothScanTimer
        interval: 6500
        repeat: false
        onTriggered: {
            bluetoothScanOff.running = false
            bluetoothScanOff.running = true
        }
    }

    NotificationServer {
        id: notificationServer
        bodySupported: true
        imageSupported: true

        onNotification: (notification) => {
            const item = {
                id: notification.id ? notification.id.toString() : Date.now().toString(),
                notification: notification,
                appName: notification.appName || "System",
                desktopEntry: notification.desktopEntry || "",
                title: notification.summary || "Notification",
                body: notification.body || "",
                image: notification.image || notification.appIcon || "",
                shownInPopup: true
            }
            controlCenter.notifications = [item].concat(controlCenter.notifications).slice(0, 30)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: 8

            Text {
                text: "▲ " + controlCenter.userName + "@" + controlCenter.hostName
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
            HeaderButton { icon: ""; onClicked: controlCenter.closePanel() }
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
                    if (controlCenter.openDetail("network"))
                        return

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
                    if (controlCenter.openDetail("bluetooth"))
                        return

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
            Layout.preferredHeight: controlCenter.detailPage === "" ? 240 : 380
            color: "#0d0d0d"
            border.color: "#1c1c1c"
            border.width: 1
            clip: true

            Loader {
                anchors.fill: parent
                anchors.margins: 12
                sourceComponent: controlCenter.detailPage === "network" ? networkDetailView : (controlCenter.detailPage === "bluetooth" ? bluetoothDetailView : notificationsView)
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

    Component {
        id: notificationsView

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Text {
                    text: controlCenter.notifications.length + " NOTIFICATIONS"
                    color: "#888888"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 9
                    Layout.fillWidth: true
                }
                Text {
                    text: controlCenter.notifications.length > 0 ? "" : ""
                    color: "#888888"
                    font.pixelSize: 13
                    MouseArea {
                        anchors.fill: parent
                        enabled: controlCenter.notifications.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlCenter.dismissAllNotifications()
                    }
                }
            }

            Item {
                visible: controlCenter.notifications.length === 0
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
                visible: controlCenter.notifications.length === 0
                Layout.fillWidth: true
                text: "No new notifications"
                color: "#555555"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }

            ListView {
                id: notificationList
                visible: controlCenter.notifications.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: controlCenter.notifications

                delegate: Rectangle {
                    width: notificationList.width
                    height: Math.max(52, notificationText.implicitHeight + 20)
                    color: "#111111"
                    border.color: "#2a2a2a"
                    border.width: 1
                    property int sourceIndex: index

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            text: ""
                            color: "#888888"
                            font.pixelSize: 14
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                        }

                        ColumnLayout {
                            id: notificationText
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                color: "#e0e0e0"
                                font.family: "JetBrains Mono"
                                font.bold: true
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.body || modelData.appName
                                color: "#888888"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                maximumLineCount: 2
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlCenter.openNotification(sourceIndex)
                    }
                }
            }
        }
    }

    Component {
        id: networkDetailView

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            DetailHeader {
                title: "NETWORK"
                status: controlCenter.wifiBusy ? "working" : controlCenter.wifiStatus
                onBack: controlCenter.detailPage = ""
                onRefresh: controlCenter.refreshWifiDetails()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 8

                DetailButton {
                    label: controlCenter.wifiEnabled ? "Turn Off" : "Turn On"
                    active: controlCenter.wifiEnabled
                    Layout.preferredWidth: 86
                    onClicked: controlCenter.toggleWifiRadio()
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: "#090909"
                    border.color: passwordInput.activeFocus ? "#888888" : "#222222"
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        text: "password"
                        visible: passwordInput.text.length === 0
                        color: "#555555"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                    }

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        verticalAlignment: TextInput.AlignVCenter
                        text: controlCenter.wifiPassword
                        color: "#e0e0e0"
                        selectionColor: "#e0e0e0"
                        selectedTextColor: "#000000"
                        echoMode: TextInput.Password
                        clip: true
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        onTextChanged: controlCenter.wifiPassword = text
                    }
                }
            }

            ListView {
                id: wifiList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: controlCenter.wifiNetworks

                delegate: Rectangle {
                    width: wifiList.width
                    height: 60
                    color: modelData.connected ? "#e0e0e0" : (wifiMouse.containsMouse ? "#151515" : "#101010")
                    border.color: modelData.connected ? "#e0e0e0" : "#2a2a2a"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 8

                        Text {
                            text: modelData.connected ? "󰸞" : (modelData.secured ? "" : "")
                            color: modelData.connected ? "#000000" : "#888888"
                            font.pixelSize: 15
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: modelData.ssid
                                color: modelData.connected ? "#000000" : "#e0e0e0"
                                font.family: "JetBrains Mono"
                                font.bold: true
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (modelData.signal || 0) + "%  " + (modelData.security || "Open") + (modelData.saved ? "  saved" : "")
                                color: modelData.connected ? "#333333" : "#888888"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        DetailButton {
                            label: modelData.connected ? "Down" : "Join"
                            active: modelData.connected
                            Layout.preferredWidth: 48
                            onClicked: modelData.connected ? controlCenter.disconnectWifi(modelData.ssid) : controlCenter.connectWifi(modelData.ssid, controlCenter.wifiPassword, modelData.saved, modelData.secured)
                        }

                        DetailButton {
                            label: "Forget"
                            visible: modelData.saved
                            Layout.preferredWidth: 56
                            onClicked: controlCenter.forgetWifi(modelData.ssid)
                        }
                    }

                    MouseArea {
                        id: wifiMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothDetailView

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            DetailHeader {
                title: "BLUETOOTH"
                status: controlCenter.bluetoothBusy ? "working" : (controlCenter.bluetoothScanning ? "scanning" : controlCenter.bluetoothStatus)
                onBack: controlCenter.detailPage = ""
                onRefresh: controlCenter.refreshBluetoothDetails()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 8

                DetailButton {
                    label: controlCenter.btEnabled ? "Turn Off" : "Turn On"
                    active: controlCenter.btEnabled
                    Layout.preferredWidth: 86
                    onClicked: controlCenter.toggleBluetoothPower()
                }

                DetailButton {
                    label: controlCenter.bluetoothScanning ? "Scanning" : "Scan"
                    active: controlCenter.bluetoothScanning
                    Layout.preferredWidth: 74
                    onClicked: controlCenter.scanBluetooth()
                }

                Text {
                    Layout.fillWidth: true
                    text: controlCenter.bluetoothDevices.length + " devices"
                    color: "#888888"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            ListView {
                id: bluetoothList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: controlCenter.bluetoothDevices

                delegate: Rectangle {
                    width: bluetoothList.width
                    height: 66
                    color: modelData.connected ? "#e0e0e0" : (btMouse.containsMouse ? "#151515" : "#101010")
                    border.color: modelData.connected ? "#e0e0e0" : "#2a2a2a"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 8

                        Text {
                            text: modelData.connected ? "" : ""
                            color: modelData.connected ? "#000000" : "#888888"
                            font.pixelSize: 15
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || modelData.mac
                                color: modelData.connected ? "#000000" : "#e0e0e0"
                                font.family: "JetBrains Mono"
                                font.bold: true
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (modelData.paired ? "paired" : "new") + (modelData.trusted ? "  trusted" : "") + "  " + modelData.mac
                                color: modelData.connected ? "#333333" : "#888888"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        DetailButton {
                            label: modelData.connected ? "Disconnect" : (modelData.paired ? "Connect" : "Link")
                            active: modelData.connected
                            Layout.preferredWidth: modelData.connected ? 82 : (modelData.paired ? 68 : 46)
                            onClicked: modelData.connected ? controlCenter.disconnectBluetooth(modelData.mac) : (modelData.paired ? controlCenter.connectBluetooth(modelData.mac) : controlCenter.linkBluetooth(modelData.mac))
                        }

                        DetailButton {
                            label: modelData.paired ? "Trust" : "Pair"
                            visible: modelData.paired && !modelData.trusted
                            Layout.preferredWidth: 48
                            onClicked: modelData.paired ? controlCenter.trustBluetooth(modelData.mac) : controlCenter.pairBluetooth(modelData.mac)
                        }

                        DetailButton {
                            label: "Remove"
                            Layout.preferredWidth: 58
                            onClicked: controlCenter.removeBluetooth(modelData.mac)
                        }
                    }

                    MouseArea {
                        id: btMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
    }

    component DetailHeader: RowLayout {
        id: detailHeader

        signal back()
        signal refresh()
        property string title: ""
        property string status: ""

        Layout.fillWidth: true
        Layout.preferredHeight: 22
        spacing: 8

        Text {
            text: "‹"
            color: "#e0e0e0"
            font.family: "JetBrains Mono"
            font.bold: true
            font.pixelSize: 18
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: detailHeader.back()
            }
        }

        Text {
            Layout.fillWidth: true
            text: title
            color: "#e0e0e0"
            font.family: "JetBrains Mono"
            font.bold: true
            font.pixelSize: 10
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: status
            visible: status.length > 0
            color: "#666666"
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth: 120
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: ""
            color: "#888888"
            font.pixelSize: 12
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: detailHeader.refresh()
            }
        }
    }

    component DetailButton: Rectangle {
        signal clicked()
        property string label: ""
        property bool active: false

        Layout.preferredHeight: 28
        color: active ? "#e0e0e0" : (buttonMouse.containsMouse ? "#1a1a1a" : "#0a0a0a")
        border.color: active ? "#e0e0e0" : "#2a2a2a"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: label
            color: active ? "#000000" : "#e0e0e0"
            font.family: "JetBrains Mono"
            font.bold: true
            font.pixelSize: 9
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
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

        Item {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Rectangle {
                id: rail
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                color: "#1c1c1c"
            }

            Rectangle {
                anchors.left: rail.left
                anchors.verticalCenter: rail.verticalCenter
                height: rail.height
                width: rail.width * Math.max(0, Math.min(1, value))
                color: "#e0e0e0"
            }

            Rectangle {
                width: 8
                height: 26
                x: Math.max(0, Math.min(parent.width - width, (parent.width * Math.max(0, Math.min(1, value))) - (width / 2)))
                anchors.verticalCenter: parent.verticalCenter
                color: "#e0e0e0"
                border.color: "#0a0a0a"
                border.width: 1
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
