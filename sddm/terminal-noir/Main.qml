import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQuick.Effects
import SddmComponents 2.0

import "Components"

QQC2.Pane {
    id: root

    width: Screen.width
    height: Screen.height
    padding: 0
    focus: true

    palette.window: config.BackgroundColor || "#000000"
    font.family: config.Font || "JetBrains Mono"
    font.pointSize: config.FontSize !== "" ? config.FontSize : 13

    Item {
        anchors.fill: parent

        Image {
            id: backgroundImage
            anchors.fill: parent
            source: config.Background || "background.png"
            fillMode: config.CropBackground == "false" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
        }

        Rectangle {
            anchors.fill: parent
            color: config.DimBackgroundColor || "#000000"
            opacity: config.DimBackground !== "" ? Number(config.DimBackground) : 0.42
        }

        ShaderEffectSource {
            id: blurSource
            anchors.fill: loginSurface
            sourceItem: backgroundImage
            sourceRect: Qt.rect(loginSurface.x, loginSurface.y, loginSurface.width, loginSurface.height)
            visible: false
        }

        MultiEffect {
            anchors.fill: loginSurface
            source: config.PartialBlur == "true" ? blurSource : backgroundImage
            blurEnabled: config.PartialBlur == "true" || config.FullBlur == "true"
            blur: config.Blur !== "" ? Number(config.Blur) : 1.0
            blurMax: config.BlurMax !== "" ? Number(config.BlurMax) : 48
            autoPaddingEnabled: false
            visible: blurEnabled
        }

        Rectangle {
            id: loginSurface
            width: Math.min(root.width * 0.42, 520)
            height: Math.min(root.height * 0.68, 620)
            anchors.centerIn: parent
            color: config.FormBackgroundColor || "#080808"
            opacity: config.FormBackgroundOpacity !== "" ? Number(config.FormBackgroundOpacity) : 0.62
            border.color: config.BorderColor || "#333333"
            border.width: 1
            radius: config.RoundCorners !== "" ? Number(config.RoundCorners) : 0
        }

        LoginForm {
            id: loginForm
            anchors.fill: loginSurface
            anchors.margins: Math.max(28, root.height * 0.035)
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#1c1c1c"
            border.width: 1
        }
    }
}
