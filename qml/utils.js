// Парсер LRC-файлов (Модуль 2.1: JS-библиотеки)

function parseLRC(lrcText) {
    var lines = lrcText.split('\n')
    var result = []
    
    // регулярное выражение для поиска [mm:ss.xx]
    var regex = /\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)/
    
    for (var i = 0; i < lines.length; i++) {
        var match = lines[i].match(regex)
        if (match) {
            var minutes = parseInt(match[1])
            var seconds = parseInt(match[2])
            var milliseconds = parseInt(match[3])
            
            // если сотые - * на 10 = миллисекунды
            if (match[3].length === 2) {
                milliseconds *= 10
            }
            
            var totalMs = (minutes * 60 + seconds) * 1000 + milliseconds
            var text = match[4].trim()
            
            if (text !== "") {
                result.push({ time: totalMs, text: text })
            }
        }
    }
    return result
}