-----------------------------
--    Avalon    --
-----------------------------

artoria_avalon = class({})

LinkLuaModifier( "modifier_artoria_avalon", "abilities/artoria/modifiers/modifier_artoria_avalon", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_avalon_immunity", "abilities/artoria/modifiers/modifier_artoria_avalon_immunity", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_avalon_heal", "abilities/artoria/modifiers/modifier_artoria_avalon_heal", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_avalon_cd_checker", "abilities/artoria/modifiers/modifier_artoria_avalon_cd_checker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_ultimate_excalibur_window", "abilities/artoria/modifiers/modifier_artoria_ultimate_excalibur_window", LUA_MODIFIER_MOTION_NONE )


function artoria_avalon:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier(caster, self, "modifier_artoria_avalon", { Duration = self:GetSpecialValueFor("duration")})
	
	--caster:AddNewModifier(caster, self, "modifier_artoria_avalon_immunity", { Duration = self:GetSpecialValueFor("duration")})
	
	if caster:HasModifier("modifier_artoria_avalon_attribute") then
		caster:AddNewModifier(caster, self, "modifier_artoria_avalon_heal", { Duration = self:GetSpecialValueFor("duration")})
	end
	
	caster:EmitSound("Hero_Omniknight.GuardianAngel.Cast")
	EmitGlobalSound("Saber.Avalon")
	EmitGlobalSound("Saber.Avalon_Shout")
	
	self:CheckCombo()
end

function artoria_avalon:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("artoria_excalibur"):IsCooldownReady() 
		and caster:FindAbilityByName("artoria_ultimate_excalibur"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_artoria_ultimate_excalibur_window", { Duration = 4 })
		end
	end
end