// Компонент: Визуализация звука (спектр-бары).
// Модуль 1.5 (Canvas), 2.3 (Анимации).

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Rectangle {
    id: root
    
    // передается снаружи, играет ли музыка сейчас
    property bool isPlaying: false
    
    color: "transparent"
    
    // Таймер для обновления анимации (~60 кадров в секунду)
    Timer {
        interval: 16
        running: root.isPlaying
        repeat: true
        onTriggered: canvas.requestPaint()
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        
        // массив для хранения текущих высот баров (для сглаживания)
        property var barHeights: []
        property real phase: 0 // фаза для волны
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            
            var barCount = 40          // количество полосок
            var barWidth = width / barCount
            var gap = 2                // расстояние между полосками
            
            // если массив пустой - иниц нулями
            if (barHeights.length !== barCount) {
                barHeights = []
                for (var j = 0; j < barCount; j++) {
                    barHeights.push(0)
                }
            }
            
            // увеличивается фаза для движения волны
            phase += 0.1

            // рисуется каждый бар
            for (var i = 0; i < barCount; i++) {
                var targetHeight = 0
                
                if (root.isPlaying) {
                    // изменил на волну вместо хаотичности
                    // синус создает "волну", от индекса бара и фазы
                    var wave = Math.abs(Math.sin(i * 0.2 + phase))
                    targetHeight = (Math.random() * 0.3 + wave * 0.7) * height
                }
                
                // плавное сглаживание (чтобы полоски не дергались резко)
                barHeights[i] += (targetHeight - barHeights[i]) * 0.2
                
                var x = i * barWidth + gap
                var y = height - barHeights[i]
                var w = barWidth - gap * 2
                var h = barHeights[i]
                
                // градиент
                var gradient = ctx.createLinearGradient(0, height, 0, 0)
                gradient.addColorStop(0, "#89b4fa") 
                gradient.addColorStop(1, "#cba6f7") 
                
                ctx.fillStyle = gradient
                ctx.fillRect(x, y, w, h)
            }
        }
    }
}