-- gilgamesh_attribute_power_of_sumer — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilgamesh/gilgamesh_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gilgamesh_attribute_power_of_sumer = class({})

-- Логика перенесена из scripts/vscripts/gilg_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnPowerOfSumerAcquired

OnPowerOfSumerAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if not hero then
		hero = caster.HeroUnit
	end

	hero.IsSumerAcquired = true

	-- Set master 1's mana
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function gilgamesh_attribute_power_of_sumer:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: gilg_ability / OnPowerOfSumerAcquired
	OnPowerOfSumerAcquired({ caster = caster, ability = self, target = caster })
end
