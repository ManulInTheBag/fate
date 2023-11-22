lu_bu_restless_soul = class({})

LinkLuaModifier( "modifier_lu_bu_restless_soul", "abilities/lu_bu/modifiers/modifier_lu_bu_restless_soul", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_sky_piercer_window", "abilities/lu_bu/modifiers/modifier_lu_bu_sky_piercer_window", LUA_MODIFIER_MOTION_NONE )

function lu_bu_restless_soul:OnSpellStart()
	local caster = self:GetCaster()
	local hp_heal = self:GetSpecialValueFor("active_heal")
	
	caster:Heal(hp_heal, caster)
	
	self:CheckCombo()
end

function lu_bu_restless_soul:CheckCombo()
	local caster = self:GetCaster()
	
	local blastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_death_coil_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( blastFx, 1, caster:GetAbsOrigin())

    Timers:CreateTimer( 2.0, function()
        ParticleManager:DestroyParticle(blastFx)
        ParticleManager:ReleaseParticleIndex( blastFx )
    end)

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 and not caster:HasModifier("modifier_relentless_assault_blocker_combo") then
		if caster:FindAbilityByName("lu_bu_god_force"):IsCooldownReady() 
		and caster:FindAbilityByName("lu_bu_sky_piercer"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_lu_bu_sky_piercer_window", { Duration = 4 })
		end
	end
end

function lu_bu_restless_soul:GetIntrinsicModifierName()
	return "modifier_lu_bu_restless_soul"
end