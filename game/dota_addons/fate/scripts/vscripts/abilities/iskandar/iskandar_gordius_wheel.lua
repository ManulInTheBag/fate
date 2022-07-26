iskandar_gordius_wheel = class({})

LinkLuaModifier("modifier_gordius_wheel", "abilities/iskandar/modifiers/modifier_gordius_wheel", LUA_MODIFIER_MOTION_NONE)

function iskandar_gordius_wheel:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_gordius_wheel") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function iskandar_gordius_wheel:GetCustomCastError()
	return "Already Riding"
end

function iskandar_gordius_wheel:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_gordius_wheel", { Duration = 12 })

	caster:EmitSound("Hero_Magnataur.Skewer.Cast")
    caster:EmitSound("Hero_Zuus.GodsWrath")
    caster:EmitSound("Iskander_Wheel_" .. math.random(1,3))
	local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
	local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle2, 1, caster:GetAbsOrigin())
    local particle3 = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle3, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle3, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle3, 2, caster:GetAbsOrigin())
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
		ParticleManager:DestroyParticle( particle2, false )
		ParticleManager:ReleaseParticleIndex( particle2 )
		ParticleManager:DestroyParticle( particle3, false )
		ParticleManager:ReleaseParticleIndex( particle3 )
	end)
end