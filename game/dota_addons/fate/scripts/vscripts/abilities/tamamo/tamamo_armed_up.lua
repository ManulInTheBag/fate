-- tamamo_armed_up — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/tamamo/tamamo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

tamamo_armed_up = class({})

-- Логика перенесена из scripts/vscripts/tamamo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnArmedUpStart

OnArmedUpStart = function(keys)
	local caster = keys.caster
	local a1 = caster:FindAbilityByName("tamamo_soul_stream") -- Soulstream 
	local a2 = caster:FindAbilityByName("tamamo_subterranean_grasp") -- Subterranean Grasp
	local a3 = nil
	if caster.bIsShackleAvailable ~= true then
		a3 = caster:FindAbilityByName("tamamo_mantra") -- Mantra
	else
		a3 = caster:FindAbilityByName("tamamo_mystic_shackle")
	end
	local a4 = caster:FindAbilityByName("tamamo_castration_fist") -- Armed Up
	local a5 = caster:FindAbilityByName("tamamo_armed_up") -- fate_empty1
	local a6 = caster:FindAbilityByName("tamamo_amaterasu") -- Amaterasu

	caster:SwapAbilities("tamamo_fiery_heaven", a1:GetName(), true, false) 
	caster:SwapAbilities("tamamo_frigid_heaven", a2:GetName(), true, false) 
	caster:SwapAbilities("tamamo_gust_heaven", a3:GetName(), true, false) 
	caster:SwapAbilities("tamamo_void_heaven", a4:GetName(), true, false) 
	caster:SwapAbilities("tamamo_close_spellbook", a5:GetName(), true,false) 
	--caster:SwapAbilities("fate_empty2", a6:GetName(), true, false) 
end


function tamamo_armed_up:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: tamamo_ability / OnArmedUpStart
	OnArmedUpStart({ caster = caster, ability = self, target = caster })
end
