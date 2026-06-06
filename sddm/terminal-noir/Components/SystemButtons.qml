import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    id: systemButtons

    spacing: 14

    property var actions: [
        { "label": config.TranslateSuspend || "SUSPEND", "enabled": sddm.canSuspend, "action": "suspend" },
        { "label": config.TranslateReboot || "REBOOT", "enabled": sddm.canReboot, "action": "reboot" },
        { "label": config.TranslateShutdown || "SHUTDOWN", "enabled": sddm.canPowerOff, "action": "shutdown" }
    ]

    Repeater {
        model: systemButtons.actions

        Button {
            required property var modelData
            Layout.preferredWidth: 104
            Layout.preferredHeight: 34
            visible: config.HideSystemButtons != "true"
            enabled: config.BypassSystemButtonsChecks == "true" || modelData.enabled
            text: modelData.label
            font.family: root.font.family
            font.pointSize: root.font.pointSize * 0.76
            font.bold: true
            background: Rectangle {
                color: parent.hovered || parent.activeFocus ? "#e0e0e0" : "#0a0a0a"
                opacity: parent.enabled ? 0.82 : 0.34
                border.color: parent.hovered || parent.activeFocus ? "#ffffff" : "#333333"
                border.width: 1
                radius: config.RoundCorners !== "" ? Number(config.RoundCorners) : 0
            }
            contentItem: Text {
                text: parent.text
                color: parent.hovered || parent.activeFocus ? "#000000" : (config.SystemButtonsIconsColor || "#c8c8c8")
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: systemButtons.runAction(modelData.action)
        }
    }

    function runAction(action) {
        if (action === "suspend") {
            sddm.suspend()
        } else if (action === "reboot") {
            sddm.reboot()
        } else if (action === "shutdown") {
            sddm.powerOff()
        }
    }
}
