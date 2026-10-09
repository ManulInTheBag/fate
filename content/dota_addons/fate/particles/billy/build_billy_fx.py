# -*- coding: utf-8 -*-
"""Партикли выстрелов Billy the Kid — КОПИИ рабочих партиклей с точечными правками.

⚠️ Почему не с нуля (05.10.2026): .vpcf, написанные руками/генератором, компилятор
принимает молча («OK»), Particle Editor при открытии их «достраивает» и они в нём видны,
но скомпилированные с диска в игре не рисуются. Структуру берём только из файлов,
которые сохранял сам Particle Editor и которые работают в игре.
Юзер забраковал: самописные трейлы, увеличенные дымки nobu_trail, ленту стрелы Робин
(«как стрелы»); указал образцы — пулю Хиджикаты и пулю Муэрты.

Линейная пуля Билли = всё дерево hijikata_bullet* (своё ядро/ленты + стоковые детали
Dead Shot Муэрты), скопированное под именами billy_bullet*: правки Хиджикаты не заденут
Билли. Корень billy_bullet устроен как самонаводящийся снаряд (притяжение к CP1, скорость
из CP2), поэтому он же — рикошет Q (тот же вид и цвет, что у выстрела). Доп. выстрелы D и
атака — стоковая muerta_base_attack, тут не собирается.

Запуск из этой папки: python build_billy_fx.py, затем
resourcecompiler -game <game/dota> -f -i content/dota_addons/fate/particles/billy/*.vpcf
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
HIJ = os.path.join(os.path.dirname(HERE), 'hijikata')

def tree(name, acc):
    if name in acc:
        return
    acc.append(name)
    s = open(os.path.join(HIJ, name + '.vpcf'), encoding='utf-8').read()
    for m in re.finditer(r'm_ChildRef = resource:"particles/hijikata/([a-z_0-9]+)\.vpcf"', s):
        tree(m.group(1), acc)

files = []
tree('hijikata_bullet', files)
REN = {n: n.replace('hijikata_', 'billy_', 1) for n in files}   # hijikata_bullet_1 -> billy_bullet_1
for n in files:
    s = open(os.path.join(HIJ, n + '.vpcf'), encoding='utf-8').read()
    for a, b in REN.items():
        s = s.replace('resource:"particles/hijikata/%s.vpcf"' % a, 'resource:"particles/billy/%s.vpcf"' % b)
    assert 'particles/hijikata/' not in s, n
    with open(os.path.join(HERE, REN[n] + '.vpcf'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(s)
    print('copied', n, '->', REN[n])

# ------------------------------------------------------------------ правки внешнего вида
# Юзер: трейл поменьше и не оранжевый (оранжевый Хиджикаты «не в тему»).
# Цвет: насыщенные (оранжевый/красный/огонь) -> серебристо-белый той же яркости; тёмные
# и серые (дым) не трогаем. Размер: ширина лент (m_flConstantRadius), их жизнь (длина
# хвоста) и свечение головы — меньше.
COLOR_RE = re.compile(r'(m_ConstantColor|m_ColorMin|m_ColorMax|m_ColorFade|m_LiteralColor) = '
                      r'\[ (\d+), (\d+), (\d+)((?:, \d+)?) \]')
def silver(m, k=1.0):
    r, g, b = int(m.group(2)), int(m.group(3)), int(m.group(4))
    v = max(r, g, b)
    if v < 40 or (v - min(r, g, b)) / v < 0.25:
        return m.group(0)
    v = v * k
    return '%s = [ %d, %d, %d%s ]' % (m.group(1), round(v * 0.9), round(v * 0.94), round(v), m.group(5))

# Юзер 06.10.2026: «трейл чуть потемнее» — ленты (trail_core аддитивная: темнее = тусклее,
# trail_dark* — серее) получают серебро не полной яркости.
TRAIL_DARKEN = {'billy_bullet_1_trail_core': 0.7, 'billy_bullet_1_trail_dark': 0.7,
                'billy_bullet_1_trail_dark_2': 0.7, 'billy_bullet_1_trail_dark_3': 0.7}

# Ширина (замер после жалобы «трейлы очень широкие»): ленты рисуются полушириной =
# радиусу частицы (ConstantRadius), а три тёмных спирали trail_dark ещё и крутятся вокруг
# пути на RingWave m_flInitialRadius 30/40 — это и давало полосу шириной ~80. Стоковый
# чёрный дым Dead Shot (linear_tree_projectile_black) — тоже широкий, выключен.
BLACK = 'muerta_deadshot_linear_tree_projectile_black.vpcf"\n'
EDITS = {   # файл: [(было, стало)] — каждое ровно один раз
    'billy_bullet_1':              [(BLACK, BLACK + '\t\t\tm_bDisableChild = true\n')],
    'billy_bullet_1_trail_core':   [('m_flConstantRadius = 35.0', 'm_flConstantRadius = 6.0'),
                                    ('m_flLiteralValue = 0.365\n', 'm_flLiteralValue = 0.2\n')],
    'billy_bullet_1_trail_dark':   [('m_flConstantRadius = 20.0', 'm_flConstantRadius = 3.0'),
                                    ('m_flLiteralValue = 0.25\n', 'm_flLiteralValue = 0.14\n'),
                                    ('m_flLiteralValue = 30.0\n', 'm_flLiteralValue = 5.0\n')],
    'billy_bullet_1_trail_dark_2': [('m_flConstantRadius = 20.0', 'm_flConstantRadius = 3.0'),
                                    ('m_flLiteralValue = 0.25\n', 'm_flLiteralValue = 0.14\n'),
                                    ('m_flLiteralValue = 40.0\n', 'm_flLiteralValue = 6.0\n')],
    'billy_bullet_1_trail_dark_3': [('m_flConstantRadius = 20.0', 'm_flConstantRadius = 3.0'),
                                    ('m_flLiteralValue = 0.25\n', 'm_flLiteralValue = 0.14\n'),
                                    ('m_flLiteralValue = 40.0\n', 'm_flLiteralValue = 6.0\n')],
    'billy_bullet_1_core':         [('m_flLiteralValue = 45.0\n', 'm_flLiteralValue = 18.0\n')],
}
for n in REN.values():
    path = os.path.join(HERE, n + '.vpcf')
    s = open(path, encoding='utf-8').read()
    k = TRAIL_DARKEN.get(n, 1.0)
    s = COLOR_RE.sub(lambda m: silver(m, k), s)
    for a, b in EDITS.get(n, []):
        assert s.count(a) == 1, (n, a, s.count(a))
        s = s.replace(a, b)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(s)
    print('styled', n)

# ------------------------------------------------------------------ летящая пуля без «выстрела»
# Юзер 06.10.2026: «белые всплески» и «белое непойми-что на пистолете». Это были дети пули,
# рождающиеся в точке вылета (CP3 на старте): дульная вспышка Хиджикаты, перекрашенная
# silver() в белую, «угли» fire_embers (тоже ставшие белыми), дымок и флеки Dead Shot. При
# рикошете они вспыхивали в точке отскока на земле. Теперь у ЛЕТЯЩЕЙ пули их нет вовсе;
# выстрел у дула — отдельная billy_gunflash (ниже), Lua ставит её на attach_attack1.
# Lua создаёт пулю с billy_bullet_1 (CP0/CP3 — старт, CP1 — вектор скорости): корень
# billy_bullet (притяжение к CP1 + MovementPlaceOnGround) тоже писал CP3 детям — второй
# писатель CP3 сбивал модель пули с пути (жалоба «трейл быстрее пули»); корень не используется.
def disable_child(s, ref):
    a = ref + '"\n'
    assert s.count(a) == 1, ref
    return s.replace(a, a + '\t\t\tm_bDisableChild = true\n')

p = os.path.join(HERE, 'billy_bullet_1.vpcf')
s = open(p, encoding='utf-8').read()
for ref in ('hero_muerta/muerta_deadshot_tracking_proj_firing_smoke.vpcf',
            'hero_muerta/muerta_deadshot_tracking_firing.vpcf',
            'particles/billy/billy_bullet_1_fire_embers.vpcf',
            'particles/billy/billy_muzzleflash.vpcf',
            # ленты — теперь отдельной системой billy_trail (ниже)
            'particles/billy/billy_bullet_1_trail_core.vpcf',
            'particles/billy/billy_bullet_1_trail_dark.vpcf',
            'particles/billy/billy_bullet_1_trail_dark_2.vpcf',
            'particles/billy/billy_bullet_1_trail_dark_3.vpcf'):
    s = disable_child(s, ref)
# Юзер 07.10.2026: «трейлы рисуются каждый раз разной длины» (дробь W: 400 на 3000/с). Пулю
# гасил только DestroyParticle с сервера — команда доходит до клиента с шагом тика (~33 мс)
# и сетевым джиттером: ±100 из 400. Теперь корень сам останавливается (с endcap — как
# DestroyParticle(false)) через CP5.x секунд от рождения на КЛИЕНТЕ: Lua пишет туда
# dist/speed (Billy_FlyingFx). Сервер гасит раньше только на попадании. Наследуют все копии
# (billy_trail, combo, d) — они собираются из этого файла ниже.
# ⚠️ CP5 обязателен: без него длительность 0 — пуля гаснет сразу.
STOP_BY_CP5 = ('\tm_PreEmissionOperators = \n\t[\n\t\t{\n\t\t\t_class = "C_OP_StopAfterCPDuration"\n'
               '\t\t\tm_flDuration = \n\t\t\t{\n\t\t\t\tm_nType = "PF_TYPE_CONTROL_POINT_COMPONENT"\n'
               '\t\t\t\tm_nControlPoint = 5\n\t\t\t\tm_nVectorComponent = 0\n'
               '\t\t\t\tm_nMapType = "PF_MAP_TYPE_MULT"\n\t\t\t\tm_flMultFactor = 1.0\n\t\t\t}\n'
               '\t\t},\n\t]\n')
assert 'm_PreEmissionOperators' not in s and s.count('\tm_Emitters = \n') == 1
s = s.replace('\tm_Emitters = \n', STOP_BY_CP5 + '\tm_Emitters = \n')
with open(p, 'w', encoding='utf-8', newline='\n') as f:
    f.write(s)
print('billy_bullet_1: start-of-flight and trail children disabled')

# ------------------------------------------------------------------ трейл отдельно от пули
# Юзер 06.10.2026: «трейлов не видно сразу после попадания» — ленты были детьми пули, и
# Billy_BulletEnd гасил их вместе с ней (EndCapTimedDecay 0.15 + LerpEndCapScalar
# радиус/альфа в 0). Теперь трейл — своя система billy_trail: невидимая «голова» (копия
# billy_bullet_1 без рендера: CP0/CP3 старт, CP1 скорость — Lua создаёт её рядом с пулей)
# и дети: яркая лента, длинная тусклая «тающая» лента, три тонкие спирали и искры. У
# детей выключены все endcap-операторы: на попадании Lua гасит систему, голова встаёт,
# эмиттеры молчат, а выпущенные частицы доживают свой срок — это и есть лингер.
# Цвет — бледное золото (юзер: «цвет чутка поменять»; оранжевый раньше был «не в тему»).
TRAIL_TINT = (1.0, 0.9, 0.74)
def one(s, a, b):
    assert s.count(a) == 1, (a, s.count(a))
    return s.replace(a, b)

def warm(text, k, tint=TRAIL_TINT):
    def sub(m):
        r, g, b = int(m.group(2)), int(m.group(3)), int(m.group(4))
        v = max(r, g, b)
        if v < 40 or (v - min(r, g, b)) / v < 0.25:
            return m.group(0)
        v = min(255, v * k)
        return '%s = [ %d, %d, %d%s ]' % ((m.group(1),) + tuple(round(v * t) for t in tint) + (m.group(5),))
    return COLOR_RE.sub(sub, text)

def disable_ops(text, classes):
    for c in classes:
        a = '_class = "%s"\n' % c
        assert a in text, c
        text = text.replace(a, a + '\t\t\tm_bDisableOperator = true\n')
    return text

def life(text, old, new):
    # InitFloat времени жизни: литерал, за которым (в пределах блока) m_nOutputField = 1
    text, n = re.subn(r'(m_flLiteralValue = )%s(\n(?:\t+[^\n]*\n){0,3}?\t+m_nOutputField = 1\n)' % re.escape(old),
                      r'\g<1>%s\g<2>' % new, text)
    assert n == 1, ('life', old)
    return text

def hij(name):
    return open(os.path.join(HIJ, name + '.vpcf'), encoding='utf-8').read()

# Юзер 07.10.2026: ленту не видно, когда стреляешь за террейн (за ступени/склон) — рендереры
# детей трейла рисуются без z-буфера, поверх геометрии. Ставится в put() по имени файла, так
# что получают все копии: обычный, D, комбо, комбо-выстрелы. Повторно флаг не вписывается.
TRAIL_CHILD_RE = re.compile(r'_trail(?:_d)?_(?:core|linger|spiral(?:_\d)?|sparks)$')
def noz(text):
    return re.sub(r'(\t+)(_class = "C_OP_Render(?:Ropes|Sprites)"\n)(?!\t+m_bDisableZBuffering)',
                  r'\1\2\1m_bDisableZBuffering = true\n', text)

def put(name, text):
    if TRAIL_CHILD_RE.search(name):
        text = noz(text)
    with open(os.path.join(HERE, name + '.vpcf'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    print('wrote', name)

ENDCAP_OPS = ('C_OP_EndCapTimedDecay', 'C_OP_LerpEndCapScalar')

# Юзер 07.10.2026: трейл Q «не до конца рисуется», в упор — нет вовсе. Лента — цепочка точек
# ContinuousEmitter'а: на 7000/с при 110 точках/с шаг ~64 и последний отрезок до пули пустой;
# а FadeIn 0.4 (доля жизни 0.2 = 0.08 с) делал прозрачными последние ~550 пути — у короткого
# выстрела это почти весь трейл. Теперь TRAIL_RATE точек/с (шаг ~32) и fade-in яркой ленты
# и спиралей короче (TRAIL_FADE_IN). Короткие выстрелы ещё и тянутся во времени: Lua даёт
# частице не меньше BILLY_BULLET_MIN_FX секунд полёта (Billy_LinearShot).
TRAIL_RATE = '220.0'
TRAIL_FADE_IN = '0.1'

# яркая лента у пули: чуть ярче и шире прежней (6 -> 9), гуще (64 -> TRAIL_RATE точек/с: на
# скорости 7000+ реже — ломаная), жизнь прежняя 0.2
t = warm(hij('hijikata_bullet_1_trail_core'), 0.9)
t = one(t, 'm_flConstantRadius = 35.0', 'm_flConstantRadius = 9.0')
t = life(t, '0.365', '0.2')
t = one(t, 'm_flLiteralValue = 64.0\n', 'm_flLiteralValue = %s\n' % TRAIL_RATE)
t = one(t, 'm_nMaxParticles = 24', 'm_nMaxParticles = 96')
t = one(t, 'm_flFadeInTime = 0.4', 'm_flFadeInTime = ' + TRAIL_FADE_IN)
put('billy_trail_core', disable_ops(t, ENDCAP_OPS))

# «тающая» лента: шире (16), тусклее, живёт 0.55 с — висит по всему пути и гаснет с хвоста;
# возникает чуть позади головы (fade-in) и долго тает (fade-out)
t = warm(hij('hijikata_bullet_1_trail_core'), 0.55)
t = one(t, 'm_flConstantRadius = 35.0', 'm_flConstantRadius = 16.0')
t = life(t, '0.365', '0.55')
t = one(t, 'm_flLiteralValue = 64.0\n', 'm_flLiteralValue = %s\n' % TRAIL_RATE)
t = one(t, 'm_nMaxParticles = 24', 'm_nMaxParticles = 256')
t = one(t, 'm_flFadeInTime = 0.4', 'm_flFadeInTime = 0.1')
t = one(t, 'm_flFadeOutTime = 0.4', 'm_flFadeOutTime = 0.8')
put('billy_trail_linger', disable_ops(t, ENDCAP_OPS))

# спирали — как у пули (тонкие, на радиусе 5–6 вокруг пути), чуть шире и дольше
for src, ring in (('hijikata_bullet_1_trail_dark', '30.0'), ('hijikata_bullet_1_trail_dark_2', '40.0'),
                  ('hijikata_bullet_1_trail_dark_3', '40.0')):
    t = warm(hij(src), 0.75)
    t = one(t, 'm_flConstantRadius = 20.0', 'm_flConstantRadius = 4.0')
    t = life(t, '0.25', '0.22')
    t = one(t, 'm_flLiteralValue = %s\n' % ring, 'm_flLiteralValue = %s\n' % ('5.0' if ring == '30.0' else '6.0'))
    t = one(t, 'm_flFadeInTime = 0.4', 'm_flFadeInTime = ' + TRAIL_FADE_IN)
    put(src.replace('hijikata_bullet_1_trail_dark', 'billy_trail_spiral'), disable_ops(t, ENDCAP_OPS))

# искры: копия «головы»-свечения пули (hijikata_bullet_1_core) — мелкие тёплые огоньки
# вдоль пути, разлетаются в стороны и гаснут за ~0.3 с
t = hij('hijikata_bullet_1_core')
t = re.sub(r'm_ConstantColor = \[ \d+, \d+, \d+, \d+ \]', 'm_ConstantColor = [ 255, 205, 140, 230 ]', t, count=1)
t = life(t, '0.05', '0.3')
t = one(t, 'm_flLiteralValue = 45.0\n', 'm_flLiteralValue = 5.0\n')
t = re.sub(r'm_nMaxParticles = \d+', 'm_nMaxParticles = 64', t, count=1)
t = disable_ops(t, ('C_OP_EndCapTimedDecay', 'C_OP_RampScalarLinearSimple'))
t = one(t, '\t\t\t_class = "C_OP_RenderSprites"\n',
        '\t\t\t_class = "C_OP_RenderSprites"\n\t\t\tm_nOutputBlendMode = "PARTICLE_OUTPUT_BLEND_MODE_ADD"\n')
VEL = ('\t\t{\n\t\t\t_class = "C_INIT_InitialVelocityNoise"\n'
       '\t\t\tm_vecOutputMin = \n\t\t\t{\n\t\t\t\tm_nType = "PVEC_TYPE_LITERAL"\n\t\t\t\tm_vLiteralValue = [ -90.0, -90.0, -30.0 ]\n\t\t\t}\n'
       '\t\t\tm_vecOutputMax = \n\t\t\t{\n\t\t\t\tm_nType = "PVEC_TYPE_LITERAL"\n\t\t\t\tm_vLiteralValue = [ 90.0, 90.0, 120.0 ]\n\t\t\t}\n'
       '\t\t},\n')
t = one(t, '\tm_Initializers = \n\t[\n', '\tm_Initializers = \n\t[\n' + VEL)
put('billy_trail_sparks', t)

# голова трейла: billy_bullet_1 (без рендера) с новым списком детей
kids = ['billy_trail_core', 'billy_trail_linger', 'billy_trail_spiral', 'billy_trail_spiral_2',
        'billy_trail_spiral_3', 'billy_trail_sparks']
block = '\tm_Children = \n\t[\n' + ''.join(
    '\t\t{\n\t\t\tm_ChildRef = resource:"particles/billy/%s.vpcf"\n\t\t},\n' % k for k in kids) + '\t]\n'
t, n = re.subn(r'\tm_Children = \n\t\[\n.*?\n\t\]\n', lambda m: block, s, flags=re.S)
assert n == 1 and 'm_Renderers' not in t
put('billy_trail', t)

# ------------------------------------------------------------------ выстрел у дула
# billy_gunflash = ОРИГИНАЛЬНАЯ (оранжевая, без silver) вспышка Хиджикаты, втрое меньше и
# без пережога в белое (overbright 5 -> 2, add-self 4 -> 1), + стоковый серый дымок
# Dead Shot (tracking_proj_firing_smoke). CP3 — дуло, ориентация CP3 — направление выстрела.
s = open(os.path.join(HIJ, 'hijikata_muzzleflash.vpcf'), encoding='utf-8').read()
def one(s, a, b):
    assert s.count(a) == 1, (a, s.count(a))
    return s.replace(a, b)
s = one(s, 'm_flLiteralValue = 90.0\n', 'm_flLiteralValue = 30.0\n')   # радиус вспышки
s = one(s, 'm_flEndScale = 3.0', 'm_flEndScale = 2.0')
for field, old, new in (('m_flOverbrightFactor', '5.0', '2.0'), ('m_flAddSelfAmount', '4.0', '1.0')):
    s, n = re.subn(r'(%s = \n(?:\t+[^\n]*\n){1,4}?\t+m_flLiteralValue = )%s' % (field, re.escape(old)),
                   r'\g<1>' + new, s)
    assert n == 1, field
s = one(s, '\tm_nFirstMultipleOverride_BackwardCompat = 6\n',
        '\tm_nFirstMultipleOverride_BackwardCompat = 6\n\tm_Children = \n\t[\n\t\t{\n\t\t\tm_ChildRef = '
        'resource:"particles/units/heroes/hero_muerta/muerta_deadshot_tracking_proj_firing_smoke.vpcf"\n'
        '\t\t},\n\t]\n')
with open(os.path.join(HERE, 'billy_gunflash.vpcf'), 'w', encoding='utf-8', newline='\n') as f:
    f.write(s)
print('wrote billy_gunflash')

# прошлый вариант рикошета (06.10.2026) больше не нужен: пуля везде одна
for old in ('billy_bullet_rico', 'billy_bullet_1_rico'):
    for p in (os.path.join(HERE, old + '.vpcf'),
              os.path.join(HERE, r'..\..\..\..\..\game\dota_addons\fate\particles\billy', old + '.vpcf_c')):
        if os.path.exists(p):
            os.remove(p)
            print('removed', p)

# уборка прошлых версий (nobu/robin-копии и самописные)
for old in ('billy_bullet_tracking', 'billy_bullet_trail', 'billy_bullet_streak', 'billy_muzzle',
            'billy_muzzle_sparks', 'billy_impact', 'billy_impact_flash', 'billy_tracer'):
    # ⚠️ billy_smoke НЕ трогать: с 06.10.2026 это дым W из build_billy_smoke.py
    p = os.path.join(HERE, old + '.vpcf')
    if os.path.exists(p):
        os.remove(p)
        print('removed', old)

# ------------------------------------------------------------------ пуля комбо (массивная)
# Юзер 07.10.2026: у комбо пуля шириной 100 (было 35) — «партикль по массивней». Отдельные
# копии, обычная пуля Q/W/E/атаки не меняется. Lua: BILLY_FX.combo_bullet/combo_trail.
#  billy_combo_bullet       = billy_bullet_1, дети: своя модель и своё свечение головы;
#  billy_combo_bullet_model = стоковая модель пули Муэрты (сфера, растянутая ×3 по X; декомпил
#                             s2v лежит в muerta_projectile_model.template), радиус 0.1 -> 0.28;
#  billy_combo_bullet_core  = свечение головы 18 -> 55;
#  billy_combo_trail        = billy_trail с детьми шире/дольше (лента 9 -> 30, тающая 16 -> 52,
#                             спирали толще и на радиусе 18–22 вокруг пути, искры крупнее и дальше).
def rd(name):
    return open(os.path.join(HERE, name + '.vpcf'), encoding='utf-8').read()

def reref(text, a, b):
    return one(text, 'resource:"particles/%s.vpcf"' % a, 'resource:"particles/billy/%s.vpcf"' % b)

t = open(os.path.join(HERE, 'muerta_projectile_model.template'), encoding='utf-8').read()
t, n = re.subn(r'(C_INIT_InitFloat"\n\t+m_InputValue = \n\t+\{\n\t+m_nType = "PF_TYPE_LITERAL"\n'
               r'\t+m_flLiteralValue = )0\.1(\n\t+\}\n\t+\},)', r'\g<1>0.28\g<2>', t)
assert n == 1, 'model radius'
put('billy_combo_bullet_model', t)

t = one(rd('billy_bullet_1_core'), 'm_flLiteralValue = 18.0\n', 'm_flLiteralValue = 55.0\n')
put('billy_combo_bullet_core', t)

t = rd('billy_bullet_1')
t = reref(t, 'units/heroes/hero_muerta/muerta_deadshot_tracking_projectile_model', 'billy_combo_bullet_model')
t = reref(t, 'billy/billy_bullet_1_core', 'billy_combo_bullet_core')
put('billy_combo_bullet', t)

t = rd('billy_trail_core')
t = one(t, 'm_flConstantRadius = 9.0', 'm_flConstantRadius = 30.0')
t = life(t, '0.2', '0.3')
put('billy_combo_trail_core', t)

t = rd('billy_trail_linger')
t = one(t, 'm_flConstantRadius = 16.0', 'm_flConstantRadius = 52.0')
t = life(t, '0.55', '0.8')
put('billy_combo_trail_linger', t)

for src, ring, new_ring in (('billy_trail_spiral', '5.0', '18.0'), ('billy_trail_spiral_2', '6.0', '22.0'),
                            ('billy_trail_spiral_3', '6.0', '22.0')):
    t = rd(src)
    t = one(t, 'm_flConstantRadius = 4.0', 'm_flConstantRadius = 10.0')
    ring_at = 'm_flInitialRadius = \n\t\t\t{\n\t\t\t\tm_nType = "PF_TYPE_LITERAL"\n' \
              '\t\t\t\tm_nMapType = "PF_MAP_TYPE_DIRECT"\n\t\t\t\tm_flLiteralValue = '
    t = one(t, ring_at + ring + '\n', ring_at + new_ring + '\n')
    t = life(t, '0.22', '0.3')
    put(src.replace('billy_trail', 'billy_combo_trail'), t)

t = rd('billy_trail_sparks')
t = one(t, 'm_flLiteralValue = 5.0\n', 'm_flLiteralValue = 10.0\n')
t = one(t, '[ -90.0, -90.0, -30.0 ]', '[ -220.0, -220.0, -60.0 ]')
t = one(t, '[ 90.0, 90.0, 120.0 ]', '[ 220.0, 220.0, 260.0 ]')
t = one(t, 'm_nMaxParticles = 64', 'm_nMaxParticles = 128')
put('billy_combo_trail_sparks', t)

t = rd('billy_trail')
for k in ('core', 'linger', 'spiral', 'spiral_2', 'spiral_3', 'sparks'):
    t = reref(t, 'billy/billy_trail_' + k, 'billy_combo_trail_' + k)
put('billy_combo_trail', t)

# ------------------------------------------------------------------ пули под D (усиленные)
# Юзер 07.10.2026: под D (Q/W/E/R и атака, когда тратят пули) — трейл ярче, а попадание
# взрывается оранжевым всплеском вместо землистой пыли. Обычные пули не меняются.
# Lua: BILLY_FX.d = { bullet, trail }, BILLY_FX.burst_d.
#  billy_bullet_d        = billy_bullet_1 с головой billy_bullet_d_core (свечение 18 -> 30,
#                          оранжевое, аддитивное — у обычной серое в смешивании);
#  billy_trail_d         = billy_trail с детьми billy_trail_d_*: оттенок не бледное золото, а
#                          оранжево-золотой TRAIL_TINT_D на полной яркости, лента 9 -> 13 и
#                          живёт 0.2 -> 0.3, пережог 10 -> 16, тающая 16 -> 22 / 0.55 -> 0.75,
#                          спирали толще, искр вдвое больше и они разлетаются дальше;
#  billy_burst_d         = всплеск попадания: оранжевая вспышка Хиджикаты (как billy_gunflash,
#                          но крупнее, CP3 — точка, forward CP3 — к стрелку) + дети:
#                          billy_burst_d_puff  — пыль billy_ricochet_dust, перекрашенная в огонь,
#                                                быстрее и короче, без стоковых комьев земли;
#                          billy_burst_d_sparks — искры billy_hitsparks вдвое гуще и дальше.
TRAIL_TINT_D = (1.0, 0.68, 0.3)

def lit(text, field, old, new):
    # литерал CPerParticleFloatInput-поля field (m_flOverbrightFactor = { ... m_flLiteralValue })
    text, n = re.subn(r'(%s = \n(?:\t+[^\n]*\n){1,4}?\t+m_flLiteralValue = )%s' % (field, re.escape(old)),
                      r'\g<1>' + new, text)
    assert n == 1, (field, old)
    return text

# голова пули: оранжевое аддитивное свечение
t = rd('billy_bullet_1_core')
t = one(t, 'm_flLiteralValue = 18.0\n', 'm_flLiteralValue = 30.0\n')
t = one(t, 'm_ConstantColor = [ 57, 57, 57, 137 ]', 'm_ConstantColor = [ 255, 150, 60, 210 ]')
t = one(t, 'm_Color = [ 35, 135, 111 ]', 'm_Color = [ 150, 55, 10 ]')
t = one(t, 'm_Color = [ 81, 187, 164 ]', 'm_Color = [ 255, 140, 40 ]')
t = one(t, 'm_Color = [ 255, 255, 255 ]', 'm_Color = [ 255, 236, 190 ]')
t = one(t, '\t\t\t_class = "C_OP_RenderSprites"\n',
        '\t\t\t_class = "C_OP_RenderSprites"\n\t\t\tm_nOutputBlendMode = "PARTICLE_OUTPUT_BLEND_MODE_ADD"\n')
put('billy_bullet_d_core', t)

t = reref(rd('billy_bullet_1'), 'billy/billy_bullet_1_core', 'billy_bullet_d_core')
put('billy_bullet_d', t)

# трейл
t = warm(hij('hijikata_bullet_1_trail_core'), 1.0, TRAIL_TINT_D)
t = one(t, 'm_flConstantRadius = 35.0', 'm_flConstantRadius = 13.0')
t = life(t, '0.365', '0.3')
t = one(t, 'm_flLiteralValue = 64.0\n', 'm_flLiteralValue = %s\n' % TRAIL_RATE)
t = one(t, 'm_nMaxParticles = 24', 'm_nMaxParticles = 96')
t = one(t, 'm_flFadeInTime = 0.4', 'm_flFadeInTime = ' + TRAIL_FADE_IN)
t = lit(t, 'm_flOverbrightFactor', '10.0', '16.0')
put('billy_trail_d_core', disable_ops(t, ENDCAP_OPS))

t = warm(hij('hijikata_bullet_1_trail_core'), 0.8, TRAIL_TINT_D)
t = one(t, 'm_flConstantRadius = 35.0', 'm_flConstantRadius = 22.0')
t = life(t, '0.365', '0.75')
t = one(t, 'm_flLiteralValue = 64.0\n', 'm_flLiteralValue = %s\n' % TRAIL_RATE)
t = one(t, 'm_nMaxParticles = 24', 'm_nMaxParticles = 256')
t = one(t, 'm_flFadeInTime = 0.4', 'm_flFadeInTime = 0.1')
t = one(t, 'm_flFadeOutTime = 0.4', 'm_flFadeOutTime = 0.8')
put('billy_trail_d_linger', disable_ops(t, ENDCAP_OPS))

for src, ring in (('hijikata_bullet_1_trail_dark', '30.0'), ('hijikata_bullet_1_trail_dark_2', '40.0'),
                  ('hijikata_bullet_1_trail_dark_3', '40.0')):
    t = warm(hij(src), 1.0, TRAIL_TINT_D)
    t = one(t, 'm_flConstantRadius = 20.0', 'm_flConstantRadius = 6.0')
    t = life(t, '0.25', '0.28')
    t = one(t, 'm_flLiteralValue = %s\n' % ring, 'm_flLiteralValue = %s\n' % ('6.0' if ring == '30.0' else '8.0'))
    t = one(t, 'm_flFadeInTime = 0.4', 'm_flFadeInTime = ' + TRAIL_FADE_IN)
    put(src.replace('hijikata_bullet_1_trail_dark', 'billy_trail_d_spiral'), disable_ops(t, ENDCAP_OPS))

t = rd('billy_trail_sparks')
t = one(t, 'm_ConstantColor = [ 255, 205, 140, 230 ]', 'm_ConstantColor = [ 255, 165, 70, 255 ]')
t = one(t, 'm_flLiteralValue = 5.0\n', 'm_flLiteralValue = 7.0\n')
t = one(t, '[ -90.0, -90.0, -30.0 ]', '[ -160.0, -160.0, -40.0 ]')
t = one(t, '[ 90.0, 90.0, 120.0 ]', '[ 160.0, 160.0, 200.0 ]')
t = one(t, 'm_nMaxParticles = 64', 'm_nMaxParticles = 128')
put('billy_trail_d_sparks', t)

t = rd('billy_trail')
for k in ('core', 'linger', 'spiral', 'spiral_2', 'spiral_3', 'sparks'):
    t = reref(t, 'billy/billy_trail_' + k, 'billy_trail_d_' + k)
put('billy_trail_d', t)

# ------------------------------------------------------------------ крупная пуля W под D
# Юзер 07.10.2026: у W под D пуля тоже другого цвета, как у остальных скиллов. Крупная пуля W —
# массивная пуля комбо (billy_combo_bullet/_trail); здесь её копия в окраске пуль под D:
#  billy_combo_bullet_d      = billy_combo_bullet с головой billy_combo_bullet_d_core
#                              (оранжевое свечение billy_bullet_d_core, радиус 30 -> 55);
#  billy_combo_trail_d       = billy_trail_d с детьми размеров комбо: лента 13 -> 30,
#                              тающая 22 -> 52 / 0.75 -> 0.8, спирали 6 -> 10 на радиусе 18–22,
#                              жизнь 0.28 -> 0.3, искры крупнее и дальше.
# Lua: BILLY_FX.combo_d (W берёт её, если при выстреле D включена и пуль хватает на разрыв).
t = one(rd('billy_bullet_d_core'), 'm_flLiteralValue = 30.0\n', 'm_flLiteralValue = 55.0\n')
put('billy_combo_bullet_d_core', t)
put('billy_combo_bullet_d', reref(rd('billy_combo_bullet'), 'billy/billy_combo_bullet_core', 'billy_combo_bullet_d_core'))

t = one(rd('billy_trail_d_core'), 'm_flConstantRadius = 13.0', 'm_flConstantRadius = 30.0')
put('billy_combo_trail_d_core', t)

t = one(rd('billy_trail_d_linger'), 'm_flConstantRadius = 22.0', 'm_flConstantRadius = 52.0')
t = life(t, '0.75', '0.8')
put('billy_combo_trail_d_linger', t)

for src, ring, new_ring in (('billy_trail_d_spiral', '6.0', '18.0'), ('billy_trail_d_spiral_2', '8.0', '22.0'),
                            ('billy_trail_d_spiral_3', '8.0', '22.0')):
    t = rd(src)
    t = one(t, 'm_flConstantRadius = 6.0', 'm_flConstantRadius = 10.0')
    ring_at = 'm_flInitialRadius = \n\t\t\t{\n\t\t\t\tm_nType = "PF_TYPE_LITERAL"\n' \
              '\t\t\t\tm_nMapType = "PF_MAP_TYPE_DIRECT"\n\t\t\t\tm_flLiteralValue = '
    t = one(t, ring_at + ring + '\n', ring_at + new_ring + '\n')
    t = life(t, '0.28', '0.3')
    put(src.replace('billy_trail_d', 'billy_combo_trail_d'), t)

t = rd('billy_trail_d_sparks')
t = one(t, 'm_flLiteralValue = 7.0\n', 'm_flLiteralValue = 12.0\n')
t = one(t, '[ -160.0, -160.0, -40.0 ]', '[ -220.0, -220.0, -60.0 ]')
t = one(t, '[ 160.0, 160.0, 200.0 ]', '[ 220.0, 220.0, 260.0 ]')
put('billy_combo_trail_d_sparks', t)

t = rd('billy_trail_d')
for k in ('core', 'linger', 'spiral', 'spiral_2', 'spiral_3', 'sparks'):
    t = reref(t, 'billy/billy_trail_d_' + k, 'billy_combo_trail_d_' + k)
put('billy_combo_trail_d', t)

# всплеск попадания
t = rd('billy_ricochet_dust')
t = one(t, 'm_ConstantColor = [ 112, 94, 66, 255 ]', 'm_ConstantColor = [ 255, 140, 50, 255 ]')
t = one(t, 'm_ColorMin = [ 118, 96, 64, 255 ]', 'm_ColorMin = [ 255, 170, 70, 255 ]')
t = one(t, 'm_ColorMax = [ 96, 82, 62, 255 ]', 'm_ColorMax = [ 245, 105, 25, 255 ]')
t = one(t, 'm_flRandomMin = 0.8\n', 'm_flRandomMin = 0.3\n')      # жизнь 0.8–1.4 -> 0.3–0.55
t = one(t, 'm_flRandomMax = 1.4\n', 'm_flRandomMax = 0.55\n')
t = one(t, 'm_flFadeOutTime = 0.5', 'm_flFadeOutTime = 0.3')
t = one(t, 'm_flFadeInTime = 0.1', 'm_flFadeInTime = 0.03')
# юзер 07.10.2026: дым на 20% меньше — и радиус клубов, и разлёт ×0.8 (было 140–300 / 22)
t = one(t, 'm_flLiteralValue = 40.0\n', 'm_flLiteralValue = 112.0\n')     # скорость кольца 40–100 -> 112–240
t = one(t, 'm_flLiteralValue = 100.0\n', 'm_flLiteralValue = 240.0\n')
t = one(t, 'm_flEndScale = 5.0', 'm_flEndScale = 3.5')
t = one(t, 'm_flLiteralValue = 28.0\n', 'm_flLiteralValue = 17.6\n')
t = one(t, 'dust_impact_flek.vpcf"\n', 'dust_impact_flek.vpcf"\n\t\t\tm_bDisableChild = true\n')
put('billy_burst_d_puff', t)

t = rd('billy_hitsparks')
t = one(t, 'm_nMaxParticles = 100', 'm_nMaxParticles = 200')
t = one(t, 'm_flLiteralValue = 800.0\n', 'm_flLiteralValue = 1600.0\n')
t = one(t, 'm_vecOutputMin = [ 512.0, 512.0, 512.0 ]', 'm_vecOutputMin = [ 800.0, 800.0, 800.0 ]')
t = one(t, 'm_vecOutputMax = [ -512.0, -512.0, -512.0 ]', 'm_vecOutputMax = [ -800.0, -800.0, -800.0 ]')
put('billy_burst_d_sparks', t)

t = hij('hijikata_muzzleflash')
t = one(t, 'm_flLiteralValue = 90.0\n', 'm_flLiteralValue = 70.0\n')   # радиус вспышки (у дула 30)
t = one(t, 'm_flEndScale = 3.0', 'm_flEndScale = 2.5')
t = lit(t, 'm_flOverbrightFactor', '5.0', '3.0')
t = lit(t, 'm_flAddSelfAmount', '4.0', '1.5')
t = one(t, '\tm_nFirstMultipleOverride_BackwardCompat = 6\n',
        '\tm_nFirstMultipleOverride_BackwardCompat = 6\n\tm_Children = \n\t[\n'
        '\t\t{\n\t\t\tm_ChildRef = resource:"particles/billy/billy_burst_d_puff.vpcf"\n\t\t},\n'
        '\t\t{\n\t\t\tm_ChildRef = resource:"particles/billy/billy_burst_d_sparks.vpcf"\n\t\t},\n\t]\n')
put('billy_burst_d', t)

# ------------------------------------------------------------------ выстрелы комбо (акцент на пули)
# Юзер 07.10.2026: с массивным трейлом очередь комбо выглядит «как просто ЛУЧ», а не три
# выстрела. Пули идут через 0.1 с на 8000/с — между ними ~800, а трейл billy_combo_trail
# (лента 0.3 с, тающая 0.8 с) тянулся на 2400+ и сливал их в одну полосу. Здесь своя пара
# (billy_combo_trail/billy_combo_bullet остаются у W — его пуля медленная):
#  billy_combo_shot        = billy_bullet_1, дети: модель billy_combo_shot_model (сфера 0.1 -> 0.4),
#                            головка billy_combo_shot_core и ореол billy_combo_shot_flare;
#  billy_combo_shot_core   = свечение головы: тёплое белое, аддитивное, радиус 40, живёт 0.03
#                            (было 0.05 — шлейф ~240 вместо 400: точка, а не штрих);
#  billy_combo_shot_flare  = мягкий ореол 80 вокруг головы, тусклый оранжевый;
#  billy_combo_shot_trail  = billy_trail, только короткие дети: лента 12 / 0.06 с (~480 —
#                            короче расстояния между пулями), спирали 4 на радиусе 8–10, 0.06 с,
#                            искры — как у billy_combo_trail. Тающей ленты нет вовсе.
t = open(os.path.join(HERE, 'muerta_projectile_model.template'), encoding='utf-8').read()
t, n = re.subn(r'(C_INIT_InitFloat"\n\t+m_InputValue = \n\t+\{\n\t+m_nType = "PF_TYPE_LITERAL"\n'
               r'\t+m_flLiteralValue = )0\.1(\n\t+\}\n\t+\},)', r'\g<1>0.4\g<2>', t)
assert n == 1, 'model radius'
put('billy_combo_shot_model', t)

def glow(radius, color, life_s):
    t = rd('billy_bullet_1_core')
    t = one(t, 'm_flLiteralValue = 18.0\n', 'm_flLiteralValue = %s\n' % radius)
    t = life(t, '0.05', life_s)
    t = one(t, 'm_ConstantColor = [ 57, 57, 57, 137 ]', 'm_ConstantColor = [ %d, %d, %d, %d ]' % color)
    t = one(t, '\t\t\t_class = "C_OP_ColorInterpolate"\n', '\t\t\t_class = "C_OP_ColorInterpolate"\n\t\t\tm_bDisableOperator = true\n')
    return one(t, '\t\t\t_class = "C_OP_RenderSprites"\n',
               '\t\t\t_class = "C_OP_RenderSprites"\n\t\t\tm_nOutputBlendMode = "PARTICLE_OUTPUT_BLEND_MODE_ADD"\n')
put('billy_combo_shot_core', glow('40.0', (255, 235, 200, 170), '0.03'))   # юзер: свечение слишком сильное (было 75 / альфа 255)
put('billy_combo_shot_flare', glow('80.0', (255, 170, 80, 45), '0.03'))     # было 150 / альфа 90

t = rd('billy_bullet_1')
t = reref(t, 'units/heroes/hero_muerta/muerta_deadshot_tracking_projectile_model', 'billy_combo_shot_model')
t = reref(t, 'billy/billy_bullet_1_core', 'billy_combo_shot_core')
t = one(t, 'resource:"particles/billy/billy_combo_shot_core.vpcf"\n\t\t},\n',
        'resource:"particles/billy/billy_combo_shot_core.vpcf"\n\t\t},\n'
        '\t\t{\n\t\t\tm_ChildRef = resource:"particles/billy/billy_combo_shot_flare.vpcf"\n\t\t},\n')
put('billy_combo_shot', t)

t = rd('billy_trail_core')
t = one(t, 'm_flConstantRadius = 9.0', 'm_flConstantRadius = 12.0')
t = life(t, '0.2', '0.06')
put('billy_combo_shot_trail_core', t)

for src, ring, new_ring in (('billy_trail_spiral', '5.0', '8.0'), ('billy_trail_spiral_2', '6.0', '10.0'),
                            ('billy_trail_spiral_3', '6.0', '10.0')):
    t = rd(src)
    ring_at = 'm_flInitialRadius = \n\t\t\t{\n\t\t\t\tm_nType = "PF_TYPE_LITERAL"\n' \
              '\t\t\t\tm_nMapType = "PF_MAP_TYPE_DIRECT"\n\t\t\t\tm_flLiteralValue = '
    t = one(t, ring_at + ring + '\n', ring_at + new_ring + '\n')
    t = life(t, '0.22', '0.06')
    put(src.replace('billy_trail', 'billy_combo_shot_trail'), t)

kids = ['billy_combo_shot_trail_core', 'billy_combo_shot_trail_spiral', 'billy_combo_shot_trail_spiral_2',
        'billy_combo_shot_trail_spiral_3', 'billy_combo_trail_sparks']
block = '\tm_Children = \n\t[\n' + ''.join(
    '\t\t{\n\t\t\tm_ChildRef = resource:"particles/billy/%s.vpcf"\n\t\t},\n' % k for k in kids) + '\t]\n'
t, n = re.subn(r'\tm_Children = \n\t\[\n.*?\n\t\]\n', lambda m: block, rd('billy_trail'), flags=re.S)
assert n == 1
put('billy_combo_shot_trail', t)
