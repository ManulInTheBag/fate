-- false_assassin_attribute_improve_minds_eye — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/sasaki/sasaki_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

false_assassin_attribute_improve_minds_eye = class({})
LinkLuaModifier("modifier_minds_eye_attribute", "abilities/sasaki/modifiers/modifier_minds_eye_attribute", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/fa_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMindsEyeImproved

OnMindsEyeImproved = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsMindsEyeAcquired = true
	hero:FindAbilityByName("false_assassin_minds_eye"):SetLevel(2) 	

	Timers:CreateTimer(function()
		if hero:IsAlive() then 
			hero:AddNewModifier(hero, keys.ability, "modifier_minds_eye_attribute", {})
			return nil
		else
			return 1
		end
	end)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function false_assassin_attribute_improve_minds_eye:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: fa_ability / OnMindsEyeImproved
	OnMindsEyeImproved({ caster = caster, ability = self, target = caster })
end
