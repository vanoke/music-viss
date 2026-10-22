"""
Мост QML - Python: методы, вызываемые из QML.

Теперь умеет запускать фоновый поток и отправлять сигналы
"""

import threading
from pathlib import Path
from PySide6.QtCore import QObject, Slot, Signal
from backend.media import MediaFile
from backend.http_client import download_track_info

class Bridge(QObject):
    # сигнал. в QML он вызовет функцию onCoverDownloaded(fileUrl, coverPath)
    trackInfoDownloaded = Signal(str, str, str, str)

    def __init__(self, covers_dir: Path):
        super().__init__()
        self.covers_dir = covers_dir

    @Slot(str, result="QVariantMap")
    def readTags(self, file_url: str) -> dict:
        media = MediaFile(file_url, self.covers_dir)
        return media.read_tags()

    @Slot(str, str, str)
    def fetchInfo(self, file_url: str, artist: str, title: str):
        # слот вызывается из QML. НЕ качает картинку сам, иначе QML зависнет
        # создает и запускает фоновый поток 
        thread = threading.Thread(
            target=self._fetch_task,
            args=(file_url, artist, title)
        )
        thread.daemon = True
        thread.start()

    def _fetch_task(self, file_url: str, artist: str, title: str):
        info = download_track_info(artist, title, self.covers_dir)
        
        # Стреляем сигналом только если что-то нашли
        if info["coverPath"] or info["correctedTitle"]:
            self.trackInfoDownloaded.emit(
                file_url, 
                info["coverPath"], 
                info["correctedTitle"], 
                info["correctedArtist"]
            )


    # Чтение LRC файла
    @Slot(str, result=str)
    def readLRC(self, file_url: str) -> str:
        # URL в путь
        media = MediaFile(file_url, self.covers_dir)
        # поиск .lrc с тем же именем
        lrc_path = Path(media.path).with_suffix('.lrc')
        
        if lrc_path.exists():
            try:
                # файл читается в кодировке UTF-8
                return lrc_path.read_text(encoding='utf-8')
            except Exception as e:
                print(f"[LRC] Ошибка чтения {lrc_path}: {e}")
                return ""
        return ""