-- nursery_rhyme_attribute_improve_queens_glass_game — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nursery_rhyme/nursery_rhyme_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nursery_rhyme_attribute_improve_queens_glass_game = class({})

-- Логика перенесена из scripts/vscripts/nursery_rhyme_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnImproveQGGAcquired

OnImproveQGGAcquired = function(keys)
	local caster = keys.caster
	local pid = caster:GetPlayerOwnerID()
	local hero = PlayerResource:GetSelectedHeroEntity(pid)

	--hero:SwapAbilities("jeanne_saint", "jeanne_identity_discernment", true, true) 
	-- Set master 1's mana 
	hero.bIsQGGImproved = true
	
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function nursery_rhyme_attribute_improve_queens_glass_game:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: nursery_rhyme_ability / OnImproveQGGAcquired
	OnImproveQGGAcquired({ caster = caster, ability = self, target = caster })
end
