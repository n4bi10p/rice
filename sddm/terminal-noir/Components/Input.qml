import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import SddmComponents 2.0

ColumnLayout {
    id: inputContainer

    property int selectedSession: 0
    property bool failed: false

    spacing: 10

    TextConstants { id: textConstants }

    QQC2.Label {
        Layout.fillWidth: true
        Layout.preferredHeight: root.font.pointSize * 1.8
        text: failed ? (config.TranslateLoginFailedWarning || textConstants.loginFailed) : (keyboard.capsLock ? (config.TranslateCapslockWarning || textConstants.capslockWarning) : "")
        color: config.WarningColor || "#e0e0e0"
        font.family: root.font.family
        font.pointSize: root.font.pointSize * 0.8
        horizontalAlignment: Text.AlignHCenter
        opacity: text.length > 0 ? 1 : 0
    }

    QQC2.TextField {
        id: username
        Layout.fillWidth: true
        Layout.preferredHeight: root.font.pointSize * 3.3
        text: config.ForceLastUser == "true" ? userModel.lastUser : ""
        placeholderText: config.TranslatePlaceholderUsername || textConstants.userName
        placeholderTextColor: config.PlaceholderTextColor || "#888888"
        color: config.LoginFieldTextColor || "#ffffff"
        selectedTextColor: "#000000"
        selectionColor: "#e0e0e0"
        horizontalAlignment: TextInput.AlignHCenter
        selectByMouse: true
        font.family: root.font.family
        font.bold: true
        background: Rectangle {
            color: config.LoginFieldBackgroundColor || "#0a0a0a"
            opacity: 0.58
            border.color: username.activeFocus ? (config.HighlightBorderColor || "#e0e0e0") : "#333333"
            border.width: 1
            radius: config.RoundCorners !== "" ? Number(config.RoundCorners) : 0
        }
        leftPadding: 44
        rightPadding: 44
        Keys.onReturnPressed: password.forceActiveFocus()
        Keys.onEnterPressed: password.forceActiveFocus()

        Image {
            source: Qt.resolvedUrl("../Assets/User.svg")
            width: 15
            height: 15
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0.72
        }
    }

    QQC2.TextField {
        id: password
        Layout.fillWidth: true
        Layout.preferredHeight: root.font.pointSize * 3.3
        focus: config.PasswordFocus == "true"
        placeholderText: config.TranslatePlaceholderPassword || textConstants.password
        placeholderTextColor: config.PlaceholderTextColor || "#888888"
        echoMode: TextInput.Password
        passwordCharacter: "*"
        color: config.PasswordFieldTextColor || "#ffffff"
        selectedTextColor: "#000000"
        selectionColor: "#e0e0e0"
        horizontalAlignment: TextInput.AlignHCenter
        selectByMouse: true
        font.family: root.font.family
        font.bold: true
        background: Rectangle {
            color: config.PasswordFieldBackgroundColor || "#0a0a0a"
            opacity: 0.58
            border.color: password.activeFocus ? (config.HighlightBorderColor || "#e0e0e0") : "#333333"
            border.width: 1
            radius: config.RoundCorners !== "" ? Number(config.RoundCorners) : 0
        }
        leftPadding: 44
        rightPadding: 44
        onAccepted: login()

        Image {
            source: Qt.resolvedUrl("../Assets/Password.svg")
            width: 15
            height: 15
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0.72
        }
    }

    QQC2.Button {
        id: loginButton
        Layout.fillWidth: true
        Layout.preferredHeight: root.font.pointSize * 3.2
        text: config.TranslateLogin || textConstants.login
        enabled: config.AllowEmptyPassword == "true" || (username.text.length > 0 && password.text.length > 0)
        font.family: root.font.family
        font.bold: true
        font.pointSize: root.font.pointSize * 0.92
        background: Rectangle {
            color: loginButton.enabled ? (config.LoginButtonBackgroundColor || "#e0e0e0") : "#333333"
            border.color: loginButton.activeFocus || loginButton.hovered ? "#ffffff" : "#e0e0e0"
            border.width: 1
            radius: config.RoundCorners !== "" ? Number(config.RoundCorners) : 0
        }
        contentItem: Text {
            text: loginButton.text
            color: loginButton.enabled ? (config.LoginButtonTextColor || "#000000") : "#888888"
            font: loginButton.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: login()
    }

    function login() {
        const user = config.AllowUppercaseLettersInUsernames == "false" ? username.text.toLowerCase() : username.text
        sddm.login(user, password.text, inputContainer.selectedSession)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            failed = true
            resetFailure.restart()
        }
    }

    Timer {
        id: resetFailure
        interval: 3500
        repeat: false
        onTriggered: failed = false
    }
}
