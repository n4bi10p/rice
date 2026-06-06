import QtQuick 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: form

    spacing: 14

    Clock {
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height * 0.36
    }

    Input {
        id: input
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height * 0.32
        selectedSession: sessionButton.selectedSession
    }

    VirtualKeyboardButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: parent.height * 0.06
    }

    SystemButtons {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: parent.height * 0.1
    }

    SessionButton {
        id: sessionButton
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: parent.height * 0.07
    }
}
