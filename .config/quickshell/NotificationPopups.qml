import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var notifications: []
    readonly property var visibleNotifications: notifications.filter(n => n.shownInPopup).slice(0, 4)

    signal openNotification(string id)
    signal dismissNotification(string id)
    signal hideNotificationPopup(string id)

    function actionButtons(item) {
        const notification = item.notification
        const actions = notification && notification.actions ? notification.actions : []
        const buttons = []

        for (let i = 0; i < actions.length && buttons.length < 2; i++) {
            if (actions[i].identifier !== "default")
                buttons.push(actions[i])
        }

        return buttons
    }

    anchors {
        top: true
        right: true
    }
    margins {
        top: 42
        right: 18
    }

    implicitWidth: 400
    implicitHeight: 420
    color: "transparent"
    visible: visibleNotifications.length > 0
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "notification-popups"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
        id: stack
        width: parent.width
        spacing: 10

        Repeater {
            model: root.visibleNotifications

            Rectangle {
                id: toast
                required property var modelData

                width: stack.width
                height: Math.max(116, content.implicitHeight + 28)
                color: "#090909"
                border.color: "#333333"
                border.width: 1

                Rectangle {
                    width: 4
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                    }
                    color: "#e0e0e0"
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openNotification(toast.modelData.id)
                }

                Timer {
                    interval: 7000
                    running: true
                    repeat: false
                    onTriggered: root.hideNotificationPopup(toast.modelData.id)
                }

                ColumnLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "⇩"
                            color: "#e0e0e0"
                            font.pixelSize: 12
                        }

                        Text {
                            text: modelData.appName.toUpperCase()
                            color: "#ffffff"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "now"
                            color: "#888888"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.title
                        color: "#e0e0e0"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 14
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: modelData.body.length > 0
                        text: modelData.body
                        color: "#c8c8c8"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: root.actionButtons(toast.modelData)

                            Rectangle {
                                id: actionButton
                                required property var modelData
                                Layout.preferredWidth: Math.max(84, actionText.implicitWidth + 24)
                                Layout.preferredHeight: 30
                                color: "#1c1c1c"
                                border.color: "#333333"
                                border.width: 1

                                Text {
                                    id: actionText
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    color: "#ffffff"
                                    font.family: "JetBrains Mono"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    propagateComposedEvents: false
                                    onClicked: {
                                        modelData.invoke()
                                        root.dismissNotification(toast.modelData.id)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 30
                            color: "#101010"
                            border.color: "#222222"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Dismiss"
                                color: "#888888"
                                font.family: "JetBrains Mono"
                                font.bold: true
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                propagateComposedEvents: false
                                onClicked: root.dismissNotification(toast.modelData.id)
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }
}
