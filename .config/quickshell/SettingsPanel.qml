import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: settingsPanel

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "settings-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var settings: null
    property string currentTab: "Quick"
    property string fallbackWallpaperPath: Quickshell.env("HOME") + "/.config/wall/catwall.png"
    property var tabs: [
        { name: "Quick", icon: "" },
        { name: "General", icon: "" },
        { name: "Bar", icon: "▰" },
        { name: "Modules", icon: "" },
        { name: "System", icon: "" },
        { name: "Keybinds", icon: "" }
    ]

    function toggle() {
        settingsPanel.visible = !settingsPanel.visible
    }

    function open() {
        settingsPanel.visible = true
    }

    function close() {
        settingsPanel.visible = false
    }

    function localPath(fileName) {
        const resolved = Qt.resolvedUrl(fileName).toString()
        return resolved.startsWith("file://") ? decodeURIComponent(resolved.substring(7)) : resolved
    }

    function currentWallpaperPath() {
        return settings ? settings.wallpaperPath : fallbackWallpaperPath
    }

    function setSetting(name, value) {
        if (!settings)
            return

        settings[name] = value
        settings.save()
    }

    function boolArg(value) {
        return value ? "true" : "false"
    }

    function setSettingAndApplyWaybar(name, value) {
        settingsPanel.setSetting(name, value)
        settingsPanel.applyWaybarModules()
    }

    function run(process) {
        process.running = false
        process.running = true
    }

    function applyWaybarModules() {
        if (!settings)
            return

        applyWaybar.command = [
            "sh",
            settingsPanel.localPath("apply_waybar_modules.sh"),
            settingsPanel.boolArg(settings.barNetworkEnabled),
            settingsPanel.boolArg(settings.barAudioEnabled),
            settingsPanel.boolArg(settings.barBluetoothEnabled),
            settingsPanel.boolArg(settings.barNotificationsEnabled)
        ]
        settingsPanel.run(applyWaybar)
    }

    function applyCurrentWallpaper() {
        applyWallpaper.command = ["sh", "-c", "pkill swaybg; swaybg -i \"$1\" -m fill >/tmp/swaybg.log 2>&1 &", "sh", currentWallpaperPath()]
        applyWallpaper.running = false
        applyWallpaper.running = true
    }

    function applyBlurSetting() {
        if (!settings)
            return

        applyBlur.command = ["hyprctl", "keyword", "decoration:blur:enabled", settings.blurEnabled ? "true" : "false"]
        applyBlur.running = false
        applyBlur.running = true
    }

    Process { id: applyWaybar; running: false }
    Process { id: restartShell; command: ["sh", "-c", "(sleep 0.2; quickshell kill 2>/dev/null || pkill -x quickshell || true; quickshell --daemonize -p \"$HOME/.config/quickshell/shell.qml\") >/tmp/terminal-noir-quickshell-restart.log 2>&1 &"]; running: false }
    Process { id: restartWaybar; command: ["sh", "-c", "pkill waybar; waybar >/tmp/waybar.log 2>&1 &"]; running: false }
    Process { id: restartOsd; command: ["sh", "-c", "pkill -x swayosd-server >/dev/null 2>&1 || true; \"$HOME/.config/hypr/scripts/swayosd-launch.sh\" >/tmp/terminal-noir-swayosd.log 2>&1 &"]; running: false }
    Process { id: restartIdle; command: ["systemctl", "--user", "restart", "hypridle.service"]; running: false }
    Process { id: restartSunset; command: ["systemctl", "--user", "restart", "hyprsunset.service"]; running: false }
    Process { id: resetPortals; command: ["sh", "-c", "\"$HOME/.config/hypr/scripts/resetxdgportal.sh\""]; running: false }
    Process { id: testNotification; command: ["notify-send", "-a", "Terminal Noir", "Terminal Noir", "Notification pipeline is active"]; running: false }
    Process { id: applyWallpaper; running: false }
    Process { id: applyBlur; running: false }
    Process { id: reloadHyprland; command: ["hyprctl", "reload"]; running: false }
    Process { id: lockScreen; command: [Quickshell.env("HOME") + "/.config/hypr/scripts/lockscreen.sh"]; running: false }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.55
        MouseArea { anchors.fill: parent; onClicked: settingsPanel.close() }
    }

    Rectangle {
        id: window
        width: Math.min(1000, settingsPanel.width - 80)
        height: Math.min(650, settingsPanel.height - 80)
        anchors.centerIn: parent
        color: "#0a0a0a"
        border.color: "#333333"
        border.width: 1
        clip: true
        focus: true

        Keys.onEscapePressed: settingsPanel.close()

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 205
                Layout.fillHeight: true
                color: "#101010"
                border.color: "#1c1c1c"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Settings"
                        color: "#ffffff"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 6
                        Layout.bottomMargin: 8
                    }

                    Repeater {
                        model: settingsPanel.tabs

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            color: settingsPanel.currentTab === modelData.name ? "#e0e0e0" : "transparent"
                            border.color: settingsPanel.currentTab === modelData.name ? "#e0e0e0" : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: settingsPanel.currentTab === modelData.name ? "#000000" : "#e0e0e0"
                                    font.pixelSize: 15
                                    Layout.preferredWidth: 20
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    text: modelData.name
                                    color: settingsPanel.currentTab === modelData.name ? "#000000" : "#e0e0e0"
                                    font.family: "JetBrains Mono"
                                    font.bold: true
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsPanel.currentTab = modelData.name
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        text: "TERMINAL NOIR"
                        color: "#555555"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#0a0a0a"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34

                        Text {
                            text: settingsPanel.currentTab
                            color: "#ffffff"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 22
                            Layout.fillWidth: true
                        }

                        Text {
                            text: ""
                            color: "#888888"
                            font.pixelSize: 16
                            MouseArea { anchors.fill: parent; onClicked: settingsPanel.close() }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#0d0d0d"
                        border.color: "#1c1c1c"
                        border.width: 1
                        clip: true

                        Loader {
                            anchors.fill: parent
                            anchors.margins: 20
                            sourceComponent: {
                                if (settingsPanel.currentTab === "Quick") return quickPage
                                if (settingsPanel.currentTab === "General") return generalPage
                                if (settingsPanel.currentTab === "Bar") return barPage
                                if (settingsPanel.currentTab === "Modules") return modulesPage
                                if (settingsPanel.currentTab === "System") return systemPage
                                return keybindsPage
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: quickPage
        Flickable {
            contentWidth: width
            contentHeight: quickColumn.implicitHeight
            clip: true

            ColumnLayout {
                id: quickColumn
                width: parent.width
                spacing: 18

                SectionTitle { icon: ""; title: "Wallpaper" }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 320
                        Layout.preferredHeight: 180
                        color: "#111111"
                        border.color: "#333333"
                        border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: "file://" + settingsPanel.currentWallpaperPath()
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        TextInputLine {
                            title: "Wallpaper Path"
                            value: settingsPanel.currentWallpaperPath()
                            onCommitted: (text) => settingsPanel.setSetting("wallpaperPath", text)
                        }

                        ActionButton {
                            icon: "󰸉"
                            label: "Apply Wallpaper"
                            onClicked: settingsPanel.applyCurrentWallpaper()
                        }
                        ActionButton {
                            icon: ""
                            label: "Restart Waybar"
                            onClicked: settingsPanel.applyWaybarModules()
                        }
                    }
                }

                SectionTitle { icon: ""; title: "Theme" }
                ToggleLine {
                    title: "Hyprland Blur"
                    subtitle: "Apply live compositor blur for translucent overlays"
                    checked: settingsPanel.settings ? settingsPanel.settings.blurEnabled : true
                    onToggled: (value) => {
                        settingsPanel.setSetting("blurEnabled", value)
                        settingsPanel.applyBlurSetting()
                    }
                }
                ToggleLine { title: "Dark Mode"; subtitle: "Terminal Noir stays monochrome and high contrast"; checked: true; locked: true }
                ToggleLine { title: "Sharp Corners"; subtitle: "0px radius across shell surfaces"; checked: true; locked: true }
            }
        }
    }

    Component {
        id: generalPage
        PageColumn {
            SectionTitle { icon: ""; title: "Typography" }
            InfoLine { title: "Main Font"; value: "JetBrains Mono" }
            InfoLine { title: "Mono Font"; value: "JetBrains Mono Nerd Font" }
            SectionTitle { icon: "◼"; title: "Geometry" }
            InfoLine { title: "Corners"; value: "0px" }
            InfoLine { title: "Borders"; value: "1px" }
            InfoLine { title: "Palette"; value: "Monochrome" }
        }
    }

    Component {
        id: barPage
        PageColumn {
            SectionTitle { icon: "▰"; title: "Bar" }
            InfoLine { title: "Position"; value: "Top" }
            InfoLine { title: "Workspaces"; value: "1-5" }
            InfoLine { title: "Height"; value: "32px" }
            ToggleLine {
                title: "Network Module"
                subtitle: "Persisted preference for the Waybar network block"
                checked: settingsPanel.settings ? settingsPanel.settings.barNetworkEnabled : true
                onToggled: (value) => settingsPanel.setSettingAndApplyWaybar("barNetworkEnabled", value)
            }
            ToggleLine {
                title: "Audio Module"
                subtitle: "Persisted preference for the Waybar audio block"
                checked: settingsPanel.settings ? settingsPanel.settings.barAudioEnabled : true
                onToggled: (value) => settingsPanel.setSettingAndApplyWaybar("barAudioEnabled", value)
            }
            ToggleLine {
                title: "Bluetooth Module"
                subtitle: "Persisted preference for the Waybar Bluetooth block"
                checked: settingsPanel.settings ? settingsPanel.settings.barBluetoothEnabled : true
                onToggled: (value) => settingsPanel.setSettingAndApplyWaybar("barBluetoothEnabled", value)
            }
            ToggleLine {
                title: "Notifications Module"
                subtitle: "Persisted preference for the Waybar notification button"
                checked: settingsPanel.settings ? settingsPanel.settings.barNotificationsEnabled : true
                onToggled: (value) => settingsPanel.setSettingAndApplyWaybar("barNotificationsEnabled", value)
            }
        }
    }

    Component {
        id: modulesPage
        PageColumn {
            SectionTitle { icon: ""; title: "Modules" }
            ToggleLine {
                title: "Quick Details"
                subtitle: "Enable in-panel Wi-Fi and Bluetooth detail views"
                checked: settingsPanel.settings ? settingsPanel.settings.quickPanelDetailsEnabled : true
                onToggled: (value) => settingsPanel.setSetting("quickPanelDetailsEnabled", value)
            }
            ToggleLine {
                title: "Media Widget"
                subtitle: "Bottom-left MPRIS player card"
                checked: settingsPanel.settings ? settingsPanel.settings.mediaWidgetEnabled : true
                onToggled: (value) => settingsPanel.setSetting("mediaWidgetEnabled", value)
            }
            ToggleLine {
                title: "Stats Widget"
                subtitle: "Bottom-right hardware and software dashboard"
                checked: settingsPanel.settings ? settingsPanel.settings.statsWidgetEnabled : true
                onToggled: (value) => settingsPanel.setSetting("statsWidgetEnabled", value)
            }
            ToggleLine {
                title: "Notification Popups"
                subtitle: "Quickshell handles notification toasts"
                checked: settingsPanel.settings ? settingsPanel.settings.notificationPopupsEnabled : true
                onToggled: (value) => settingsPanel.setSetting("notificationPopupsEnabled", value)
            }
            ToggleLine {
                title: "Clock Calendar"
                subtitle: "Waybar clock opens the calendar panel"
                checked: settingsPanel.settings ? settingsPanel.settings.calendarEnabled : true
                onToggled: (value) => settingsPanel.setSetting("calendarEnabled", value)
            }
        }
    }

    Component {
        id: systemPage
        PageColumn {
            SectionTitle { icon: ""; title: "System" }
            InfoLine { title: "Window Manager"; value: "Hyprland" }
            InfoLine { title: "Shell"; value: "Quickshell" }
            InfoLine { title: "Launcher"; value: "Rofi" }
            ActionButton { icon: ""; label: "Reload Hyprland"; onClicked: settingsPanel.run(reloadHyprland) }
            ActionButton { icon: "󰒲"; label: "Restart Shell"; onClicked: settingsPanel.run(restartShell) }
            ActionButton { icon: "▰"; label: "Restart Waybar"; onClicked: settingsPanel.applyWaybarModules() }
            ActionButton { icon: "󰍹"; label: "Restart OSD"; onClicked: settingsPanel.run(restartOsd) }
            ActionButton { icon: "󰒲"; label: "Restart Idle Service"; onClicked: settingsPanel.run(restartIdle) }
            ActionButton { icon: "󰖔"; label: "Restart Sunset Service"; onClicked: settingsPanel.run(restartSunset) }
            ActionButton { icon: "󰖟"; label: "Reset Portals"; onClicked: settingsPanel.run(resetPortals) }
            ActionButton { icon: ""; label: "Test Notification"; onClicked: settingsPanel.run(testNotification) }
            ActionButton { icon: ""; label: "Lock"; onClicked: settingsPanel.run(lockScreen) }
        }
    }

    Component {
        id: keybindsPage
        PageColumn {
            SectionTitle { icon: ""; title: "Keybinds" }
            InfoLine { title: "Terminal"; value: "SUPER + T" }
            InfoLine { title: "Launcher"; value: "SUPER + Space" }
            InfoLine { title: "Clipboard"; value: "SUPER + V" }
            InfoLine { title: "Float"; value: "SUPER + SHIFT + V" }
            InfoLine { title: "Lock"; value: "SUPER + CTRL + L" }
            InfoLine { title: "Logout"; value: "SUPER + M" }
            InfoLine { title: "Audio"; value: "Fn + F1/F2/F3" }
            InfoLine { title: "Brightness"; value: "Fn + F9/F10" }
        }
    }

    component PageColumn: ColumnLayout {
        spacing: 14
    }

    component SectionTitle: RowLayout {
        property string icon: ""
        property string title: ""
        Layout.fillWidth: true
        spacing: 10
        Text { text: icon; color: "#e0e0e0"; font.pixelSize: 15; Layout.preferredWidth: 22 }
        Text {
            text: title
            color: "#ffffff"
            font.family: "JetBrains Mono"
            font.bold: true
            font.pixelSize: 16
        }
    }

    component ActionButton: Rectangle {
        signal clicked()
        property string icon: ""
        property string label: ""
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        color: mouse.containsMouse ? "#1c1c1c" : "#111111"
        border.color: "#333333"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
            Text { text: icon; color: "#e0e0e0"; font.pixelSize: 17; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
            Text { text: label; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; Layout.fillWidth: true }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component ToggleLine: Rectangle {
        signal toggled(bool checked)
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        property bool locked: false
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        color: toggleMouse.containsMouse && !locked ? "#141414" : "#101010"
        border.color: locked ? "#151515" : "#1c1c1c"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: title; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12 }
                Text { text: subtitle; color: "#888888"; font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
            }

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 20
                color: checked ? "#e0e0e0" : "#1c1c1c"
                border.color: "#333333"
                border.width: 1
                Rectangle {
                    width: 14
                    height: 14
                    x: checked ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: checked ? "#000000" : "#888888"
                    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }
            }
        }

        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !locked
            cursorShape: locked ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: toggled(!checked)
        }
    }

    component SegmentedRow: ColumnLayout {
        property string title: ""
        property var options: []
        property int selectedIndex: 0
        Layout.fillWidth: true
        spacing: 8

        Text { text: title; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12 }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: options
                Rectangle {
                    Layout.preferredWidth: Math.max(90, optionText.implicitWidth + 24)
                    Layout.preferredHeight: 30
                    color: index === selectedIndex ? "#e0e0e0" : "#1c1c1c"
                    border.color: "#333333"
                    border.width: 1

                    Text {
                        id: optionText
                        anchors.centerIn: parent
                        text: modelData
                        color: index === selectedIndex ? "#000000" : "#e0e0e0"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedIndex = index
                    }
                }
            }
        }
    }

    component InfoLine: Rectangle {
        property string title: ""
        property string value: ""
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        color: "#101010"
        border.color: "#1c1c1c"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            Text { text: title; color: "#888888"; font.family: "JetBrains Mono"; font.pixelSize: 11; Layout.fillWidth: true }
            Text { text: value; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 11 }
        }
    }

    component TextInputLine: Rectangle {
        signal committed(string text)
        property string title: ""
        property string value: ""
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        color: "#101010"
        border.color: input.activeFocus ? "#888888" : "#1c1c1c"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Text {
                text: title
                color: "#888888"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                Layout.preferredWidth: 120
            }

            TextInput {
                id: input
                Layout.fillWidth: true
                text: value
                color: "#e0e0e0"
                selectionColor: "#e0e0e0"
                selectedTextColor: "#000000"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                clip: true
                onAccepted: committed(text)
                onEditingFinished: committed(text)
            }
        }
    }
}
