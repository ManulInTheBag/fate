-- gilgamesh_attribute_sword_of_creation — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilgamesh/gilgamesh_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gilgamesh_attribute_sword_of_creation = class({})

-- Логика перенесена из scripts/vscripts/gilg_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSwordOfCreationAcquired

OnSwordOfCreationAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsEnumaImproved = true

	-- Set master 1's mana
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function gilgamesh_attribute_sword_of_creation:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: gilg_ability / OnSwordOfCreationAcquired
	OnSwordOfCreationAcquired({ caster = caster, ability = self, target = caster })
end
