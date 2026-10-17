// Этап 4: интеграция с Python (mutagen)
// Модуль 2.4 (Компоненты), 4.1 (Работа с файлами), мост QML-Python

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtMultimedia
import "components"

ApplicationWindow {
    id: root

    width: 900
    height: 600
    visible: true
    title: qsTr("Music Visualizer")

    Material.theme: Material.Dark
    Material.accent: Material.Blue

    //      ЛОГИКА

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
    // за это время FFmpeg освободит поток
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

    // Свойства для слайдера: при перетаскивании - игнор player.position. от дергания. теперь в PlayerControls.qml 
    // УТИЛИТА: миллисекунды в "м:сс" теперь в PlayerControls.qml

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
                var url = selectedFiles[i].toString()

                // ЭТАП 4 МОСТ. вызов Python-моста для чтения тегов
                // bridge.readTags(url) возвращает объект {title, artist, coverPath}
                var tags = bridge.readTags(url)

                playlistModel.append({
                    // Если тега нет (tags.title пустой), используем имя файла
                    title: tags.title || fileNameFromUrl(url),
                    // сохранение исполнителя и путь к обложке в модель
                    artist: tags.artist || "",
                    coverPath: tags.coverPath || "",
                    path: url
                })
            }
            if (currentTrackIndex === -1 && playlistModel.count > 0) {
                playTrackAt(0)
            }
        }
    }

    //      UI
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
            // Компонент получает модель и индекс, а при клике отправляет сигнал trackClicked
            PlaylistView {
                width: parent.width
                height: 200
                listModel: playlistModel
                currentIndex: root.currentTrackIndex
                onTrackClicked: root.playTrackAt(index)
            }

            // СЛАЙДЕР ПОЗИЦИИ и КНОПКИ УПРАВЛЕНИЯ
            // Компонент получает плеер и аудиовыход, а наружу отправляет сигналы
            PlayerControls {
                width: parent.width
                player: player
                audioOut: audioOut
                onPrevClicked: root.prevTrack()
                onNextClicked: root.nextTrack()
                onSeekRequested: function(pos) {
                    audioOut.volume = 0
                    player.position = pos
                    restoreVolumeTimer.start()
                }
            }
        }
    }
}