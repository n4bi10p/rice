import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

ColumnLayout {
    id: clock

    property date currentDate: new Date()

    spacing: 4

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.currentDate = new Date()
    }

    Item { Layout.fillHeight: true }

    QQC2.Label {
        Layout.fillWidth: true
        text: config.HeaderText || "TERMINAL NOIR"
        color: config.HeaderTextColor || "#ffffff"
        font.family: root.font.family
        font.pointSize: root.font.pointSize * 0.86
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.QtRendering
    }

    QQC2.Label {
        Layout.fillWidth: true
        text: Qt.formatTime(clock.currentDate, config.HourFormat || "HH:mm")
        color: config.TimeTextColor || "#ffffff"
        font.family: root.font.family
        font.pointSize: root.font.pointSize * 5.4
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.QtRendering
    }

    QQC2.Label {
        Layout.fillWidth: true
        text: Qt.formatDate(clock.currentDate, config.DateFormat || "dddd d MMMM").toUpperCase()
        color: config.DateTextColor || "#b0b0b0"
        font.family: root.font.family
        font.pointSize: root.font.pointSize * 1.05
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.QtRendering
    }
}
