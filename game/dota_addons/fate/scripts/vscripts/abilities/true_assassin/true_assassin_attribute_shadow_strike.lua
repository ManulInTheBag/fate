-- true_assassin_attribute_shadow_strike — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/true_assassin/ta_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

true_assassin_attribute_shadow_strike = class({})

LinkLuaModifier("modifier_shadow_strike_upgrade", "abilities/true_assassin/modifiers/modifier_shadow_strike_upgrade", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/ta_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnShadowStrikeAcquired

OnShadowStrikeAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsShadowStrikeAcquired = true

	hero:AddNewModifier(caster, keys.ability, "modifier_shadow_strike_upgrade", {})

	-- Set master 1's mana
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function true_assassin_attribute_shadow_strike:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: ta_ability / OnShadowStrikeAcquired
	OnShadowStrikeAcquired({ caster = caster, ability = self, target = caster })
end
