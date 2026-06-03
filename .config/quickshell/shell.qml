import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io

ShellRoot {
    id: root

    // --- IPC SERVER ---
    IpcHandler {
        target: "controlcenter"
        function toggle() {
            ccPanel.toggle()
        }
    }

    ControlCenter {
        id: ccPanel
        onRequestSettings: settingsPanel.toggle()
    }

    SettingsPanel {
        id: settingsPanel
    }

    function localPath(fileName) {
        const resolved = Qt.resolvedUrl(fileName).toString()
        return resolved.startsWith("file://") ? decodeURIComponent(resolved.substring(7)) : resolved
    }

    // Pick the most recently active player
    readonly property MprisPlayer activePlayer: Mpris.players.values[0] ?? null

    // --- DATA FETCHING ---
    property var hwStats: {"cpu": "---", "gpu": "---", "mem": "---"}
    property var swStats: {"os": "---", "wm": "---", "sh": "---"}

    Process {
        id: hwProcess
        command: [root.localPath("hw_stats.sh")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { hwStats = JSON.parse(text); } catch(e) {}
            }
        }
    }

    Process {
        id: swProcess
        command: [root.localPath("sw_stats.sh")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { swStats = JSON.parse(text); } catch(e) {}
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            hwProcess.running = false; hwProcess.running = true;
            swProcess.running = false; swProcess.running = true;
        }
    }

    // --- WIDGET 1: SPOTIFY CAPSULE (BOTTOM-LEFT) ---
    PanelWindow {
        anchors { bottom: true; left: true }
        margins { bottom: 40; left: 40 }
        implicitWidth: 320; implicitHeight: 120; color: "#050505"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "spotify-widget"
        Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#1a1a1a"; border.width: 1 }

        RowLayout {
            anchors.fill: parent; anchors.margins: 15; spacing: 15
            Rectangle {
                Layout.preferredWidth: 90; Layout.preferredHeight: 90; color: "#111111"
                Image {
                    anchors.fill: parent
                    source: activePlayer ? activePlayer.metadata["mpris:artUrl"] ?? "" : ""
                    fillMode: Image.PreserveAspectCrop
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { text: activePlayer ? "  SPOTIFY" : "  NO MEDIA"; color: "#555555"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
                Text { text: activePlayer ? activePlayer.trackTitle : "Offline"; color: "#ffffff"; font.family: "JetBrains Mono"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: activePlayer ? activePlayer.trackArtist : "---"; color: "#888888"; font.family: "JetBrains Mono"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                RowLayout {
                    spacing: 10; Layout.topMargin: 5
                    Text { text: "󰒮"; color: activePlayer && activePlayer.canGoPrevious ? "#ffffff" : "#333333"; font.pixelSize: 16; MouseArea { anchors.fill: parent; onClicked: if (activePlayer) activePlayer.previous() } }
                    Text { text: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"; color: activePlayer && activePlayer.canControl ? "#ffffff" : "#333333"; font.pixelSize: 18; MouseArea { anchors.fill: parent; onClicked: if (activePlayer) activePlayer.togglePlaying() } }
                    Text { text: "󰒭"; color: activePlayer && activePlayer.canGoNext ? "#ffffff" : "#333333"; font.pixelSize: 16; MouseArea { anchors.fill: parent; onClicked: if (activePlayer) activePlayer.next() } }
                }
            }
        }
    }

    // --- WIDGET 2: SYSTEM DASHBOARD (BOTTOM-RIGHT) ---
    PanelWindow {
        anchors { bottom: true; right: true }
        margins { bottom: 40; right: 40 }
        implicitWidth: 350; implicitHeight: 180; color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "stats-widget"

        ColumnLayout {
            anchors.right: parent.right; spacing: 15
            ColumnLayout {
                Layout.alignment: Qt.AlignRight; spacing: 4
                Text { text: "HARDWARE"; color: "#888888"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2; Layout.alignment: Qt.AlignRight }
                Text { text: "<font color='#555555'>CPU</font> " + hwStats.cpu; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.pixelSize: 11; textFormat: Text.RichText; Layout.alignment: Qt.AlignRight }
                Text { text: "<font color='#555555'>GPU</font> " + hwStats.gpu; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.pixelSize: 11; textFormat: Text.RichText; Layout.alignment: Qt.AlignRight }
                Text { text: "<font color='#555555'>MEM</font> " + hwStats.mem; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.pixelSize: 11; textFormat: Text.RichText; Layout.alignment: Qt.AlignRight }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignRight; spacing: 4
                Text { text: "SOFTWARE"; color: "#888888"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2; Layout.alignment: Qt.AlignRight }
                Text { text: "<font color='#555555'>OS</font> " + swStats.os; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.pixelSize: 11; textFormat: Text.RichText; Layout.alignment: Qt.AlignRight }
                Text { text: "<font color='#555555'>WM</font> " + swStats.wm; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.pixelSize: 11; textFormat: Text.RichText; Layout.alignment: Qt.AlignRight }
                Text { text: "<font color='#555555'>SH</font> " + swStats.sh; color: "#e0e0e0"; font.family: "JetBrains Mono"; font.pixelSize: 11; textFormat: Text.RichText; Layout.alignment: Qt.AlignRight }
            }
        }
    }
}
