// Компонент: Караоке-текст песен.
// Модуль 3.3 (Текст), 2.5 (Модели).

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Rectangle {
    id: root
    
    property var lyricsModel: null
    property int currentLine: -1

    signal lyricClicked(int timeMs)
    
    color: "transparent"
    clip: true


    // авто прокрутка к текущей строке
    onCurrentLineChanged: {
        if (currentLine >= 0) {
            // прокрутка строки по центру
            lyricsView.positionViewAtIndex(currentLine, ListView.Center)
        }
    }


    ListView {
        id: lyricsView
        anchors.fill: parent
        model: root.lyricsModel
        spacing: 15
        // откл интерактивной прокрутки, будет программно
        interactive: false 
        
        delegate: Text {
            width: lyricsView.width
            horizontalAlignment: Text.AlignHCenter
            text: model.text // текст из модели
            font.pixelSize: 18
            font.bold: index === root.currentLine
            
            // подсветка текущей строки
            color: index === root.currentLine ? "white" : "#6c7086"
            
            // плавный переход цвета
            Behavior on color { ColorAnimation { duration: 200 } }

            // фиксируется клик по строке
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHangCursor
                onClicked: root.lyricClicked(model.time) // отдача времени строки в мейн
            }
        }
    }
}