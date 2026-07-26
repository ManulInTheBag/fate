-- fate_experience_thinker — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

fate_experience_thinker = class({})

LinkLuaModifier("fate_experience_passive_aura", "abilities/general/fate_experience_thinker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("fate_experience_passive", "abilities/general/fate_experience_thinker", LUA_MODIFIER_MOTION_NONE)

function fate_experience_thinker:GetIntrinsicModifierName()
	return "fate_experience_passive_aura"
end

fate_experience_passive_aura = class({})

function fate_experience_passive_aura:IsHidden() return true end

function fate_experience_passive_aura:IsAura() return true end
function fate_experience_passive_aura:GetModifierAura() return "fate_experience_passive" end
function fate_experience_passive_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("range") end
function fate_experience_passive_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_BOTH end
function fate_experience_passive_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function fate_experience_passive_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end

fate_experience_passive = class({})


function fate_experience_passive:OnCreated(kv)
	if not IsServer() then return end
	self:StartIntervalThink(1.0)
end

function fate_experience_passive:OnRefresh(kv)
	self:OnCreated(kv)
end

function fate_experience_passive:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: libraries/util / OnExperienceZoneThink
	OnExperienceZoneThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end
