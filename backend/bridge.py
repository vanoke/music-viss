"""
Мост QML - Python: методы, вызываемые из QML.

принимает запрос из QML, делегирует в media.py,
возвращает результат. Ничего не знает про UI.
"""

from pathlib import Path

from PySide6.QtCore import QObject, Slot

from backend.media import MediaFile


class Bridge(QObject):
    def __init__(self, covers_dir: Path):
        super().__init__()
        self.covers_dir = covers_dir

    @Slot(str, result="QVariantMap")
    def readTags(self, file_url: str) -> dict:
        media = MediaFile(file_url, self.covers_dir)
        return media.read_tags()