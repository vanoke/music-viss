// Главное окно приложения. Пока заглушка — «точка входа» QML.
// Относится к Модулю 1, темы 1.4 (язык QML) и 1.5 (визуальные типы).

import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: root

    width: 900
    height: 600
    visible: true
    title: qsTr("Music Visualizer")

    // Тёмный Rectangle на весь фон окна.
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"

        Column {
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Music Visualizer + Lyrics Sync"
                color: "white"
                font.pixelSize: 28
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Qt Quick / PySide6 — этап 1"
                color: "#a6adc8"
                font.pixelSize: 16
            }
        }
    }
}