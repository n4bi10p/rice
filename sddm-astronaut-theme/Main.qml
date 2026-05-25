// ===========================================================================
// SDDM ASTROUNAUT THEME - MODIFIED FOR RICE
// ===========================================================================

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height

    // Pitch black background
    color: "#000000"

    // Set font globally
    FontLoader { id: jetbrainsMono; source: "qrc:/sddm/themes/sddm-astronaut-theme/fonts/JetBrainsMono-Regular.ttf" }

    // This is typically for showing the desktop wallpaper in the background.
    // We're keeping it black as per your request, the wallpaper will be handled by theme.sh
    Image {
        id: wallpaper
        anchors.fill: parent
        source: theme.background
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width
        sourceSize.height: root.height
        // Ensure pure black if no image is set or image is transparent
        layer.enabled: true
        layer.effect: ShaderEffect {
            property color overlayColor: "#000000"
            fragmentShader: "
                #version 150
                uniform sampler2D source;
                uniform lowp float qt_Opacity;
                uniform highp vec4 overlayColor;
                void main() {
                    gl_FragColor = texture2D(source, qt_TexCoord0) * overlayColor * qt_Opacity;
                }
            "
        }
    }


    // --- MAIN LAYOUT ---
    GridLayout {
        id: mainLayout
        anchors.centerIn: parent
        columns: 1
        rowSpacing: 20

        // Clock
        Label {
            text: Qt.formatTime(systemd.currentTime, "hh:mm")
            font.pixelSize: 80
            font.family: jetbrainsMono.name
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        // Date
        Label {
            text: Qt.formatDate(systemd.currentTime, "ddd, MMM d")
            font.pixelSize: 24
            font.family: jetbrainsMono.name
            color: "#e0e0e0"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        // User list (if enabled in sddm.conf, otherwise just login)
        ListView {
            Layout.preferredWidth: 300
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignHCenter
            spacing: 5
            model: sddm.users
            interactive: false // Selection via input field is preferred

            delegate: Rectangle {
                width: parent.width
                height: 40
                color: "transparent"
                border.width: 0

                MouseArea {
                    anchors.fill: parent
                    onClicked: sddm.login(model.name)
                }

                Label {
                    anchors.centerIn: parent
                    text: model.realName
                    font.pixelSize: 20
                    font.family: jetbrainsMono.name
                    color: sddm.username === model.name ? "#ffffff" : "#e0e0e0" // Highlight selected user
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Login Box
        Rectangle {
            Layout.preferredWidth: 300
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignHCenter
            color: "#111111" // Dark grey background for login box
            border.color: "#2a2a2a"
            border.width: 2
            radius: 0 // CRITICAL: No rounding

            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                padding: 15

                TextField {
                    id: usernameInput
                    Layout.fillWidth: true
                    placeholderText: "Username"
                    font.family: jetbrainsMono.name
                    font.pixelSize: 16
                    color: "#ffffff"
                    selectionColor: "#555555"
                    selectedTextColor: "#ffffff"
                    background: Rectangle {
                        color: "#1c1c1c" // Darker input background
                        border.color: "#2a2a2a"
                        border.width: 1
                        radius: 0 // CRITICAL: No rounding
                    }
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            passwordInput.forceActiveFocus();
                            event.accepted = true;
                        }
                    }
                    Component.onCompleted: {
                        if (sddm.users.length > 0) {
                            sddm.currentUsername = sddm.users[0].name;
                        }
                        usernameInput.focus = true;
                    }
                }

                TextField {
                    id: passwordInput
                    Layout.fillWidth: true
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    font.family: jetbrainsMono.name
                    font.pixelSize: 16
                    color: "#ffffff"
                    selectionColor: "#555555"
                    selectedTextColor: "#ffffff"
                    background: Rectangle {
                        color: "#1c1c1c" // Darker input background
                        border.color: "#2a2a2a"
                        border.width: 1
                        radius: 0 // CRITICAL: No rounding
                    }
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(sddm.currentUsername, passwordInput.text);
                            event.accepted = true;
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: sddm.lastLoginMessage
                    font.family: jetbrainsMono.name
                    font.pixelSize: 12
                    color: "#888888" // Medium grey for messages
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Login Button
        Button {
            id: loginButton
            Layout.fillWidth: true
            Layout.preferredWidth: 300
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignHCenter
            text: "Login"
            font.family: jetbrainsMono.name
            font.pixelSize: 18
            background: Rectangle {
                color: "#2a2a2a" // Dark grey button background
                border.color: "#555555"
                border.width: 2
                radius: 0 // CRITICAL: No rounding
                opacity: loginButton.pressed ? 0.8 : 1
            }
            contentItem: Label {
                text: parent.text
                font: parent.font
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: sddm.login(sddm.currentUsername, passwordInput.text)
        }
    }

    // --- Bottom Bar for Session/Keyboard ---
    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: 15
        Layout.bottomMargin: 20

        ComboBox {
            id: sessionSelector
            Layout.preferredWidth: 150
            Layout.preferredHeight: 35
            font.family: jetbrainsMono.name
            font.pixelSize: 14
            background: Rectangle {
                color: "#1c1c1c"
                border.color: "#2a2a2a"
                border.width: 1
                radius: 0
            }
            contentItem: Label {
                text: sessionSelector.displayText
                font: sessionSelector.font
                color: "#e0e0e0"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            popup: Pane {
                background: Rectangle {
                    color: "#0a0a0a"
                    border.color: "#555555"
                    border.width: 1
                    radius: 0
                }
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0
                ListView {
                    model: sddm.sessionDisplayNames
                    delegate: ItemDelegate {
                        width: sessionSelector.width
                        height: 30
                        background: Rectangle {
                            color: control.highlighted ? "#2a2a2a" : "#0a0a0a"
                            radius: 0
                        }
                        Label {
                            anchors.centerIn: parent
                            text: model.modelData
                            font.family: jetbrainsMono.name
                            font.pixelSize: 14
                            color: control.highlighted ? "#ffffff" : "#e0e0e0"
                        }
                        onClicked: {
                            sessionSelector.currentIndex = index
                            sessionSelector.close()
                        }
                    }
                }
            }
            model: sddm.sessionDisplayNames
            onCurrentIndexChanged: {
                sddm.currentSession = sddm.session[sessionSelector.currentIndex]
            }
            Component.onCompleted: {
                sddm.currentSession = sddm.session[sessionSelector.currentIndex]
            }
        }

        ComboBox {
            id: keyboardSelector
            Layout.preferredWidth: 150
            Layout.preferredHeight: 35
            font.family: jetbrainsMono.name
            font.pixelSize: 14
            background: Rectangle {
                color: "#1c1c1c"
                border.color: "#2a2a2a"
                border.width: 1
                radius: 0
            }
            contentItem: Label {
                text: keyboardSelector.displayText
                font: keyboardSelector.font
                color: "#e0e0e0"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            popup: Pane {
                background: Rectangle {
                    color: "#0a0a0a"
                    border.color: "#555555"
                    border.width: 1
                    radius: 0
                }
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0
                ListView {
                    model: sddm.keyboardLayoutDisplayNames
                    delegate: ItemDelegate {
                        width: keyboardSelector.width
                        height: 30
                        background: Rectangle {
                            color: control.highlighted ? "#2a2a2a" : "#0a0a0a"
                            radius: 0
                        }
                        Label {
                            anchors.centerIn: parent
                            text: model.modelData
                            font.family: jetbrainsMono.name
                            font.pixelSize: 14
                            color: control.highlighted ? "#ffffff" : "#e0e0e0"
                        }
                        onClicked: {
                            keyboardSelector.currentIndex = index
                            keyboardSelector.close()
                        }
                    }
                }
            }
            model: sddm.keyboardLayoutDisplayNames
            onCurrentIndexChanged: {
                sddm.currentKeyboardLayout = sddm.keyboardLayout[keyboardSelector.currentIndex]
            }
            Component.onCompleted: {
                sddm.currentKeyboardLayout = sddm.keyboardLayout[keyboardSelector.currentIndex]
            }
        }
    }
}
