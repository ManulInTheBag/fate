-- caster_5th_ancient_magic — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_ancient_magic = class({})

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnAncientStart, AncientLevelUp

OnAncientStart = function(keys)
	local caster = keys.caster
	local a1 = caster:GetAbilityByIndex(0)
	local a2 = caster:GetAbilityByIndex(1)
	local a3 = caster:GetAbilityByIndex(2)
	local a4 = caster:GetAbilityByIndex(3)
	local a5 = caster:GetAbilityByIndex(4)
	local a6 = caster:GetAbilityByIndex(5)
	caster:SwapAbilities("caster_5th_wall_of_flame", a1:GetName(), true, false) 
	caster:SwapAbilities("caster_5th_silence", a2:GetName(), true, false) 
	caster:SwapAbilities("caster_5th_divine_words", a3:GetName(), true, false)
	caster:SwapAbilities("medea_blink", a4:GetName(), true, false) 
	caster:SwapAbilities("caster_5th_close_spellbook", a5:GetName(), true, false) 
	caster:SwapAbilities("caster_5th_sacrifice", a6:GetName(), true, false) 
end

AncientLevelUp = function(keys)
	local caster = keys.caster
	local a1 = caster:FindAbilityByName("caster_5th_wall_of_flame")
	a1:SetLevel(keys.ability:GetLevel())
	a1:EndCooldown()
	local a2 = caster:FindAbilityByName("caster_5th_silence")
	a2:SetLevel(keys.ability:GetLevel())
	a2:EndCooldown()
	local a3 = caster:FindAbilityByName("caster_5th_divine_words")
	a3:SetLevel(keys.ability:GetLevel())
	a3:EndCooldown()
	local a4 = caster:FindAbilityByName("medea_blink")
	a4:SetLevel(keys.ability:GetLevel())
	a4:EndCooldown()
	local a5 = caster:FindAbilityByName("caster_5th_sacrifice")
	a5:SetLevel(keys.ability:GetLevel())
	a5:EndCooldown()
end


function caster_5th_ancient_magic:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnAncientStart
	OnAncientStart({ caster = caster, ability = self, target = caster })
end

function caster_5th_ancient_magic:OnUpgrade()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / AncientLevelUp
	AncientLevelUp({ caster = caster, ability = self, target = caster })
end

function caster_5th_ancient_magic:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		-- DD RunScript: caster_ability / OnAncientStart
		OnAncientStart({ caster = caster, ability = self })
	end
end
