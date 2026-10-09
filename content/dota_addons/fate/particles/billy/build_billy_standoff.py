# -*- coding: utf-8 -*-
"""Конус-засада комбо Билли (Thunderer, переделка 08.10.2026): пол + две стенки + кромка.

Юзер: конус комбо должен быть ДРУГИМ, чем конус ульты (красный клин Распутина), другого
цвета и со «стенками». Тема фантазма — гром/молния, поэтому всё электрически-синее.

Устройство (все цвета — из Lua, BILLY_COMBO_FX в billy_combo.lua; CP-цвета 0..255):
  billy_standoff_floor   пол-клин: КОПИЯ billy_highnoon_cone (= rasputin_skill_mark_widea,
                         проверен в игре) — CP0/CP1 Билли, CP2 конец оси, CP3.x полуширина
                         у края, CP4 цвет, CP6.x 1. Второй слой (у R выключен) — плазма
                         beam_plasma_04, бежит вдоль оси: яркая середина ленты = ось прицела.
                         На endcap не гаснет мгновенно, а тает 0.15 с.
  billy_standoff_wall    вертикальная стенка вдоль края: лента CP1 -> CP2, нормаль частиц =
                         CP7 (горизонтальный перпендикуляр к краю, ставит Lua). Ширина ленты
                         (радиус) = высота стенки WALL_H; середина ленты — у земли, нижняя
                         половина уходит под террейн (z-буфер включён), видна верхняя: от
                         яркой кромки у земли к прозрачному верху. При создании «вырастает»
                         из земли за WALL_RISE. CP4 — цвет стенки, CP5 — цвет кромок.
                         Дети: billy_standoff_line (кромка по земле), billy_standoff_wall_top
                         (тонкая линия по верху), billy_standoff_wall_sparks (электрические
                         разряды вдоль стенки — копия стоковых искр стены Disruptor).
  billy_standoff_line    яркая линия по земле CP1 -> CP2 (без z-буфера), цвет CP5.
  billy_standoff_edge    тёмная полупрозрачная подложка (обычное смешивание) с кромкой
                         billy_standoff_line ребёнком — контраст поверх чужих эффектов;
                         ей рисуются кромки у стенок и дальний край конуса (CP1 -> CP2, CP5).
  billy_highnoon_wall    то же, что стенка, для конуса ульты (R): красные искры
                         billy_highnoon_wall_sparks; пол и кромки ульта берёт общие.

Нормаль: лента ALIGN_TO_PARTICLE_NORMAL лежит в плоскости, перпендикулярной нормали
частицы. У пола нормаль по умолчанию (вверх) — лента плоская; у стенки — горизонтальная,
лента встаёт вертикально (так устроена стена Disruptor: InitVec нормали (0,1,0)).

⚠️ Все числа в float-полях — с точкой (целый литерал в рантайме = 0, см. build_billy_fx.py).

Запуск из этой папки:  python build_billy_standoff.py
Компиляция (без -game: с ним падает на gameinfo.gi):
    resourcecompiler -i "<полный путь>/particles/billy/billy_standoff*.vpcf"
"""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
S2V = r"C:\Users\glebu\Tools\s2v\Source2Viewer-CLI.exe"
VPK = r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\pak01_dir.vpk"

WALL_H      = 150.0    # высота стенки над землёй
WALL_RISE   = 0.25     # за сколько секунд стенка вырастает из земли
WALL_ALPHA  = 1.0      # было 0.6 → 0.8 → 1.0 (юзер 09.10.2026: конус тонет в чужих эффектах)
WALL_GLOW   = 2.0      # overbright стенки
FLOOR_ALPHA = 0.45     # было 0.32 (у R 0.42); поднято вместе со стенками 09.10.2026
LINE_R      = 11.0     # полуширина кромки по земле (было 7)
LINE_GLOW   = 3.5      # overbright кромки (было 2)
TOP_R       = 4.0      # полуширина линии по верху стенки (было 3)
# Контраст: под яркой кромкой — тёмная полупрозрачная полоса (обычное смешивание, не
# аддитив): красное/синее аддитивное поверх красного чужого эффекта сливается, а светлая
# линия на тёмной подложке читается на любом фоне. billy_standoff_edge = подложка + кромка.
SHADOW_R     = 30.0
SHADOW_ALPHA = 0.6
PATH_N      = 32       # точек ленты вдоль края (2500+ длины)

HEADER = ('<!-- kv3 encoding:text:version{e21c7f3c-8a33-41c5-9977-a76d3a32aa0d} '
          'format:vpcf66:version{dd571be4-586e-4f41-8b2d-5bbc969e1c53} -->\n')


def f(x):
    """float-литерал: всегда с точкой"""
    s = repr(float(x))
    return s if '.' in s or 'e' in s else s + '.0'


def write(name, text):
    assert re.search(r'm_fl\w+ = -?\d+\n', text) is None, (name, 'целый литерал во float-поле')
    with open(os.path.join(HERE, name + '.vpcf'), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text)
    print('wrote', name + '.vpcf')


def replace_once(s, a, b, what):
    assert s.count(a) == 1, (what, s.count(a))
    return s.replace(a, b)


# ---------------------------------------------------------------- общие куски (из billy_highnoon_cone)
def path_init(n):
    return ('\t\t{\n\t\t\t_class = "C_INIT_CreateSequentialPathV2"\n'
            '\t\t\tm_flNumToAssign = %s\n'
            '\t\t\tm_PathParams = \n\t\t\t{\n'
            '\t\t\t\tm_nStartControlPointNumber = 1\n'
            '\t\t\t\tm_nEndControlPointNumber = 2\n'
            '\t\t\t}\n\t\t},\n') % f(n)


def init_float(value, field):
    return ('\t\t{\n\t\t\t_class = "C_INIT_InitFloat"\n'
            '\t\t\tm_InputValue = \n\t\t\t{\n'
            '\t\t\t\tm_nType = "PF_TYPE_LITERAL"\n'
            '\t\t\t\tm_flLiteralValue = %s\n'
            '\t\t\t}\n\t\t\tm_nOutputField = %d\n\t\t},\n') % (f(value), field)


def path_ops(n, ground_offset):
    return ('\t\t{\n\t\t\t_class = "C_OP_BasicMovement"\n\t\t},\n'
            '\t\t{\n\t\t\t_class = "C_OP_MaintainSequentialPath"\n'
            '\t\t\tm_flTolerance = 2.0\n'
            '\t\t\tm_flNumToAssign = %s\n'
            '\t\t\tm_PathParams = \n\t\t\t{\n'
            '\t\t\t\tm_nEndControlPointNumber = 2\n'
            '\t\t\t\tm_nStartControlPointNumber = 1\n'
            '\t\t\t}\n\t\t},\n'
            '\t\t{\n\t\t\t_class = "C_OP_MovementPlaceOnGround"\n'
            '\t\t\tm_CollisionGroupName = "DEBRIS"\n'
            '\t\t\tm_flTraceOffset = 128.0\n'
            '\t\t\tm_flMaxTraceLength = 512.0\n'
            '\t\t\tm_flTolerance = 2.0\n'
            '\t\t\tm_nRefCP2 = 1\n'
            '\t\t\tm_nRefCP1 = 2\n'
            '\t\t\tm_flOffset = %s\n\t\t},\n') % (f(n), f(ground_offset))


def color_op(cp):
    return ('\t\t{\n\t\t\t_class = "C_OP_RemapCPtoVector"\n'
            '\t\t\tm_nCPInput = %d\n'
            '\t\t\tm_nFieldOutput = 6\n'
            '\t\t\tm_vInputMax = [ 255.0, 255.0, 255.0 ]\n'
            '\t\t\tm_vOutputMax = [ 1.0, 1.0, 1.0 ]\n\t\t},\n') % cp


# endcap (DestroyParticle(fx, false)): альфа тает, через decay с — частицы умирают
def endcap_fade(rate=-4.0, decay=0.3):
    return ('\t\t{\n\t\t\t_class = "C_OP_RampScalarLinearSimple"\n'
            '\t\t\tm_Rate = %s\n\t\t\tm_flEndTime = 100000.0\n\t\t\tm_nField = 7\n'
            '\t\t\tm_nOpEndCapState = "PARTICLE_ENDCAP_ENDCAP_ON"\n\t\t},\n'
            '\t\t{\n\t\t\t_class = "C_OP_EndCapTimedDecay"\n'
            '\t\t\tm_flDecayTime = %s\n\t\t},\n') % (f(rate), f(decay))


def ropes(texture, world_v, scroll, flat=True, zbuffer=True, overbright=None, alpha=None, radius=None,
          blend='ADD'):
    s = ('\t\t{\n\t\t\t_class = "C_OP_RenderRopes"\n'
         '\t\t\tm_nMinTesselation = 4\n\t\t\tm_nMaxTesselation = 4\n'
         '\t\t\tm_flTextureVWorldSize = %s\n'
         '\t\t\tm_flTextureVScrollRate = %s\n') % (f(world_v), f(scroll))
    if flat:
        s += '\t\t\tm_nOrientationType = "PARTICLE_ORIENTATION_ALIGN_TO_PARTICLE_NORMAL"\n'
    if radius is not None:
        s += '\t\t\tm_flRadiusScale = %s\n' % f(radius)
    if alpha is not None:
        s += ('\t\t\tm_flAlphaScale = \n\t\t\t{\n\t\t\t\tm_nType = "PF_TYPE_LITERAL"\n'
              '\t\t\t\tm_flLiteralValue = %s\n\t\t\t}\n') % f(alpha)
    s += ('\t\t\tm_vecTexturesInput = \n\t\t\t[\n\t\t\t\t{\n'
          '\t\t\t\t\tm_hTexture = resource:"%s"\n\t\t\t\t},\n\t\t\t]\n'
          '\t\t\tm_nOutputBlendMode = "PARTICLE_OUTPUT_BLEND_MODE_%s"\n') % (texture, blend)
    if overbright is not None:
        s += '\t\t\tm_flOverbrightFactor = %s\n' % f(overbright)
    if zbuffer:
        s += '\t\t\tm_nFeatheringMode = "PARTICLE_DEPTH_FEATHERING_ON_OPTIONAL"\n'
    else:
        s += '\t\t\tm_bDisableZBuffering = true\n'
    return s + '\t\t},\n'


def system(n, initializers, operators, renderers, children=()):
    s = HEADER + ('{\n\t_class = "CParticleSystemDefinition"\n'
                  '\tm_bShouldHitboxesFallbackToRenderBounds = false\n'
                  '\tm_nMaxParticles = %d\n'
                  '\tm_flConstantRadius = 10.0\n'
                  '\tm_nBehaviorVersion = 12\n'
                  '\tm_nFirstMultipleOverride_BackwardCompat = 5\n'
                  '\tm_Emitters = \n\t[\n'
                  '\t\t{\n\t\t\t_class = "C_OP_InstantaneousEmitter"\n'
                  '\t\t\tm_nParticlesToEmit = \n\t\t\t{\n'
                  '\t\t\t\tm_nType = "PF_TYPE_LITERAL"\n'
                  '\t\t\t\tm_flLiteralValue = %s\n'
                  '\t\t\t}\n\t\t},\n\t]\n') % (n, f(n))
    s += '\tm_Initializers = \n\t[\n' + initializers + '\t]\n'
    s += '\tm_Operators = \n\t[\n' + operators + '\t]\n'
    s += '\tm_Renderers = \n\t[\n' + renderers + '\t]\n'
    if children:
        s += '\tm_Children = \n\t[\n'
        for ref, delay in children:
            s += '\t\t{\n\t\t\tm_ChildRef = resource:"particles/billy/%s.vpcf"\n' % ref
            if delay:
                s += '\t\t\tm_flDelay = %s\n' % f(delay)
            s += '\t\t},\n'
        s += '\t]\n'
    return s + '}\n'


# ---------------------------------------------------------------- пол
def build_floor():
    s = open(os.path.join(HERE, 'billy_highnoon_cone.vpcf'), encoding='utf-8').read()
    s = replace_once(s, 'm_flLiteralValue = 0.42\n', 'm_flLiteralValue = %s\n' % f(FLOOR_ALPHA), 'alpha')
    # начальный радиус ленты 0.9 масштабирует ширину из CP3 (SET_SCALE_INITIAL_VALUE) — пол
    # выходил на 10% уже треугольника, и стенки по его углам торчали наружу (у R при 150°
    # зазор в сотни единиц; скриншот юзера 09.10.2026). Ровно 1.0: края пола = края стенок.
    s = replace_once(s, 'm_flLiteralValue = 0.9\n', 'm_flLiteralValue = 1.0\n', 'radius')
    s = replace_once(s, '\t\t{\n\t\t\t_class = "C_OP_Decay"\n\t\t\tm_nOpEndCapState = "PARTICLE_ENDCAP_ENDCAP_ON"\n\t\t},\n',
                     endcap_fade(-3.0, 0.2), 'endcap')
    # второй рендерер (у R выключен, та же текстура) -> плазма вдоль оси
    head = '\t\t{\n\t\t\t_class = "C_OP_RenderRopes"\n'
    assert s.count(head) == 2, 'два рендерера у пола'
    a = s.index(head, s.index(head) + 1)
    b = s.index('\n\t\t},\n', a) + len('\n\t\t},\n')       # конец блока — строка ровно с двумя табами
    assert 'm_bDisableOperator = true' in s[a:b], 'второй рендерер пола'
    s = s[:a] + ropes('materials/particle/beam_plasma_04.vtex', 1400.0, 900.0,
                      zbuffer=False, alpha=0.8) + s[b:]
    write('billy_standoff_floor', s)


# ---------------------------------------------------------------- стенка
def build_wall(name='billy_standoff_wall', sparks='billy_standoff_wall_sparks'):
    inits = (path_init(PATH_N)
             + init_float(0.0, 3)                       # высота растёт из нуля
             + init_float(WALL_ALPHA, 7)
             + init_float(1.0, 1)
             + ('\t\t{\n\t\t\t_class = "C_INIT_InitVec"\n'
                '\t\t\tm_InputValue = \n\t\t\t{\n'
                '\t\t\t\tm_nType = "PVEC_TYPE_CP_VALUE"\n'
                '\t\t\t\tm_nControlPoint = 7\n'
                '\t\t\t}\n\t\t\tm_nOutputField = 21\n\t\t},\n'))
    ops = (path_ops(PATH_N, 8.0)
           + ('\t\t{\n\t\t\t_class = "C_OP_RampScalarLinearSimple"\n'
              '\t\t\tm_Rate = %s\n\t\t\tm_flEndTime = %s\n\t\t\tm_nField = 3\n\t\t},\n')
           % (f(WALL_H / WALL_RISE), f(WALL_RISE))
           + color_op(4)
           + endcap_fade())
    rend = (ropes('materials/particle/beam_plasma_04.vtex', 1200.0, 260.0, overbright=WALL_GLOW)
            + ropes('materials/particle/beam_noise05.vtex', 900.0, -650.0, alpha=0.9, radius=0.85,
                    overbright=WALL_GLOW))
    write(name, system(PATH_N, inits, ops, rend, children=(
        ('billy_standoff_edge', 0.0),
        ('billy_standoff_wall_top', WALL_RISE),
        (sparks, 0.1),
    )))


def build_line(name, radius, offset, alpha, flat, zbuffer, overbright):
    inits = path_init(PATH_N) + init_float(radius, 3) + init_float(alpha, 7) + init_float(1.0, 1)
    ops = path_ops(PATH_N, offset) + color_op(5) + endcap_fade()
    rend = ropes('materials/particle/beam_hotwhite.vtex', 800.0, 800.0, flat=flat, zbuffer=zbuffer,
                 overbright=overbright)
    write(name, system(PATH_N, inits, ops, rend))


# Тёмная подложка под кромку (CP1 -> CP2, как у линии) с яркой кромкой ребёнком — ребёнок
# рисуется поверх родителя. Чёрный цвет, обычное смешивание, без z-буфера.
def build_edge():
    inits = (path_init(PATH_N) + init_float(SHADOW_R, 3) + init_float(SHADOW_ALPHA, 7)
             + init_float(1.0, 1)
             + '\t\t{\n\t\t\t_class = "C_INIT_RandomColor"\n'
               '\t\t\tm_ColorMin = [ 0, 0, 0 ]\n\t\t\tm_ColorMax = [ 0, 0, 0 ]\n\t\t},\n')
    ops = path_ops(PATH_N, 4.0) + endcap_fade()
    rend = ropes('materials/particle/beam_hotwhite.vtex', 800.0, 0.0, flat=True, zbuffer=False,
                 blend='ALPHA')
    write('billy_standoff_edge', system(PATH_N, inits, ops, rend, children=(
        ('billy_standoff_line', 0.0),
    )))


# ---------------------------------------------------------------- разряды вдоль стенки
# Цвет искр зашит в копии Disruptor (голубой); для стенок ульты — красные (RED_SPARKS).
RED_SPARKS = {'min': '[ 255, 70, 30 ]', 'max': '[ 255, 150, 70 ]', 'fade': '[ 255, 40, 20 ]'}


def build_sparks(name='billy_standoff_wall_sparks', colors=None):
    src_dir = 'particles/units/heroes/hero_disruptor'
    src = 'disruptor_static_wall_barrier_electric_spark'
    tmp = tempfile.mkdtemp(prefix='billy_standoff_')
    subprocess.run([S2V, '-i', VPK, '--vpk_filepath', src_dir + '/' + src + '.vpcf_c', '-d', '-o', tmp],
                   check=True, stdout=subprocess.DEVNULL)
    s = open(os.path.join(tmp, *src_dir.split('/'), src + '.vpcf'), encoding='utf-8').read()
    # вдоль края конуса: CP1 -> CP2 (у Disruptor CP0 -> CP1)
    s = replace_once(s, '\t\t\tm_PathParams = \n\t\t\t{\n\t\t\t\tm_nEndControlPointNumber = 1\n\t\t\t}\n',
                     '\t\t\tm_PathParams = \n\t\t\t{\n\t\t\t\tm_nStartControlPointNumber = 1\n'
                     '\t\t\t\tm_nEndControlPointNumber = 2\n\t\t\t}\n', 'path')
    # по всей высоте стенки, а не только у верха (у Disruptor 200..250)
    s = replace_once(s, 'm_flRandomMin = 200.0\n', 'm_flRandomMin = 12.0\n', 'h min')
    s = replace_once(s, 'm_flRandomMax = 250.0\n', 'm_flRandomMax = %s\n' % f(WALL_H * 0.9), 'h max')
    # стенка длиннее (до ~2600) — разрядов чаще: вместо кривой (~20/с) ровно 70/с
    s = re.sub(r'(m_nParticlesToEmit|m_flEmitRate) = \n\t\t\t\{\n\t\t\t\tm_nType = "PF_TYPE_LITERAL"\n'
               r'\t\t\t\tm_nMapType = "PF_MAP_TYPE_CURVE"\n\t\t\t\tm_flLiteralValue = 30.0\n',
               lambda m: m.group(1) + ' = \n\t\t\t{\n\t\t\t\tm_nType = "PF_TYPE_LITERAL"\n'
                         '\t\t\t\tm_nMapType = "PF_MAP_TYPE_DIRECT"\n\t\t\t\tm_flLiteralValue = 70.0\n', s, count=1)
    assert 'm_flLiteralValue = 70.0\n' in s, 'emit rate'
    s = s.replace('m_nMaxParticles = 12\n', 'm_nMaxParticles = 48\n')
    if colors:
        s = replace_once(s, 'm_ColorMin = [ 9, 238, 255 ]', 'm_ColorMin = %s' % colors['min'], 'spark min')
        s = replace_once(s, 'm_ColorMax = [ 37, 190, 237 ]', 'm_ColorMax = %s' % colors['max'], 'spark max')
        s = replace_once(s, 'm_ColorFade = [ 45, 150, 255 ]', 'm_ColorFade = %s' % colors['fade'], 'spark fade')
    write(name, s)


def main():
    build_floor()
    build_wall()
    build_line('billy_standoff_line', LINE_R, 6.0, 1.0, flat=True, zbuffer=False, overbright=LINE_GLOW)
    build_edge()
    build_line('billy_standoff_wall_top', TOP_R, WALL_H, 1.0, flat=False, zbuffer=True, overbright=2.5)
    build_sparks()
    # конус ульты (юзер 09.10.2026: «улучшить по аналогии с комбо») — пол и кромки общие
    # (цвет из Lua), стенка своя только ради красных искр
    build_wall('billy_highnoon_wall', 'billy_highnoon_wall_sparks')
    build_sparks('billy_highnoon_wall_sparks', RED_SPARKS)


if __name__ == '__main__':
    sys.exit(main())
