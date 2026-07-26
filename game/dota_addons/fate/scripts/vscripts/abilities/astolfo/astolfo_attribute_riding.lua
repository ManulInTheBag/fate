-- astolfo_attribute_riding — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_attribute_riding = class({})

function astolfo_attribute_riding:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnRidingAcquired
	OnRidingAcquired({ caster = caster, ability = self, target = caster })
end
