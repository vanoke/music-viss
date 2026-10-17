"""
Точка входа приложения Music Visualizer + Lyrics Sync.

Относится к Модулю 1, тема 1.1 (знакомство с Qt/Quick).
"""

import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


def main() -> int:
    # QGuiApplication - базовое приложение Qt, одно на процесс
    app = QGuiApplication(sys.argv)

    # Движок QML: загрузит qml/main.qml и построит по нему дерево объектов
    engine = QQmlApplicationEngine()

    # Путь к main.qml через Path(__file__).parent так путь не зависит от того, из какой папки запущен скрипт
    qml_file = Path(__file__).parent / "qml" / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        return -1

    # Цикл обработки событий - здесь приложение живёт, пока не закроют окно.
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())