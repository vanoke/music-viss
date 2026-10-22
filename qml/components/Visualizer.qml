// Компонент: Визуализация звука (спектр-бары).
// Модуль 1.5 (Canvas), 2.3 (Анимации).

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Rectangle {
    id: root
    
    // передается снаружи main.qml, играет ли музыка сейчас
    property bool isPlaying: false
    
    color: "transparent"
    
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
                    barHeights.push(2)
                }
            }
            
            // увеличивается фаза для движения волны
            phase += 0.15

            // рисуется каждый бар
            for (var i = 0; i < barCount; i++) {
                var targetHeight = 2
                
                if (root.isPlaying) {
                    // изменил на волну вместо хаотичности
                    // мат волна син+кос
                    var wave1 = Math.sin(i * 0.2 + phase) * 0.5 + 0.5
                    var wave2 = Math.cos(i * 0.1 - phase * 1.5) * 0.5 + 0.5
                    targetHeight = (wave1 * 0.5 + wave2 * 0.4 + Math.random() * 0.1) * height
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

    // работает всегда, чтобы канвас перерис.
    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: canvas.requestPaint()
    }


}