-- false_assassin_attribute_eye_of_serenity — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/sasaki/sasaki_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

false_assassin_attribute_eye_of_serenity = class({})

-- Логика перенесена из scripts/vscripts/fa_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnEyeOfSerenityAcquired

OnEyeOfSerenityAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsEyeOfSerenityAcquired = true
	hero.IsEyeOfSerenityActive = false

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function false_assassin_attribute_eye_of_serenity:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: fa_ability / OnEyeOfSerenityAcquired
	OnEyeOfSerenityAcquired({ caster = caster, ability = self, target = caster })
end
