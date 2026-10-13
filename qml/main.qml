// Этап 2: воспроизведение MP3.
// Модуль 4.2 (Мультимедиа), 3.4 (Button, Slider), 3.1 (FileDialog).

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtMultimedia
import QtQuick.Controls.Material

ApplicationWindow {
    id: root

    width: 900
    height: 600
    visible: true
    title: qsTr("Music Visualizer")
    Material.theme: Material.Dark
    Material.accent: Material.Blue

    // МЕДИАПЛЕЕР
    // MediaPlayer знает, что играть. AudioOutput - куда выводить звук
    MediaPlayer {
        id: player

        audioOutput: AudioOutput {
            id: audioOut
            volume: 0.8
        }

        onErrorOccurred: function(error, errorString) {
            console.log("MediaPlayer error:", error, errorString)
        }
    }

    // ТАЙМЕР ВОССТАНОВЛЕНИЯ ГРОМКОСТИ
    // Возвращает звук после seek'а — иначе он остаётся заглушённым
    Timer {
        id: restoreVolumeTimer
        interval: 80
        onTriggered: audioOut.volume = 0.8
    }

    // УТИЛИТА
    // Миллисекунды в "м:сс". Используется для позиции и длительности
    function fmt(ms) {
        if (!ms || ms < 0) return "0:00"
        var totalSec = Math.floor(ms / 1000)
        var m = Math.floor(totalSec / 60)
        var s = totalSec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // ДИАЛОГ ВЫБОРА ФАЙЛА
    // selectedFile - URL (file:///...), MediaPlayer принимает именно URL
    FileDialog {
        id: fileDialog
        title: "Выберите MP3-файл"
        nameFilters: ["MP3 (*.mp3)", "Все файлы (*)"]

        onAccepted: {
            player.source = selectedFile
            player.play()
        }
    }

    // UI
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"

        Column {
            anchors.centerIn: parent
            spacing: 20
            width: parent.width * 0.8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Music Visualizer + Lyrics Sync"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Открыть MP3"
                onClicked: fileDialog.open()
            }

            // Счётчик времени: позиция / длительность.
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#a6adc8"
                font.pixelSize: 14
                text: player.source === ""
                      ? "Файл не выбран"
                      : fmt(player.position) + " / " + fmt(player.duration)
            }

            // СЛАЙДЕР ПОЗИЦИИ
            Slider {
                id: positionSlider
                width: parent.width
                from: 0
                to: player.duration > 0 ? player.duration : 1
                value: player.position

                // Перемотка только после отжатия.
                // Иначе FFmpeg перезапускает поток на каждом пикселе (фикс хрипения)
                onPressedChanged: {
                    if (!pressed) {
                        // Глушим звук на момент seek'а — FFmpeg пересоздаёт поток ~50 мс
                        audioOut.volume = 0
                        player.position = value
                        restoreVolumeTimer.start()
                    }
                }
            }

            // КНОПКИ УПРАВЛЕНИЯ
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                // Play/Pause с двумя состояниями.
                // После Paused play() продолжает, после Stopped - начинает с начала
                Button {
                    text: player.playbackState === MediaPlayer.PlayingState
                          ? "Пауза" : "Играть"
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState)
                            player.pause()
                        else
                            player.play()
                    }
                }

                Button {
                    text: "Стоп"
                    onClicked: player.stop()
                }
            }
        }
    }
}