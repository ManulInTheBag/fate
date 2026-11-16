require("libraries/skin_fx")

-- Реплики хода и атаки Медеи. Эти две реплики движок выбирает на клиенте владельца,
-- и метку скина (customresponse) он там не видит. Поэтому обычные события
-- crystalmaiden_cm_move_* / attack_* тихие (тип dota_src1_3d), а голос играет отсюда:
-- только владельцу, как в Доте. События — в game_sounds_vo_crystalmaiden.vsndevts.
MEDEA_ORDER_VOICE = {
	[0] = { move = { "medea_vo_move_01", "medea_vo_move_02", "medea_vo_move_03" },
	        attack = { "medea_vo_attack_01", "medea_vo_attack_02", "medea_vo_attack_03", "medea_vo_attack_04" } },
	[1] = { move = { "medea_skin1_vo_move_01", "medea_skin1_vo_move_02", "medea_skin1_vo_move_03" },
	        attack = { "medea_skin1_vo_attack_01", "medea_skin1_vo_attack_02", "medea_skin1_vo_attack_03", "medea_skin1_vo_attack_04" } },
}
MEDEA_ORDER_VOICE_COOLDOWN = 4   -- движок сам говорил не чаще раза в 4-6 с

local ORDER_KIND = {
	[DOTA_UNIT_ORDER_MOVE_TO_POSITION] = "move",
	[DOTA_UNIT_ORDER_MOVE_TO_TARGET]   = "move",
	[DOTA_UNIT_ORDER_ATTACK_TARGET]    = "attack",
	[DOTA_UNIT_ORDER_ATTACK_MOVE]      = "attack",
}

function MedeaVoiceOrderFilter(hUnit, iOrder, iPlayerID)
	local kind = ORDER_KIND[iOrder]
	if not kind or not IsNotNull(hUnit) or not hUnit:IsRealHero() or not hUnit:IsAlive() then return end
	if hUnit:GetUnitName() ~= "npc_dota_hero_crystal_maiden" or hUnit:GetPlayerOwnerID() ~= iPlayerID then return end

	local now = GameRules:GetGameTime()
	if (hUnit.medeaVoiceNext or 0) > now then return end
	hUnit.medeaVoiceNext = now + MEDEA_ORDER_VOICE_COOLDOWN

	local skin = GetSkinNumber(hUnit)
	if not SkinSoundHeard(hUnit, iPlayerID) then skin = 0 end   -- «Звуки скинов» -> «свой» выключен
	local list = (MEDEA_ORDER_VOICE[skin] or MEDEA_ORDER_VOICE[0])[kind]
	EmitSoundOnEntityForPlayer(list[RandomInt(1, #list)], hUnit, iPlayerID)
end