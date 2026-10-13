// Этап 3: плейлист на ListModel + ListView.
// Модуль 2.5 (Модели), 2.6 (Представления), 1.6 (Позиционирование).

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtMultimedia

ApplicationWindow {
    id: root

    width: 900
    height: 600
    visible: true
    title: qsTr("Music Visualizer")

    Material.theme: Material.Dark
    Material.accent: Material.Blue

    // МЕДИАПЛЕЕР
    MediaPlayer {
        id: player

        audioOutput: AudioOutput {
            id: audioOut
            volume: 0.8
        }

        onErrorOccurred: function(error, errorString) {
            console.log("MediaPlayer error:", error, errorString)
        }

        // По окончании трека автоматически переход к следующему
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) {
                root.nextTrack()
            }
        }
    }

    // ПЛАВНОЕ НАРАСТАНИЕ ПОСЛЕ СТАРТА
    // резкая заглушка перед сменой, тут плавный возврат.
    NumberAnimation {
        id: fadeIn
        target: audioOut
        property: "volume"
        to: 0.8
        duration: 120
        easing.type: Easing.InQuad
    }

    // ТАЙМЕР ВОССТАНОВЛЕНИЯ ГРОМКОСТИ (для seek'а)
    Timer {
        id: restoreVolumeTimer
        interval: 80
        onTriggered: audioOut.volume = 0.8
    }

    // ТАЙМЕР СМЕНЫ ТРЕКА
    // 50 мс после приглушения — за это время FFmpeg освободит поток.
    Timer {
        id: switchTrackTimer
        interval: 50
        onTriggered: {
            var item = playlistModel.get(currentTrackIndex)
            player.source = item.path
            player.play()
            fadeIn.start()
        }
    }

    // ПЛЕЙЛИСТ (МОДЕЛЬ)
    ListModel {
        id: playlistModel
    }

    property int currentTrackIndex: -1

    // Свойства для слайдера: при перетаскивании — игнор player.position. от дергания.
    property bool isSeeking: false
    property real seekValue: 0

    // УТИЛИТА: миллисекунды в "м:сс"
    function fmt(ms) {
        if (!ms || ms < 0) return "0:00"
        var totalSec = Math.floor(ms / 1000)
        var m = Math.floor(totalSec / 60)
        var s = totalSec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // УТИЛИТА: имя файла из URL
    function fileNameFromUrl(url) {
        var parts = url.toString().split("/")
        return decodeURIComponent(parts[parts.length - 1])
    }

    // ФУНКЦИЯ: включить трек по индексу
    function playTrackAt(index) {
        if (index < 0 || index >= playlistModel.count) return
        currentTrackIndex = index

        // Резкое заглушение
        fadeIn.stop()
        audioOut.volume = 0

        switchTrackTimer.restart()
    }

    // ФУНКЦИЯ: следующий трек
    function nextTrack() {
        if (playlistModel.count === 0) return
        var next = currentTrackIndex + 1
        if (next >= playlistModel.count) next = 0
        playTrackAt(next)
    }

    // ФУНКЦИЯ: предыдущий трек
    function prevTrack() {
        if (playlistModel.count === 0) return
        var prev = currentTrackIndex - 1
        if (prev < 0) prev = playlistModel.count - 1
        playTrackAt(prev)
    }

    // ДИАЛОГ ВЫБОРА ФАЙЛОВ
    FileDialog {
        id: fileDialog
        title: "Выберите MP3-файлы"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["MP3 (*.mp3)", "Все файлы (*)"]

        onAccepted: {
            for (var i = 0; i < selectedFiles.length; i++) {
                var url = selectedFiles[i]
                playlistModel.append({
                    title: fileNameFromUrl(url),
                    path: url.toString()
                })
            }
            if (currentTrackIndex === -1 && playlistModel.count > 0) {
                playTrackAt(0)
            }
        }
    }

    // UI
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"

        Column {
            anchors.centerIn: parent
            spacing: 20
            width: parent.width * 0.85

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Music Visualizer + Lyrics Sync"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Button {
                    text: "Добавить треки"
                    onClicked: fileDialog.open()
                }

                Button {
                    text: "Очистить"
                    onClicked: {
                        fadeIn.stop()
                        switchTrackTimer.stop()
                        playlistModel.clear()
                        currentTrackIndex = -1
                        player.stop()
                        player.source = ""
                        audioOut.volume = 0.8
                    }
                }
            }

            // ПЛЕЙЛИСТ
            Rectangle {
                width: parent.width
                height: 200
                color: "#2a2a3e"
                radius: 8
                border.color: "#45475a"
                border.width: 1

                ListView {
                    id: playlistView
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    spacing: 2
                    model: playlistModel

                    delegate: Rectangle {
                        width: playlistView.width
                        height: 36
                        radius: 4
                        color: index === currentTrackIndex ? "#3a3a5e" : "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            text: (index + 1) + ". " + title
                            color: "white"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.playTrackAt(index)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: playlistModel.count === 0
                    text: "Плейлист пуст. Нажмите «Добавить треки»."
                    color: "#6c7086"
                    font.pixelSize: 14
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#a6adc8"
                font.pixelSize: 14
                text: player.source === ""
                      ? "Трек не выбран"
                      : fmt(player.position) + " / " + fmt(player.duration)
            }

            // СЛАЙДЕР ПОЗИЦИИ
            // Изменение позиции — value берётся из seekValue, position игнорируется.
            Slider {
                id: positionSlider
                width: parent.width
                from: 0
                to: player.duration > 0 ? player.duration : 1
                value: root.isSeeking ? root.seekValue : player.position
                onMoved: root.seekValue = value

                onPressedChanged: {
                    root.isSeeking = pressed
                    if (!pressed) {
                        audioOut.volume = 0
                        player.position = root.seekValue
                        restoreVolumeTimer.start()
                    }
                }
            }

            // КНОПКИ УПРАВЛЕНИЯ
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Button {
                    text: "◀"
                    implicitWidth: 60
                    onClicked: root.prevTrack()
                }

                // implicitWidth фиксирует ширину — иначе смена текста
                Button {
                    text: player.playbackState === MediaPlayer.PlayingState
                          ? "Пауза" : "Играть"
                    implicitWidth: 100
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState)
                            player.pause()
                        else
                            player.play()
                    }
                }

                Button {
                    text: "Стоп"
                    implicitWidth: 80
                    onClicked: player.stop()
                }

                Button {
                    text: "▶"
                    implicitWidth: 60
                    onClicked: root.nextTrack()
                }
            }
        }
    }
}