-----------------------------
--    Instinct    --
-----------------------------

artoria_instinct = class({})

LinkLuaModifier( "modifier_artoria_instinct", "abilities/artoria/modifiers/modifier_artoria_instinct", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_avalon_cd_checker", "abilities/artoria/modifiers/modifier_artoria_avalon_cd_checker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_ultimate_excalibur_window", "abilities/artoria/modifiers/modifier_artoria_ultimate_excalibur_window", LUA_MODIFIER_MOTION_NONE )

function artoria_instinct:GetIntrinsicModifierName()
	return "modifier_artoria_instinct"
end

function artoria_instinct:OnSpellStart()
	self:CheckCombo()
end

function artoria_instinct:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("artoria_excalibur"):IsCooldownReady() 
		and caster:FindAbilityByName("artoria_ultimate_excalibur"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_artoria_ultimate_excalibur_window", { Duration = 4 })
		end
	end
end