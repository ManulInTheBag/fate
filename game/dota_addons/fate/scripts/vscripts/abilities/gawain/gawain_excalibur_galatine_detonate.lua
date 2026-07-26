-- gawain_excalibur_galatine_detonate — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gawain/gawain_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gawain_excalibur_galatine_detonate = class({})

-- Логика перенесена из scripts/vscripts/gawain_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGalatineDetonate, GiveGawainGalatine

OnGalatineDetonate = function(keys)
	local caster = keys.caster
	caster.IsGalatineActive = false
	GiveGawainGalatine(caster)
	--[[local skillname = caster:GetAbilityByIndex(5):GetAbilityName() ]]


	--[[if skillname == "gawain_excalibur_galatine_detonate" then
		caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_detonate", true, false)
	end]]
end

GiveGawainGalatine = function(caster)
	local galatineSlot = caster:GetAbilityByIndex(5)

	caster.IsGalatineActive = false

	if galatineSlot:GetAbilityName() ~= "gawain_excalibur_galatine" then
		caster:SwapAbilities("gawain_excalibur_galatine", galatineSlot:GetAbilityName(), true, false)
	end
end


function gawain_excalibur_galatine_detonate:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: gawain_ability / OnGalatineDetonate
	OnGalatineDetonate({ caster = caster, ability = self, target = caster })
end
