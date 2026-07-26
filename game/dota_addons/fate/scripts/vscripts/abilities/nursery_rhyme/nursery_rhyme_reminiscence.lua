-- nursery_rhyme_reminiscence — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nursery_rhyme/nursery_rhyme_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nursery_rhyme_reminiscence = class({})

-- Логика перенесена из scripts/vscripts/nursery_rhyme_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnReminiscenceStart

OnReminiscenceStart = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	caster.NamelessTarget:RemoveModifierByName("modifier_nameless_forest")
end


function nursery_rhyme_reminiscence:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: nursery_rhyme_ability / OnReminiscenceStart
	OnReminiscenceStart({ caster = caster, ability = self, target = caster })
end
