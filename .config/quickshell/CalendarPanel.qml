import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: calendarPanel

    anchors {
        top: true
        left: true
    }
    margins {
        top: 32
        left: Math.max(0, Math.round(((screen ? screen.width : 1920) - implicitWidth) / 2))
    }

    implicitWidth: 330
    implicitHeight: 320
    color: "#0a0a0a"
    visible: false
    screen: Quickshell.screens[0]
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "calendar-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property date today: new Date()
    property int displayYear: today.getFullYear()
    property int displayMonth: today.getMonth()
    property var monthNames: ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
    property var weekdayNames: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    property var days: []

    function toggle() {
        calendarPanel.visible = !calendarPanel.visible
        if (calendarPanel.visible)
            rebuild()
    }

    function rebuild() {
        const first = new Date(displayYear, displayMonth, 1)
        const daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()
        const prevDays = new Date(displayYear, displayMonth, 0).getDate()
        const cells = []

        for (let i = first.getDay() - 1; i >= 0; i--)
            cells.push({ day: prevDays - i, current: false })

        for (let d = 1; d <= daysInMonth; d++)
            cells.push({ day: d, current: true })

        let nextDay = 1
        while (cells.length < 42)
            cells.push({ day: nextDay++, current: false })

        days = cells
    }

    function shiftMonth(delta) {
        const next = new Date(displayYear, displayMonth + delta, 1)
        displayYear = next.getFullYear()
        displayMonth = next.getMonth()
        rebuild()
    }

    Component.onCompleted: rebuild()

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
        border.color: "#333333"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 8

            Text {
                text: monthNames[displayMonth] + " " + displayYear
                color: "#ffffff"
                font.family: "JetBrains Mono"
                font.bold: true
                font.pixelSize: 14
                Layout.fillWidth: true
            }

            CalendarButton { label: "‹"; onClicked: calendarPanel.shiftMonth(-1) }
            CalendarButton { label: "›"; onClicked: calendarPanel.shiftMonth(1) }
        }

        GridLayout {
            columns: 7
            rowSpacing: 0
            columnSpacing: 0
            Layout.fillWidth: true
            Layout.preferredHeight: 24

            Repeater {
                model: calendarPanel.weekdayNames
                Text {
                    Layout.preferredWidth: 43
                    Layout.preferredHeight: 24
                    text: modelData
                    color: "#888888"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        GridLayout {
            columns: 7
            rowSpacing: 4
            columnSpacing: 4
            Layout.fillWidth: true
            Layout.fillHeight: true

            Repeater {
                model: calendarPanel.days

                Rectangle {
                    readonly property bool isToday: modelData.current
                        && modelData.day === calendarPanel.today.getDate()
                        && calendarPanel.displayMonth === calendarPanel.today.getMonth()
                        && calendarPanel.displayYear === calendarPanel.today.getFullYear()

                    Layout.preferredWidth: 39
                    Layout.preferredHeight: 30
                    color: isToday ? "#e0e0e0" : "transparent"
                    border.color: isToday ? "#ffffff" : (modelData.current ? "#1c1c1c" : "transparent")
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: parent.isToday ? "#000000" : (modelData.current ? "#e0e0e0" : "#444444")
                        font.family: "JetBrains Mono"
                        font.bold: parent.isToday || modelData.current
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    component CalendarButton: Rectangle {
        signal clicked()
        property string label: ""
        Layout.preferredWidth: 26
        Layout.preferredHeight: 24
        color: mouse.containsMouse ? "#1c1c1c" : "#101010"
        border.color: "#333333"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: label
            color: "#e0e0e0"
            font.family: "JetBrains Mono"
            font.bold: true
            font.pixelSize: 14
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
