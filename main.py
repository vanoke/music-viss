"""
Точка входа приложения Music Visualizer + Lyrics Sync.

Относится к Модулю 1, тема 1.1 (знакомство с Qt/Quick).
Плюс регистрация Python-моста (Модуль 4.1).
"""

import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from backend.bridge import Bridge

import os
# в Qt 6 по умолчанию на Windows используется Direct3D 11
os.environ["QSG_RHI_BACKEND"] = "opengl"


def main() -> int:
    app = QGuiApplication(sys.argv)

    project_root = Path(__file__).parent

    # Папка кэша обложек - создается при запуске, если ее нет
    covers_dir = project_root / "data" / "covers"
    covers_dir.mkdir(parents=True, exist_ok=True)

    # Создание моста QML-Python
    bridge = Bridge(covers_dir)

    engine = QQmlApplicationEngine()

    # Регистрация моста ДО загрузки QML, иначе ReferenceError
    engine.rootContext().setContextProperty("bridge", bridge)

    qml_file = project_root / "qml" / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        return -1

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())