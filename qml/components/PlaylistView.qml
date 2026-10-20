// Компонент: список треков.

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Rectangle {
    id: root

    // Модель передаётся снаружи - компонент не знает, откуда она
    property var listModel: null
    // Индекс текущего трека для подсветки
    property int currentIndex: -1

    // в main.qml: клик по треку с номером index
    signal trackClicked(int index)

    color: "#2a2a3e"
    radius: 8
    border.color: "#45475a"
    border.width: 1

    ListView {
        id: view
        anchors.fill: parent
        anchors.margins: 4
        clip: true
        spacing: 2
        model: root.listModel

        delegate: Rectangle {
            width: view.width
            height: 36
            radius: 4
            color: index === root.currentIndex ? "#3a3a5e" : "transparent"


            // Миниатюра обложки. Появляется автоматически, когда в модели обновляется coverPath
            Image {
                id: coverImg
                width: 32
                height: 32
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                source: coverPath ? "file:///" + coverPath : ""
                fillMode: Image.PreserveAspectCrop
                visible: coverPath !== ""

                asynchronous: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                // если обложку видно, текст сдвигается правее
                anchors.left: coverPath ? coverImg.right : parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 12
                // artist может быть пустой, тогда только название
                text: (index + 1) + ". " + title + (artist ? " — " + artist : "")
                color: "white"
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.trackClicked(index)
            }
        }
    }

    // Заглушка, когда плейлист пуст
    Text {
        anchors.centerIn: parent
        visible: root.listModel !== null && root.listModel.count === 0
        text: "Плейлист пуст. Нажмите «Добавить треки»."
        color: "#6c7086"
        font.pixelSize: 14
    }
}