"""
Чтение тегов MP3 через mutagen.

Чистая логика без Qt: класс MediaFile умеет извлекать название,
исполнителя и встроенную обложку. Ничего не знает про QML и UI.
"""

import hashlib
from pathlib import Path
from urllib.parse import unquote, urlparse

from mutagen.id3 import APIC
from mutagen.mp3 import MP3


class MediaFile:
    def __init__(self, file_url: str, covers_dir: Path):
        self.file_url = file_url
        self.path = self._url_to_path(file_url)
        self.covers_dir = covers_dir

    @staticmethod
    def _url_to_path(url: str) -> str:
        # unquote для расшифровки url и кириллицы
        parsed = urlparse(url)
        path = unquote(parsed.path)
        # Windows urlparse даёт /C:/Music/... - убирается ведущий слэш
        if path.startswith("/") and len(path) > 2 and path[2] == ":":
            path = path[1:]
        return path

    def read_tags(self) -> dict:
        result = {"title": "", "artist": "", "coverPath": ""}

        try:
            audio = MP3(self.path)
        except Exception as e:
            print(f"[MediaFile] не удалось открыть {self.path}: {e}")
            return result

        # 1. попытка взять теги из файла
        if audio.tags:
            if "TIT2" in audio.tags:
                result["title"] = str(audio.tags["TIT2"])
            if "TPE1" in audio.tags:
                result["artist"] = str(audio.tags["TPE1"])
            
            cover_path = self._extract_cover(audio)
            if cover_path:
                result["coverPath"] = cover_path

        # 2. нет тегов - парс имени файла
        if not result["title"] or not result["artist"]:
            fallback_title, fallback_artist = self._parse_filename()
            if not result["title"]:
                result["title"] = fallback_title
            if not result["artist"]:
                result["artist"] = fallback_artist

        return result

    def _parse_filename(self):
        filename = Path(self.path).stem
        
        if " - " in filename:
            parts = filename.split(" - ", 1)
            artist = parts[0].strip()
            title = parts[1].strip()
            return title, artist
            
        return filename, ""



    def _extract_cover(self, audio: MP3) -> str:
        # может быть несколько APIC-кадров, берется первый
        for tag in audio.tags.values():
            if isinstance(tag, APIC):
                return self._save_cover(tag)
        return ""

    def _save_cover(self, apic: APIC) -> str:
        # Хеш от пути - от пересоздания одной и той же обложки
        hash_str = hashlib.md5(self.path.encode("utf-8")).hexdigest()
        ext = "png" if apic.mime == "image/png" else "jpg"
        cover_path = self.covers_dir / f"{hash_str}.{ext}"

        if not cover_path.exists():
            try:
                cover_path.write_bytes(apic.data)
            except Exception as e:
                print(f"[MediaFile] не удалось сохранить обложку: {e}")
                return ""

        return str(cover_path)