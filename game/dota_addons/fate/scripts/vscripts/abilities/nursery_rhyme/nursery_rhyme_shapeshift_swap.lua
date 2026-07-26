-- nursery_rhyme_shapeshift_swap — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nursery_rhyme/nursery_rhyme_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nursery_rhyme_shapeshift_swap = class({})

-- Логика перенесена из scripts/vscripts/nursery_rhyme_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnShapeShiftSwap

OnShapeShiftSwap = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local casterPos = caster:GetAbsOrigin()
	if caster.bIsSwapUsed then return end

	caster:SetAbsOrigin(caster.ShapeShiftIllusion:GetAbsOrigin())
	caster.ShapeShiftIllusion:SetAbsOrigin(casterPos)
	caster.bIsSwapUsed = true
	caster:MoveToPosition(caster.ShapeShiftDest)
	caster.ShapeShiftIllusion:Hold()
end


function nursery_rhyme_shapeshift_swap:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: nursery_rhyme_ability / OnShapeShiftSwap
	OnShapeShiftSwap({ caster = caster, ability = self, target = caster })
end
