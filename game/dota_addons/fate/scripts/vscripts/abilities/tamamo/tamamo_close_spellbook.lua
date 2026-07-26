-- tamamo_close_spellbook — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/tamamo/tamamo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

tamamo_close_spellbook = class({})

-- Логика перенесена из scripts/vscripts/tamamo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnCharmListClosed, CloseCharmList

OnCharmListClosed = function(keys)
	local caster = keys.caster
	local armedUp = caster:FindAbilityByName("tamamo_armed_up")
	armedUp:EndCooldown() 

	CloseCharmList(keys)
end

CloseCharmList = function(keys)
	local caster = keys.caster

	local a1 = caster:FindAbilityByName("tamamo_fiery_heaven") -- Soulstream 
	local a2 = caster:FindAbilityByName("tamamo_frigid_heaven") -- Subterranean Grasp
	local a3 = caster:FindAbilityByName("tamamo_gust_heaven") -- Mantra
	local a4 = caster:FindAbilityByName("tamamo_void_heaven") -- Armed Up
	local a5 = caster:FindAbilityByName("tamamo_close_spellbook") -- fate_empty1
	local a6 = caster:FindAbilityByName("fate_empty2") -- Amaterasu


	caster:SwapAbilities("tamamo_soul_stream", a1:GetName(), true, false) 
	caster:SwapAbilities("tamamo_subterranean_grasp", a2:GetName(), true, false) 
	if caster.bIsShackleAvailable then
		caster:SwapAbilities("tamamo_mystic_shackle", a3:GetName(), true, false) 
	else
		caster:SwapAbilities("tamamo_mantra", a3:GetName(), true, false) 
	end
	caster:SwapAbilities("tamamo_castration_fist", a4:GetName(), true, false) 
	caster:SwapAbilities("tamamo_armed_up", a5:GetName(), true,false) 
	--caster:SwapAbilities("tamamo_amaterasu", a6:GetName(), true, false) 
end


function tamamo_close_spellbook:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: tamamo_ability / OnCharmListClosed
	OnCharmListClosed({ caster = caster, ability = self, target = caster })
end
