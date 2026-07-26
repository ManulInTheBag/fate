-- true_assassin_attribute_shaytan_arm — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/true_assassin/ta_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

true_assassin_attribute_shaytan_arm = class({})

LinkLuaModifier("modifier_shaytan_arm_attribute", "abilities/true_assassin/modifiers/modifier_shaytan_arm_attribute", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/ta_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnShaytanArmAcquired

OnShaytanArmAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local ability = keys.ability
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.ShaytanArmAcquired = true

	Timers:CreateTimer(function()
		if hero:IsAlive() then
	    hero:AddNewModifier(hero, ability, "modifier_shaytan_arm_attribute", {} )
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function true_assassin_attribute_shaytan_arm:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: ta_ability / OnShaytanArmAcquired
	OnShaytanArmAcquired({ caster = caster, ability = self, target = caster })
end
