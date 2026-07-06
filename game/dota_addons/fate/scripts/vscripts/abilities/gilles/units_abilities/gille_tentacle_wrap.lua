gille_tentacle_wrap = class({})

LinkLuaModifier("modifier_tentacle_wrap", "abilities/gilles/units_abilities/gille_tentacle_wrap", LUA_MODIFIER_MOTION_NONE)

function gille_tentacle_wrap:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	caster:EmitSound("ZC.Tentacle2")
	-- как в DD: рут фиксированные 2.0с, root_duration из KV не использовался
	target:AddNewModifier(caster, self, "modifier_tentacle_wrap", {duration = 2.0})

	local fxCounter = 0
	Timers:CreateTimer(function()
		if fxCounter > 2 then return end
		local tentacleFx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_spell_ravage_hit_wrap.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControl(tentacleFx, 0, target:GetAbsOrigin() + Vector(0,0,100))
		ParticleManager:SetParticleControl(tentacleFx, 2, target:GetAbsOrigin() + Vector(0,0,100))
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( tentacleFx, false )
			ParticleManager:ReleaseParticleIndex( tentacleFx )
		end)
		fxCounter = fxCounter + 0.5
		return 0.5
	end)
end

modifier_tentacle_wrap = class({})

function modifier_tentacle_wrap:IsDebuff()
	return true
end

function modifier_tentacle_wrap:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end
