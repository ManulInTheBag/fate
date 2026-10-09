# -*- coding: utf-8 -*-
"""Генерирует материалы и vmdl для Billy the Kid (content/dota_addons/fate/models/billy_kid).

⚠️ billy.vmdl после генерации правили руками в ModelDoc (замечено 06.10.2026: частоты
48 fps, обрезка bullet_idle 8-63, хитбоксы, имена узлов тегов bullets1/run1...).
Перезапуск скрипта эти правки СОТРЁТ — сначала перенести их сюда или править vmdl
точечно (ретрансляторы *_relay добавлены в vmdl именно так).
"""
import os
from PIL import Image

ROOT = r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\content\dota_addons\fate\models\billy_kid"
REL = "models/billy_kid"

# ---------------------------------------------------------------- маски альфы
# hero.vfx не берёт альфу из TextureColor: прозрачность = F_ALPHA_TEST + отдельная
# маска TextureTranslucency (белое = видно, чёрное = прозрачно).
for name in ("eye", "el", "ex"):
    im = Image.open(os.path.join(ROOT, name + ".png")).convert("RGBA")
    im.getchannel("A").save(os.path.join(ROOT, name + "_mask.png"))

# ---------------------------------------------------------------- материалы
# vmat -> (текстура, маска или None, материалы FBX)
MATS = {
    "billy_skin":      ("f.png",  None, ["顔", "爪", "手", "白目", "アイライン上", "二重", "眉毛", "歯", "口内", "舌"]),
    "billy_eye":       ("eye.png", "eye_mask.png", ["瞳", "目影"]),
    "billy_eyelight":  ("el.png", "el_mask.png", ["瞳光"]),
    "billy_expression":("ex.png", "ex_mask.png", ["表情"]),
    "billy_hair":      ("h.png",  None, ["髪"]),
    "billy_cloth_c01": ("c01.png", None, ["シャツ", "ﾈｸﾀｲ", "パンツ", "手袋", "ベルト赤", "ベルト留め具黒"]),
    "billy_cloth_c02": ("c02.png", None, ["ガンベルト革", "ガンベルト濃茶", "ブーツ"]),
    "billy_cloth_c03": ("c03.png", None, ["ベスト", "ジャケット", "ジャケット黒"]),
    "billy_metal_c04": ("c04.png", None, ["腕防具", "ベルト金具", "ガンベルト金属", "ブーツ金属", "ジャケット金属", "帽子金属"]),
    "billy_hat_c05":   ("c05.png", None, ["帽子", "帽子ベルト", "襟巻き"]),
    "billy_gun":       ("gunsub_gun.001_BaseColor.png", None, ["gun.001", "gun", "cylinder"]),
}

VMAT = """// THIS FILE IS AUTO-GENERATED

Layer0
{{
	shader "hero.vfx"

	//---- 2-Sided Rendering ----
	F_RENDER_BACKFACES 1

	//---- Effect Proxies ----
	F_USE_HERO_EFFECTS_PROXY 1
	F_USE_STATUS_EFFECTS_PROXY 1

	//---- Masks ----
	F_MASKS_1 1
	F_MASKS_2 1
{alpha_flag}
	//---- Color ----
	g_flDiffuseModulationAmount "1.000"
	g_flTexCoordRotation "0.000"
	g_vTexCoordOffset "[0.000 0.000]"
	g_vTexCoordScale "[1.000 1.000]"
	TextureColor "{tex}"

	//---- Fresnel ----
	g_flFresnelModulatesAlpha "0.000"
	TextureFresnelWarpColor "materials/default/default_fresnelwarpcolor.tga"
	TextureFresnelWarpRim "materials/default/default_fresnelwarprim.tga"
	TextureFresnelWarpSpec "materials/default/default_fresnelwarpspec.tga"

	//---- Lighting ----
	g_flAmbientScale "1.000"
	g_flBloomScale "0.000"
	g_flBloomShift "0.000"
	g_flOverbrightFactor "1.000"
	g_vBloomColor "[1.000000 1.000000 1.000000 0.000000]"

	//---- Mask 1 ----
	TextureDetailMask "materials/default/default_detailmask.tga"
	TextureDiffuseWarpMask "materials/default/default_diffusemask.tga"
	TextureMetalnessMask "materials/default/default_metalnessmask.tga"
	TextureSelfIllumMask "materials/default/default_selfillummask.tga"

	//---- Mask 2 ----
	TextureRimMask "[1.000000 1.000000 1.000000 0.000000]"
	TextureSpecularExponent "materials/default/default_specexp.tga"
	TextureSpecularMask "materials/default/default_specmask.tga"
	TextureTintByBaseMask "materials/default/default_basetintmask.tga"

	//---- Normal Map ----
	TextureNormal "materials/default/default_normal.tga"

	//---- Rim ----
	g_flRimLightScale "1.000"
	g_vRimLightColor "[1.000000 1.000000 1.000000 0.000000]"

	//---- Specular ----
	g_flSpecularExponent "16.000"
	g_flSpecularScale "0.300"
	g_vSpecularColor "[1.000000 1.000000 1.000000 0.000000]"
{alpha_block}}}
"""

for vmat, (tex, mask, _) in MATS.items():
    alpha_flag = alpha_block = ""
    if mask:
        alpha_flag = "\n\t//---- Translucency ----\n\tF_ALPHA_TEST 1\n"
        alpha_block = ('\n\t//---- Translucency ----\n\tg_flAlphaTestReference "0.500"\n'
                       '\tTextureTranslucency "%s/%s"\n' % (REL, mask))
    body = VMAT.format(alpha_flag=alpha_flag, tex="%s/%s" % (REL, tex), alpha_block=alpha_block)
    with open(os.path.join(ROOT, vmat + ".vmat"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write(body)

# ---------------------------------------------------------------- анимации
# (имя, fbx, активность, вес, looping, [activity modifiers], start, end)
#  start/end = -1 -> весь дубль. Все fbx: один дубль, 24 fps.
#  Теги: "bullets" — modifier_billy_bullets (D включена и пули есть),
#  "walk"/"run" — modifier_billy_gait (бег только выше run_speed); складываются.
ANIMS = [
    # (имя, fbx, активность, вес, looping, [activity modifiers], start, end, fps)
    # fps -1 = как в файле (24). Каст-анимации ускорены/обрезаны так, чтобы выстрел в
    # анимации совпадал с моментом выстрела в коде (пики скорости кисти по кривым fbx):
    #   trickshot — выстрел на 0.21–0.29 с; dust — на 0.75 с (до этого замах);
    #   dash_shoot — выстрел 0.25 с, потом прыжок; сам прыжок в коде длится 0.3 с.
    ("idle",          "Billy_idle1",              "ACT_DOTA_IDLE",              3, True,  [],               -1, -1, -1),
    ("idle_rare",     "Billy_idle2",              "ACT_DOTA_IDLE_RARE",         1, False, [],               -1, -1, -1),
    # ход/бег различаются тегом modifier_billy_gait (как run_fast/run_slow у Искандера):
    # "walk" — обычная скорость, "run" — выше run_speed (500) из KV D
    ("run",           "Billy_run",                "ACT_DOTA_RUN",               1, True,  ["run"],          -1, -1, -1),
    ("walk",          "Billy_walk",               "ACT_DOTA_RUN",               1, True,  ["walk"],         -1, -1, -1),
    ("attack",        "Billy_attack",             "ACT_DOTA_ATTACK",            1, False, [],               -1, -1, -1),
    ("death",         "Billy_death",              "ACT_DOTA_DIE",               1, False, [],               -1, -1, -1),
    ("stun",          "Billy_stun",               "ACT_DOTA_DISABLED",          1, True,  [],               -1, -1, -1),
    ("flail",         "Billy_stun",               "ACT_DOTA_FLAIL",             1, True,  [],               -1, -1, -1),
    ("bullet_idle",   "Billy_ability_bullet_idle","ACT_DOTA_IDLE",              1, True,  ["bullets"],      -1, -1, -1),
    ("bullet_run",    "Billy_ability_bullet_run", "ACT_DOTA_RUN",               1, True,  ["bullets", "run"],  -1, -1, -1),
    ("bullet_walk",   "Billy_ability_bullet_walk","ACT_DOTA_RUN",               1, True,  ["bullets", "walk"], -1, -1, -1),
    # Ретрансляторы для Billy_RefreshAnim (billy_shared.lua): копии стойки и хода с теми же
    # тегами под активностями, которых движок у героя сам не включает. Подмена на них на
    # 0.1 с заставляет перечитать теги без чужой позы посреди бега.
    ("idle_relay",        "Billy_idle1",              "ACT_DOTA_CUSTOM_TOWER_IDLE",      1, True, [],                  -1, -1, -1),
    ("bullet_idle_relay", "Billy_ability_bullet_idle","ACT_DOTA_CUSTOM_TOWER_IDLE",      1, True, ["bullets"],         -1, -1, -1),
    ("run_relay",         "Billy_run",                "ACT_DOTA_CUSTOM_TOWER_IDLE_RARE", 1, True, ["run"],             -1, -1, -1),
    ("walk_relay",        "Billy_walk",               "ACT_DOTA_CUSTOM_TOWER_IDLE_RARE", 1, True, ["walk"],            -1, -1, -1),
    ("bullet_run_relay",  "Billy_ability_bullet_run", "ACT_DOTA_CUSTOM_TOWER_IDLE_RARE", 1, True, ["bullets", "run"],  -1, -1, -1),
    ("bullet_walk_relay", "Billy_ability_bullet_walk","ACT_DOTA_CUSTOM_TOWER_IDLE_RARE", 1, True, ["bullets", "walk"], -1, -1, -1),
    # Q: каст-поинт 0.2 -> 30 fps, выстрел на ~0.2 с, вся 0.57 с
    ("trickshot",     "Billy_ability_trickshot",  "ACT_DOTA_CAST_ABILITY_1",    1, False, [],               -1, -1, 30),
    # W: с 10-го кадра (0.42 с замаха срезано), 30 fps -> выстрел на ~0.27 с под каст-поинт 0.3
    ("triple_shot",   "Billy_ability_dust",       "ACT_DOTA_CAST_ABILITY_2",    1, False, [],               10, 28, 30),
    # E: 40 fps -> 0.65 с вместо 1.08 (выстрел у dash_shoot на ~0.15 с)
    ("skedaddle",     "Billy_ability_dash",       "ACT_DOTA_CAST_ABILITY_3",    1, False, [],               -1, -1, 40),
    ("skedaddle_shoot","Billy_ability_dash_shoot","ACT_DOTA_CAST_ABILITY_3",    1, False, ["bullets"],      -1, -1, 40),
    # Highnoon: 54 кадра. Замах (каст-поинт 0.3 с = ~7 кадров) и прицеливание (ченнел).
    ("highnoon_draw", "Billy_ability_highnoon",   "ACT_DOTA_CAST_ABILITY_6",    1, False, [],                0,  7, -1),
    ("highnoon_aim",  "Billy_ability_highnoon",   "ACT_DOTA_CHANNEL_ABILITY_6", 1, False, [],                7, 54, -1),
    # комбо: каст-поинт 0.6 -> trickshot на 12 fps, выстрел на ~0.5 с
    ("combo",         "Billy_ability_trickshot",  "ACT_DOTA_CAST_ABILITY_7",    1, False, [],               -1, -1, 12),
    # комбо-засада (08.10.2026): стойка держится до 6 с — один последний кадр прицеливания
    # Highnoon в цикле (кусок 7..54 в цикле прыгал бы на стыке, а сыграть его один раз и
    # замереть — не гарантировано движком). Замах — highnoon_draw (CAST_ABILITY_6).
    ("combo_hold",    "Billy_ability_highnoon",   "ACT_DOTA_CHANNEL_ABILITY_7", 1, True,  [],               54, 54, -1),
]

def animfile(name, fbx, act, weight, loop, mods, start, end, fps):
    children = ""
    if mods:
        items = "".join(
            '\t\t\t\t\t\t\t{\n'
            '\t\t\t\t\t\t\t\t_class = "ActivityModifier"\n'
            '\t\t\t\t\t\t\t\tname = "%s"\n'
            '\t\t\t\t\t\t\t\tactivity_name = "%s"\n'
            '\t\t\t\t\t\t\t\tactivity_weight = 1\n'
            '\t\t\t\t\t\t\t},\n' % (m, m) for m in mods)
        children = '\t\t\t\t\t\tchildren = \n\t\t\t\t\t\t[\n%s\t\t\t\t\t\t]\n' % items
    return (
        '\t\t\t\t\t{\n'
        '\t\t\t\t\t\t_class = "AnimFile"\n'
        '\t\t\t\t\t\tname = "%s"\n%s'
        '\t\t\t\t\t\tis_default_idle_anim = %s\n'
        '\t\t\t\t\t\tactivity_name = "%s"\n'
        '\t\t\t\t\t\tactivity_weight = %d\n'
        '\t\t\t\t\t\tweight_list_name = ""\n'
        '\t\t\t\t\t\tfade_in_time = 0.2\n'
        '\t\t\t\t\t\tfade_out_time = 0.2\n'
        '\t\t\t\t\t\tlooping = %s\n'
        '\t\t\t\t\t\tdelta = false\n'
        '\t\t\t\t\t\tworldSpace = false\n'
        '\t\t\t\t\t\thidden = false\n'
        '\t\t\t\t\t\tanim_markup_ordered = false\n'
        '\t\t\t\t\t\tdisable_compression = false\n'
        '\t\t\t\t\t\tanimgraph_additive = false\n'
        '\t\t\t\t\t\tdelete_from_compiled_model = false\n'
        '\t\t\t\t\t\tsource_filename = "%s/%s.fbx"\n'
        '\t\t\t\t\t\timport_bone_scales = false\n'
        '\t\t\t\t\t\tstart_frame = %d\n'
        '\t\t\t\t\t\tend_frame = %d\n'
        '\t\t\t\t\t\tframerate = %.1f\n'
        '\t\t\t\t\t\treverse = false\n'
        '\t\t\t\t\t\tadditional_anim_files = [  ]\n'
        '\t\t\t\t\t},\n'
    ) % (name, children, "true" if name == "idle" else "false", act, weight,
         "true" if loop else "false", REL, fbx, start, end, float(fps))

remaps = "".join(
    '\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\tfrom = "%s.vmat"\n\t\t\t\t\t\t\t\tto = "%s/%s.vmat"\n\t\t\t\t\t\t\t},\n'
    % (src, REL, vmat) for vmat, (_, _, srcs) in MATS.items() for src in srcs)
# gun.001: точка в имени -> ModelDoc не резолвит материал и оставляет пустое имя
remaps += ('\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\tfrom = ""\n\t\t\t\t\t\t\t\tto = "%s/billy_gun.vmat"\n\t\t\t\t\t\t\t},\n' % REL)

ATTACH = [  # имя, кость, смещение
    ("attach_hitloc",  "UpperBody2", (0, 0, 0)),
    ("attach_attack1", "gun_1",      (0, 0, 0)),
    ("attach_attack2", "gun_1",      (0, 0, 0)),
    ("attach_head",    "Head",       (0, 0, 0)),
]
attachments = "".join(
    '\t\t\t\t\t{\n'
    '\t\t\t\t\t\t_class = "Attachment"\n'
    '\t\t\t\t\t\tname = "%s"\n'
    '\t\t\t\t\t\tparent_bone = "%s"\n'
    '\t\t\t\t\t\trelative_origin = [ %.1f, %.1f, %.1f ]\n'
    '\t\t\t\t\t\trelative_angles = [ 0.0, 0.0, 0.0 ]\n'
    '\t\t\t\t\t\tweight = 1.0\n'
    '\t\t\t\t\t\tignore_rotation = false\n'
    '\t\t\t\t\t},\n' % (n, b, o[0], o[1], o[2]) for n, b, o in ATTACH)

# Меши MMD-физики (Geometry "Rigidbody.NNN", "mmd_*") в модель не идут: берём только
# тело и револьвер. ⚠️ Фильтр матчит имена Geometry (не Model), точка -> "_".
KEEP_MESHES = ["billy the kid",
               "Plane_007", "Plane_008", "Plane_005", "Plane_006", "Plane_009"]  # gun, hammer, cylinder, cylinder_opener, trigger
keep = "".join('\t\t\t\t\t\t\t\t"%s",\n' % m for m in KEEP_MESHES)

VMDL = """<!-- kv3 encoding:text:version{e21c7f3c-8a33-41c5-9977-a76d3a32aa0d} format:modeldoc41:version{12fc9d44-453a-4ae4-b4d9-7e2ac0bbd4e0} -->
{
	rootNode =
	{
		_class = "RootNode"
		children =
		[
			{
				_class = "MaterialGroupList"
				children =
				[
					{
						_class = "DefaultMaterialGroup"
						remaps =
						[
%(remaps)s						]
						use_global_default = false
						global_default_material = ""
					},
				]
			},
			{
				_class = "RenderMeshList"
				children =
				[
					{
						_class = "RenderMeshFile"
						name = "billy"
						filename = "%(rel)s/Billy_model.fbx"
						import_scale = 1.0
						import_filter =
						{
							exclude_by_default = true
							exception_list =
							[
%(keep)s							]
						}
					},
				]
			},
			{
				_class = "AnimationList"
				children =
				[
%(anims)s				]
				default_root_bone_name = ""
			},
			{
				_class = "AttachmentList"
				children =
				[
%(attach)s				]
			},
			{
				_class = "ModelModifierList"
				children =
				[
					{
						_class = "ModelModifier_ScaleAndMirror"
						scale = %(scale)s
						mirror_x = false
						mirror_y = false
						mirror_z = false
						flip_bone_forward = false
						swap_left_and_right_bones = false
					},
				]
			},
		]
		model_archetype = ""
		primary_associated_entity = ""
		anim_graph_name = ""
		base_model_name = ""
	}
}
"""
SCALE = os.environ.get("BILLY_SCALE", "0.32")  # 0.4 -> юзер: на 20% меньше
out = VMDL % dict(remaps=remaps, rel=REL, keep=keep, anims="".join(animfile(*a) for a in ANIMS),
                  attach=attachments, scale=SCALE)
with open(os.path.join(ROOT, "billy.vmdl"), "w", encoding="utf-8", newline="\r\n") as f:
    f.write(out)
print("ok", len(MATS), "vmat,", len(ANIMS), "anims, scale", SCALE)
