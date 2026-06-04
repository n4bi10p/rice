import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: store

    property bool ready: false
    property alias wallpaperPath: adapter.wallpaperPath
    property alias blurEnabled: adapter.blurEnabled
    property alias mediaWidgetEnabled: adapter.mediaWidgetEnabled
    property alias statsWidgetEnabled: adapter.statsWidgetEnabled
    property alias notificationPopupsEnabled: adapter.notificationPopupsEnabled
    property alias calendarEnabled: adapter.calendarEnabled
    property alias quickPanelDetailsEnabled: adapter.quickPanelDetailsEnabled
    property alias barNetworkEnabled: adapter.barNetworkEnabled
    property alias barAudioEnabled: adapter.barAudioEnabled
    property alias barBluetoothEnabled: adapter.barBluetoothEnabled
    property alias barNotificationsEnabled: adapter.barNotificationsEnabled

    signal saved()

    Component.onCompleted: {
        settingsFile.adapter = adapter
    }

    function save() {
        saveTimer.restart()
    }

    function saveImmediate() {
        settingsFile.writeAdapter()
        store.ready = true
        store.saved()
    }

    Timer {
        id: saveTimer
        interval: 350
        repeat: false
        onTriggered: store.saveImmediate()
    }

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: {
            if (store.ready)
                saveTimer.restart()
        }
        onLoaded: {
            store.ready = true
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                store.saveImmediate()
        }
    }

    JsonAdapter {
        id: adapter

        property string wallpaperPath: Quickshell.env("HOME") + "/.config/wall/catwall.png"
        property bool blurEnabled: true
        property bool mediaWidgetEnabled: true
        property bool statsWidgetEnabled: true
        property bool notificationPopupsEnabled: true
        property bool calendarEnabled: true
        property bool quickPanelDetailsEnabled: true
        property bool barNetworkEnabled: true
        property bool barAudioEnabled: true
        property bool barBluetoothEnabled: true
        property bool barNotificationsEnabled: true
    }
}
