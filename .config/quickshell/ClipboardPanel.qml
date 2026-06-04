import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: clipboardPanel

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
    WlrLayershell.namespace: "clipboard-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property string searchText: ""
    property string statusText: ""
    property var history: []
    property var pins: []
    readonly property var filteredHistory: history.filter(item => item.label.toLowerCase().indexOf(searchText.toLowerCase()) >= 0)
    readonly property var filteredPins: pins.filter(item => item.label.toLowerCase().indexOf(searchText.toLowerCase()) >= 0)

    function toggle() {
        clipboardPanel.visible = !clipboardPanel.visible
        if (clipboardPanel.visible)
            clipboardPanel.refresh()
    }

    function close() {
        clipboardPanel.visible = false
        clipboardPanel.searchText = ""
    }

    function localPath(fileName) {
        const resolved = Qt.resolvedUrl(fileName).toString()
        return resolved.startsWith("file://") ? decodeURIComponent(resolved.substring(7)) : resolved
    }

    function helperPath() {
        return Quickshell.env("HOME") + "/.config/rofi/clipboard-menu.sh"
    }

    function refresh() {
        clipboardPanel.statusText = "refreshing"
        loadClipboard.running = false
        loadClipboard.running = true
    }

    function runAction(args, status) {
        clipboardPanel.statusText = status
        clipboardAction.command = [helperPath()].concat(args)
        clipboardAction.running = false
        clipboardAction.running = true
    }

    function copyHistory(payload) {
        runAction(["--copy-history", payload], "copied")
        closeSoon.restart()
    }

    function pinHistory(payload) {
        runAction(["--pin-history", payload], "pinned")
    }

    function deleteHistory(payload) {
        runAction(["--delete-history", payload], "deleted")
    }

    function copyPin(id) {
        runAction(["--copy-pin", id], "copied")
        closeSoon.restart()
    }

    function unpin(id) {
        runAction(["--unpin", id], "unpinned")
    }

    onVisibleChanged: {
        if (visible) {
            clipboardPanel.refresh()
            searchBox.forceActiveFocus()
        }
    }

    Process {
        id: loadClipboard
        command: [clipboardPanel.helperPath(), "--list-json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw.startsWith("{") || !raw.endsWith("}"))
                    return

                try {
                    const state = JSON.parse(raw)
                    clipboardPanel.pins = state.pins || []
                    clipboardPanel.history = state.history || []
                    clipboardPanel.statusText = clipboardPanel.history.length + " history  " + clipboardPanel.pins.length + " pinned"
                } catch (e) {
                    clipboardPanel.statusText = "failed to read clipboard"
                    console.warn("Failed to parse clipboard state:", e)
                }
            }
        }
    }

    Process {
        id: clipboardAction
        running: false
        onRunningChanged: {
            if (!running && clipboardPanel.visible)
                refreshAfterAction.restart()
        }
    }

    Timer { id: refreshAfterAction; interval: 350; repeat: false; onTriggered: clipboardPanel.refresh() }
    Timer { id: closeSoon; interval: 180; repeat: false; onTriggered: clipboardPanel.close() }
    Timer {
        interval: 5000
        running: clipboardPanel.visible
        repeat: true
        onTriggered: clipboardPanel.refresh()
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.48
        MouseArea { anchors.fill: parent; onClicked: clipboardPanel.close() }
    }

    Rectangle {
        id: window
        width: Math.min(780, clipboardPanel.width - 72)
        height: Math.min(520, clipboardPanel.height - 90)
        anchors.centerIn: parent
        color: "#0a0a0a"
        border.color: "#333333"
        border.width: 1
        clip: true
        focus: true

        Keys.onEscapePressed: clipboardPanel.close()

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.leftMargin: 14
                Layout.rightMargin: 12
                spacing: 12

                Text {
                    text: "clipboard"
                    color: "#9aa4b5"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 11
                    Layout.preferredWidth: 76
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: "#080808"
                    border.color: searchBox.activeFocus ? "#555555" : "#1c1c1c"
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search clipboard"
                        visible: searchBox.text.length === 0
                        color: "#8290a6"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                    }

                    TextInput {
                        id: searchBox
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        text: clipboardPanel.searchText
                        color: "#ffffff"
                        selectionColor: "#e0e0e0"
                        selectedTextColor: "#000000"
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        clip: true
                        onTextChanged: clipboardPanel.searchText = text
                    }
                }

                Text {
                    text: clipboardPanel.statusText
                    color: "#666666"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    Layout.preferredWidth: 125
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: ""
                    title: "Refresh"
                    onClicked: clipboardPanel.refresh()
                }

                IconButton {
                    icon: ""
                    title: "Close"
                    onClicked: clipboardPanel.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#1c1c1c"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                ClipboardColumn {
                    title: "Clipboard History"
                    subtitle: clipboardPanel.filteredHistory.length + " items"
                    emptyText: "No clipboard history"
                    modelDataList: clipboardPanel.filteredHistory
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 500
                    delegateComponent: historyDelegate
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: "#1c1c1c"
                }

                ClipboardColumn {
                    title: "Pinned Content"
                    subtitle: clipboardPanel.filteredPins.length + " saved"
                    emptyText: "No pinned content"
                    modelDataList: clipboardPanel.filteredPins
                    Layout.fillHeight: true
                    Layout.preferredWidth: 260
                    delegateComponent: pinDelegate
                }
            }
        }
    }

    Component {
        id: historyDelegate

        ClipboardRow {
            label: modelData.label
            meta: "history"
            active: false
            actions: [
                { icon: "", title: "Copy", run: () => clipboardPanel.copyHistory(modelData.payload) },
                { icon: "󰐃", title: "Pin", run: () => clipboardPanel.pinHistory(modelData.payload) },
                { icon: "", title: "Delete", run: () => clipboardPanel.deleteHistory(modelData.payload) }
            ]
        }
    }

    Component {
        id: pinDelegate

        ClipboardRow {
            label: modelData.label
            meta: modelData.mime
            active: true
            actions: [
                { icon: "", title: "Copy", run: () => clipboardPanel.copyPin(modelData.id) },
                { icon: "󰤱", title: "Unpin", run: () => clipboardPanel.unpin(modelData.id) }
            ]
        }
    }

    component ClipboardColumn: Rectangle {
        property string title: ""
        property string subtitle: ""
        property string emptyText: ""
        property var modelDataList: []
        property Component delegateComponent

        color: "#0a0a0a"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 26

                Text {
                    text: title
                    color: "#ffffff"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: subtitle
                    color: "#666666"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                visible: modelDataList.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#0d0d0d"
                border.color: "#1c1c1c"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: emptyText
                    color: "#555555"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 12
                }
            }

            ListView {
                id: clipboardList
                visible: modelDataList.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: modelDataList
                delegate: delegateComponent
            }
        }
    }

    component ClipboardRow: Rectangle {
        property string label: ""
        property string meta: ""
        property bool active: false
        property var actions: []

        width: ListView.view ? ListView.view.width : 1
        height: 74
        color: rowMouse.containsMouse ? "#151515" : (active ? "#101010" : "#0d0d0d")
        border.color: active ? "#333333" : "#222222"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: active ? "󰐃" : ""
                color: active ? "#e0e0e0" : "#888888"
                font.pixelSize: 15
                Layout.preferredWidth: 18
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: label
                    textFormat: Text.PlainText
                    color: "#e0e0e0"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }

                Text {
                    Layout.fillWidth: true
                    text: meta
                    textFormat: Text.PlainText
                    color: "#666666"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            Repeater {
                model: actions
                IconButton {
                    icon: modelData.icon
                    title: modelData.title
                    onClicked: modelData.run()
                }
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    component IconButton: Rectangle {
        signal clicked()
        property string icon: ""
        property string title: ""

        Layout.preferredWidth: 34
        Layout.preferredHeight: 28
        color: buttonMouse.containsMouse ? "#1c1c1c" : "#0a0a0a"
        border.color: "#2a2a2a"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: icon
            color: "#e0e0e0"
            font.pixelSize: 13
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
