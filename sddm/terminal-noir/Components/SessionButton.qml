import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: sessionButton

    width: parent.width
    height: root.font.pointSize * 2

    property int selectedSession: selectSession.currentIndex

    ComboBox {
        id: selectSession
        anchors.centerIn: parent
        width: Math.min(parent.width, 260)
        height: root.font.pointSize * 2
        model: sessionModel
        currentIndex: model.lastIndex
        textRole: "name"
        font.family: root.font.family
        font.pointSize: root.font.pointSize * 0.8

        indicator: Item {
            width: 0
            height: 0
        }

        contentItem: Text {
            text: (config.TranslateSessionSelection || "Session") + " (" + selectSession.currentText + ")"
            color: config.SessionButtonTextColor || "#c8c8c8"
            font: selectSession.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: selectSession.hovered || selectSession.activeFocus ? "#111111" : "transparent"
            border.color: selectSession.hovered || selectSession.activeFocus ? "#333333" : "transparent"
            border.width: 1
            radius: config.RoundCorners !== "" ? Number(config.RoundCorners) : 0
        }

        delegate: ItemDelegate {
            width: selectSession.width
            contentItem: Text {
                text: model.name
                color: selectSession.highlightedIndex === index ? (config.DropdownSelectedTextColor || "#000000") : (config.DropdownTextColor || "#e0e0e0")
                font: selectSession.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: selectSession.highlightedIndex === index ? (config.DropdownSelectedBackgroundColor || "#e0e0e0") : "transparent"
            }
        }

        popup: Popup {
            y: selectSession.height
            width: selectSession.width
            implicitHeight: contentItem.implicitHeight
            padding: 8
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: selectSession.popup.visible ? selectSession.delegateModel : null
                currentIndex: selectSession.highlightedIndex
            }
            background: Rectangle {
                color: config.DropdownBackgroundColor || "#0a0a0a"
                border.color: "#333333"
                border.width: 1
                radius: config.RoundCorners !== "" ? Number(config.RoundCorners) : 0
            }
        }
    }
}
