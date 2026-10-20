import hashlib
from pathlib import Path
import requests

def download_track_info(artist: str, title: str, covers_dir: Path) -> dict:
    result = {"coverPath": "", "correctedTitle": "","correctedArtist": ""}
    
    # and работа поиска, даже если есть только название без тегов
    if not artist and not title:
        return result

    # 1. формирование getзапроса к iTunes API
    url = "https://itunes.apple.com/search"
    params = {
        "term": f"{artist} {title}", # поиск запрос
        "entity": "song",            # поиск конкретно песни
        "limit": 1                   # нужен только первый результат
    }

    try:
        # увеличен с 5 до 10сек
        response = requests.get(url, params=params, timeout=5)
        data = response.json()

        # проверка, что iTunes хоть что-то нашел
        if data.get("resultCount", 0) > 0:
            track = data["results"][0]


            # 1. извлечение правильных названий
            result["correctedTitle"] = track.get("trackName", "")
            result["correctedArtist"] = track.get("artistName", "")

            # 2. cкачивание обложки
            artwork_url = track.get("artworkUrl100")
            if artwork_url:
                artwork_url = artwork_url.replace("100x100bb", "600x600bb")
                # увеличен с 5 до 10сек
                img_response = requests.get(artwork_url, timeout=5)
                img_response.raise_for_status()

                hash_str = hashlib.md5(f"{artist}{title}".encode("utf-8")).hexdigest()
                cover_path = covers_dir / f"itunes_{hash_str}.jpg"
                
                if not cover_path.exists():
                    cover_path.write_bytes(img_response.content)
                
                result["coverPath"] = str(cover_path)
    except Exception as e:
        print(f"[HTTP] Ошибка загрузки обложки: {e}")

    return result