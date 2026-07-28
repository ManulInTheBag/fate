---
name: fate-hero-images
description: >-
  Как добавить selection- и portrait-картинки для нового героя в Dota 2 аддоне
  fate (game/dota_addons/fate). Применять, когда нужно подключить портрет,
  картинку экрана выбора или иконку героя, который переопределяет базового
  героя доты (override_hero). Описывает пути, имена файлов, размеры, preload-XML
  и шаг компиляции.
---

# Картинки героя в аддоне fate (selection + portrait)

Каждый Servant переопределяет базового героя доты через `override_hero`
(например `npc_dota_hero_axe`). **Все UI-картинки героя именуются по имени
БАЗОВОГО героя**, а не Servant'а. Панорама берёт их генерично по имени юнита
(`Entities.GetUnitName(...)`) — отдельный код писать не нужно.

## 1. Куда класть исходники (content, .png)

- Selection (сетка выбора):
  `content/dota_addons/fate/panorama/images/custom_game/selection/npc_dota_hero_<base>.png`
- Portrait (портрет на скорборде/пике, килл-фид, фатепедия):
  `content/dota_addons/fate/panorama/images/custom_game/portrait/npc_dota_hero_<base>.png`

где `<base>` — базовый герой из `override_hero` в
`scripts/npc/heroes/npc_fate_hero_<servant>.kv`.

## 2. Размеры (как у существующих героев)

- **selection: 71 × 94** (вертикальный бюст, ~3:4)
- **portrait: 128 × 72** (горизонтальный, ~16:9)

Если исходник другого размера — кадрировать (сохраняя лицо) и ресайзнуть.
Пример на Python/PIL:

```python
from PIL import Image
def fit(src, dst, W, H):
    im = Image.open(src).convert("RGB")
    w, h = im.size
    scale = max(W / w, H / h)
    im = im.resize((round(w * scale), round(h * scale)))
    w, h = im.size
    left, top = (w - W) // 2, (h - H) // 2
    im.crop((left, top, left + W, top + H)).save(dst)
fit("portrait_src.png", ".../custom_game/portrait/npc_dota_hero_<base>.png", 128, 72)
fit("selection_src.png", ".../custom_game/selection/npc_dota_hero_<base>.png", 71, 94)
```

Вложения из чата недоступны как файлы — попросить пользователя сохранить
исходники на диск и дать пути, затем обработать их локально.

## 3. Подключение через preload-XML

Создать `content/dota_addons/fate/panorama/<servant>.xml` по образцу
`demon_king_nobunaga.xml` (предзагрузка текстур, чтобы не было pop-in):

```xml
<root>
<Panel class="AddonLoadingRoot">
<Image src="file://{images}/heroes/npc_dota_hero_<base>.png" />
<Image src="file://{images}/heroes/selection/npc_dota_hero_<base>.png" />
<Image src="file://{images}/custom_game/portrait/npc_dota_hero_<base>.png" />
<Image src="file://{images}/custom_game/selection/npc_dota_hero_<base>.png" />
</Panel>
</root>
```

Для самых старых героев предзагрузка вместо этого прописана скрытой панелью
внутри `panorama/layout/custom_game/fateanother_hero_selection.xml` — новые
герои идут отдельными top-level XML.

Отображение в рантайме работает и без preload (JS грузит
`s2r://panorama/images/custom_game/selection/<base>_png.vtex` по требованию);
preload — это только защита от подгрузки на лету.

## 4. Компиляция (обязательный ручной шаг)

Исходные `.png` в `content/` надо скомпилировать в `game/` через Dota 2
Workshop Tools (Asset Compiler → Scan and compile). Результат:
`game/dota_addons/fate/panorama/images/custom_game/selection/npc_dota_hero_<base>_png.vtex_c`
и аналогичный `portrait/...`. Без компиляции движок картинки не увидит.

## 5. Проверка

Запустить игру → экран выбора (картинка selection), портрет героя на пике/
скорборде и килл-фид (картинка portrait). Если пусто/дефолт — проверить имя
файла (`npc_dota_hero_<base>`) и что vtex_c скомпилировался.
```
