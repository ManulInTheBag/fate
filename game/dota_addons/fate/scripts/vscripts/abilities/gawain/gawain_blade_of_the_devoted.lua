gawain_blade_of_the_devoted = class({})

LinkLuaModifier("modifier_blade_devoted_self", "abilities/gawain/modifiers/modifier_blade_devoted_self", LUA_MODIFIER_MOTION_NONE)

function gawain_blade_of_the_devoted:GetAbilityDamageType()
    return DAMAGE_TYPE_MAGICAL
end

function gawain_blade_of_the_devoted:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self

	caster:EmitSound("Hero_EmberSpirit.FireRemnant.Cast")
	local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( lightFx1, 0, caster:GetAbsOrigin())
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( lightFx1, false )
		ParticleManager:ReleaseParticleIndex( lightFx1 )
	end)	

	caster:AddNewModifier(caster, caster, "modifier_blade_devoted_self", { Duration = self:GetSpecialValueFor("duration"),
																		 MovespeedBonus = self:GetSpecialValueFor("movespeed_bonus"),
																		 StunDuration = self:GetSpecialValueFor("stun_duration"),
																		 Damage = self:GetSpecialValueFor("damage"),
																		 SubDamage = self:GetSpecialValueFor("sub_damage")
	})	
end