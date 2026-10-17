// Компонент: управление плеером - счётчик времени, слайдер позиции, кнопки

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtMultimedia

Column {
    id: root

    // Плеер и аудиовыход передаются снаружи
    property var player: null
    property var audioOut: null

    // Наружу: пользователь нажал кнопку/перемотал слайдер
    signal prevClicked()
    signal nextClicked()
    signal seekRequested(real pos)

    // Состояние слайдера: пока тащат - игнор player.position
    property bool isSeeking: false
    property real seekValue: 0

    spacing: 20

    // УТИЛИТА: миллисекунды в "м:сс"
    function fmt(ms) {
        if (!ms || ms < 0) return "0:00"
        var totalSec = Math.floor(ms / 1000)
        var m = Math.floor(totalSec / 60)
        var s = totalSec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // Счётчик времени
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#a6adc8"
        font.pixelSize: 14
        text: root.player.source === ""
              ? "Трек не выбран"
              : fmt(root.player.position) + " / " + fmt(root.player.duration)
    }

    // Слайдер позиции
    Slider {
        id: positionSlider
        width: root.width
        from: 0
        to: root.player.duration > 0 ? root.player.duration : 1
        value: root.isSeeking ? root.seekValue : root.player.position
        onMoved: root.seekValue = value

        onPressedChanged: {
            root.isSeeking = pressed
            if (!pressed) {
                root.seekRequested(root.seekValue)
            }
        }
    }

    // Кнопки управления
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Button {
            text: "◀"
            implicitWidth: 60
            onClicked: root.prevClicked()
        }

        Button {
            text: root.player.playbackState === MediaPlayer.PlayingState
                  ? "Пауза" : "Играть"
            implicitWidth: 100
            onClicked: {
                if (root.player.playbackState === MediaPlayer.PlayingState)
                    root.player.pause()
                else
                    root.player.play()
            }
        }

        Button {
            text: "Стоп"
            implicitWidth: 80
            onClicked: root.player.stop()
        }

        Button {
            text: "▶"
            implicitWidth: 60
            onClicked: root.nextClicked()
        }
    }
}