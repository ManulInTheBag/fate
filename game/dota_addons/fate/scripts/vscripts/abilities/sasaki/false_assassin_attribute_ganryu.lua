-- false_assassin_attribute_ganryu — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/sasaki/sasaki_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

false_assassin_attribute_ganryu = class({})
LinkLuaModifier("modifier_ganryu_attribute", "abilities/sasaki/modifiers/modifier_ganryu_attribute", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/fa_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGanryuAcquired

OnGanryuAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsGanryuAcquired = true

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, keys.ability, "modifier_ganryu_attribute", {})
			return nil
		else
			return 1
		end
	end)

	print("Ganryu acquired")
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function false_assassin_attribute_ganryu:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: fa_ability / OnGanryuAcquired
	OnGanryuAcquired({ caster = caster, ability = self, target = caster })
end
