// Этап 4: интеграция с Python (mutagen).
// Модуль 2.4 (Компоненты), 4.1 (Работа с файлами), плюс мост QML↔Python.

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtMultimedia
import QtQuick.Layouts
import "components"
import "utils.js" as Utils 

ApplicationWindow {
    id: root

    width: 1000
    height: 750
    visible: true
    title: qsTr("Pulse")

    minimumWidth: 800
    minimumHeight: 600

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

        onPositionChanged: {
            if (lyricsModel.count > 0) {
                updateCurrentLyric()
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

    ListModel {
        id: lyricsModel
    }

    property int currentTrackIndex: -1
    property int currentLyricIndex: -1 // индекс текущей поющейся строки

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


        // загрузка LRC при смене трека
        lyricsModel.clear()
        currentLyricIndex = -1
        var item = playlistModel.get(index)
        var lrcText = bridge.readLRC(item.path)

        if (lrcText) {
            var parsed = Utils.parseLRC(lrcText)
            for (var i = 0; i < parsed.length; i++) {
                lyricsModel.append(parsed[i])
            }
        }


        // Резкое заглушение
        fadeIn.stop()
        audioOut.volume = 0

        switchTrackTimer.restart()
    }


    // поиск текущей строки
    function updateCurrentLyric() {
        var pos = player.position
        var newIndex = -1
        
        // поиск последней строки, время которой меньше текущей позиции
        for (var i = 0; i < lyricsModel.count; i++) {
            if (lyricsModel.get(i).time <= pos) {
                newIndex = i
            } else {
                break // далее искать нет смысла
            }
        }
        
        if (newIndex !== currentLyricIndex) {
            currentLyricIndex = newIndex
        }
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

        // верхняя зона Header
        Column {
            id: headerSection
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 15

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
                        lyricsModel.clear()
                        currentTrackIndex = -1
                        player.stop()
                        player.source = ""
                        audioOut.volume = 0.8
                    }
                }
            }
        }

        // нижняя зона Footer
        PlayerControls {
            id: footerSection
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.8, 800) // Ограничитель ширины

            // СЛАЙДЕР ПОЗИЦИИ и КНОПКИ УПРАВЛЕНИЯ
            // (в components/PlayerControls.qml)
            // Компонент получает плеер и аудиовыход, а наружу отправляет сигналы prevClicked, nextClicked и seekRequested.
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

        // центральная зона Body
        ColumnLayout {
            id: centerSection
            anchors.top: headerSection.bottom
            anchors.bottom: footerSection.top
            anchors.topMargin: 20
            anchors.bottomMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.8, 800) // Ограничитель ширины
            spacing: 15

            // ПЛЕЙЛИСТ
            // (код ListView и делегата теперь в components/PlaylistView.qml)
            // компонент получает модель и индекс, а при клике отправляет сигнал trackClicked
            PlaylistView {
                Layout.fillWidth: true
                Layout.fillHeight: true // cписок занимает всё свободное место
                listModel: playlistModel
                currentIndex: root.currentTrackIndex
                onTrackClicked: function(index) { root.playTrackAt(index) }
            }

            // Блок караоке
            Rectangle {
                Layout.fillWidth: true // НОВОЕ
                Layout.preferredHeight: 140 // НОВОЕ
                color: "#2a2a3e"
                radius: 8
                border.color: "#45475a"
                border.width: 1
                
                LyricsView {
                    anchors.fill: parent
                    anchors.margins: 10
                    lyricsModel: lyricsModel
                    currentLine: root.currentLyricIndex

                    // клик по тексту для перемотки трека
                    onLyricClicked: function(timeMs) {
                        player.position = timeMs
                    }
                }
            }

            // Визуализация звука
            Visualizer {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                // состояние плеера: если PlayingState - рисует
                isPlaying: player.playbackState === MediaPlayer.PlayingState
            }
        }
    }
}