aoko_round_kick = class({})

function aoko_round_kick:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")

	local damage = self:GetSpecialValueFor("damage")

	StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})

	Timers:CreateTimer(0.1, function()
		local forw = Vector(0, 0, VectorToAngles(caster:GetForwardVector())[2])

		local slash_fx = ParticleManager:CreateParticle("particles/aoko/aoko_blade_fury_blue.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(slash_fx, 5, Vector(radius-20, 1, 1))
		ParticleManager:SetParticleControl(slash_fx, 10, forw + Vector(0, 0, -80))

		local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

		for _, enemy in pairs(enemies) do
		    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
		    	--[[EmitSoundOn("edmon_beam_hit", enemy)
		    	enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})]]

		        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		    end
		end
	end)
end