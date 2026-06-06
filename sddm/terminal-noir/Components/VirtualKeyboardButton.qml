import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2

Item {
    id: keyboardToggle

    width: root.font.pointSize * 12
    height: root.font.pointSize * 2.2

    QQC2.Button {
        id: toggleButton

        anchors.fill: parent
        visible: virtualKeyboard.status == Loader.Ready && config.HideVirtualKeyboard != "true"
        checkable: true
        checked: root.virtualKeyboardManual
        focusPolicy: Qt.NoFocus
        text: checked ? (config.TranslateVirtualKeyboardButtonOn || "KEYBOARD ON") : (config.TranslateVirtualKeyboardButtonOff || "KEYBOARD OFF")
        font.family: root.font.family
        font.pointSize: root.font.pointSize * 0.76
        font.bold: true
        onClicked: virtualKeyboard.switchState()

        contentItem: Text {
            text: toggleButton.text
            color: toggleButton.checked ? (config.LoginButtonTextColor || "#000000") : (toggleButton.hovered ? (config.HoverVirtualKeyboardButtonTextColor || "#ffffff") : (config.VirtualKeyboardButtonTextColor || "#888888"))
            font: toggleButton.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: toggleButton.checked ? "#e0e0e0" : "transparent"
            opacity: toggleButton.enabled ? 0.88 : 0.35
            border.color: toggleButton.hovered || toggleButton.checked ? "#e0e0e0" : "#333333"
            border.width: 1
            radius: config.RoundCorners !== "" ? Number(config.RoundCorners) : 0
        }
    }
}
