import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#000000"

    property string fontName: config.Font || "JetBrains Mono"
    property string clockFormat: config.ClockFormat || "HH:mm"
    property string dateFormat: config.DateFormat || "dddd, MMMM d"
    property date currentDate: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    Image {
        anchors.fill: parent
        source: config.BackgroundBlur || "background-blur.png"
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: false
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.42
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#1c1c1c"
        border.width: 1
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(root.width * 0.42, 520)
        spacing: 18

        Text {
            Layout.fillWidth: true
            text: Qt.formatTime(root.currentDate, root.clockFormat)
            color: "#ffffff"
            font.family: root.fontName
            font.pixelSize: 74
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.currentDate, root.dateFormat).toUpperCase()
            color: "#b0b0b0"
            font.family: root.fontName
            font.pixelSize: 13
            font.letterSpacing: 4
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#333333"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: userInput
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                text: userModel.lastUser
                placeholderText: "username"
                color: "#ffffff"
                selectionColor: "#e0e0e0"
                selectedTextColor: "#000000"
                font.family: root.fontName
                font.pixelSize: 13
                background: Rectangle {
                    color: "#0a0a0acc"
                    border.color: userInput.activeFocus ? "#e0e0e0" : "#333333"
                    border.width: 1
                    radius: 0
                }
                Keys.onReturnPressed: passwordInput.forceActiveFocus()
                Keys.onEnterPressed: passwordInput.forceActiveFocus()
            }

            TextField {
                id: passwordInput
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                placeholderText: "password"
                echoMode: TextInput.Password
                color: "#ffffff"
                selectionColor: "#e0e0e0"
                selectedTextColor: "#000000"
                font.family: root.fontName
                font.pixelSize: 13
                focus: true
                background: Rectangle {
                    color: "#0a0a0acc"
                    border.color: passwordInput.activeFocus ? "#e0e0e0" : "#333333"
                    border.width: 1
                    radius: 0
                }
                Keys.onReturnPressed: sddm.login(userInput.text, passwordInput.text, sessionSelector.currentIndex)
                Keys.onEnterPressed: sddm.login(userInput.text, passwordInput.text, sessionSelector.currentIndex)
            }

            Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                text: "LOGIN"
                font.family: root.fontName
                font.pixelSize: 12
                font.bold: true
                background: Rectangle {
                    color: loginButton.pressed ? "#ffffff" : "#e0e0e0"
                    border.color: "#e0e0e0"
                    border.width: 1
                    radius: 0
                }
                contentItem: Text {
                    text: loginButton.text
                    color: "#000000"
                    font: loginButton.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: sddm.login(userInput.text, passwordInput.text, sessionSelector.currentIndex)
            }
        }

        Text {
            Layout.fillWidth: true
            text: sddm.lastLoginMessage
            visible: text.length > 0
            color: "#888888"
            font.family: root.fontName
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 10

        ComboBox {
            id: sessionSelector
            Layout.preferredWidth: 190
            Layout.preferredHeight: 34
            model: sessionModel
            textRole: "name"
            font.family: root.fontName
            font.pixelSize: 11
            background: Rectangle {
                color: "#0a0a0acc"
                border.color: "#333333"
                border.width: 1
                radius: 0
            }
            contentItem: Text {
                text: sessionSelector.displayText
                color: "#c8c8c8"
                font: sessionSelector.font
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillWidth: true }

        Button {
            Layout.preferredWidth: 92
            Layout.preferredHeight: 34
            text: "REBOOT"
            font.family: root.fontName
            font.pixelSize: 10
            background: Rectangle {
                color: "#0a0a0acc"
                border.color: "#333333"
                border.width: 1
                radius: 0
            }
            contentItem: Text {
                text: parent.text
                color: "#c8c8c8"
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: sddm.reboot()
        }

        Button {
            Layout.preferredWidth: 104
            Layout.preferredHeight: 34
            text: "SHUTDOWN"
            font.family: root.fontName
            font.pixelSize: 10
            background: Rectangle {
                color: "#0a0a0acc"
                border.color: "#333333"
                border.width: 1
                radius: 0
            }
            contentItem: Text {
                text: parent.text
                color: "#c8c8c8"
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: sddm.powerOff()
        }
    }
}
