// Этап 4: интеграция с Python (mutagen).
// Модуль 2.4 (Компоненты), 4.1 (Работа с файлами), плюс мост QML↔Python.

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtMultimedia
import "components"

ApplicationWindow {
    id: root

    width: 900
    height: 750
    visible: true
    title: qsTr("Music Visualizer")

    Material.theme: Material.Dark
    Material.accent: Material.Blue

    // ловится сигнал из Python, когда обложка скачается
    Connections {
        target: bridge
        function onTrackInfoDownloaded(fileUrl, coverPath, correctedTitle, correctedArtist) {
            for (var i = 0; i < playlistModel.count; i++) {
                if (playlistModel.get(i).path === fileUrl) {
                    // обновляется обложка, если она есть
                    if (coverPath) {
                        playlistModel.setProperty(i, "coverPath", coverPath)
                    }
                    // всегда обновляются названия, если iTunes их нашел
                    if (correctedTitle) {
                        playlistModel.setProperty(i, "title", correctedTitle)
                    }
                    if (correctedArtist) {
                        playlistModel.setProperty(i, "artist", correctedArtist)
                    }
                    break
                }
            }
        }
    }

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
    // резкая заглушка перед сменой, тут плавный возврат
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
    // 50 мс после приглушения - за это время FFmpeg освободит поток
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

    // Свойства для слайдера: при перетаскивании - игнор player.position. от дергания
    // (теперь они внутри PlayerControls.qml, оставлены тут для контекста, тк удалены лишние свойства из main.qml)
    // УТИЛИТА: миллисекунды в "м:сс"
    // (также в PlayerControls.qml, тк используется только там)

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

                // вызов Python-моста для чтения тегов
                // bridge.readTags(url) возвращает объект {title, artist, coverPath}
                var tags = bridge.readTags(url)

                playlistModel.append({
                    // если tags.title пустой, используется имя файла
                    title: tags.title || fileNameFromUrl(url),
                    // сохранение исполнителя и путь к обложке в модель
                    artist: tags.artist || "",
                    coverPath: tags.coverPath || "",
                    path: url
                })

                if (!tags.coverPath) {
                    bridge.fetchInfo(url, tags.artist, tags.title)
                }
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
            id: mainColumn
            anchors.centerIn: parent
            spacing: 20
            width: parent.width * 0.85

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Pulse"
                color: "white"
                font.pixelSize: 32
                font.bold: true
                font.letterSpacing: 2
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
            // (код ListView и делегата теперь в components/PlaylistView.qml)
            // компонент получает модель и индекс, а при клике отправляет сигнал trackClicked
            PlaylistView {
                width: mainColumn.width
                height: 250
                listModel: playlistModel
                currentIndex: root.currentTrackIndex
                onTrackClicked: function(index) { root.playTrackAt(index) }
            }


            // Визуализация звука
            Visualizer {
                    width: parent.width
                    height: 80 // область визуализации. ширина у mainColumn
                    // состояние плеера: если PlayingState - рисует
                    isPlaying: player.playbackState === MediaPlayer.PlayingState
            }


            // СЛАЙДЕР ПОЗИЦИИ и КНОПКИ УПРАВЛЕНИЯ
            // (в components/PlayerControls.qml)
            // Компонент получает плеер и аудиовыход, а наружу отправляет сигналы prevClicked, nextClicked и seekRequested.
            PlayerControls {
                width: mainColumn.width
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