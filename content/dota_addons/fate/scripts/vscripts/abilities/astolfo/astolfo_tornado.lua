LinkLuaModifier("modifier_astolfo_tornado", "abilities/astolfo/astolfo_tornado", LUA_MODIFIER_MOTION_NONE)

astolfo_tornado = class({})

function astolfo_tornado:OnSpellStart()
	local target = self:GetCursorPosition()
	local caster = self:GetCaster()
	local time_counter = 0.003
	local damage = self:GetSpecialValueFor("air_damage")
	local tick_damage = self:GetSpecialValueFor("damage_per_second")*FrameTime()

	Timers:CreateTimer(0.5, function()
		caster.tornado_particle = ParticleManager:CreateParticle("particles/astolfo/invoker_tornado.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(caster.tornado_particle, 0, target)
	end)

	Timers:CreateTimer(0.5, function()
		time_counter = time_counter + FrameTime()
		if time_counter > self:GetSpecialValueFor("duration") then
			local targets = FindUnitsInRadius(caster:GetTeam(), target, nil, self:GetSpecialValueFor("airborne_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(targets) do
				ApplyAirborne(caster, v, self:GetSpecialValueFor("fly_duration"))
				DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			end
			ParticleManager:DestroyParticle(caster.tornado_particle, false)
			ParticleManager:ReleaseParticleIndex(caster.tornado_particle)
			return
		end
		local targets = FindUnitsInRadius(caster:GetTeam(), target, nil, self:GetSpecialValueFor("pull_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			local pos = v:GetAbsOrigin()
			local next_pos = GetGroundPosition(RotatePosition(target, QAngle(0,0.7,0), pos), v)
			local distance = (v:GetAbsOrigin() - target):Length2D()
			if distance > 20 then
				next_pos = GetGroundPosition((next_pos + (target - next_pos):Normalized() * 12), v)
			end
			v:SetAbsOrigin(next_pos)
			DoDamage(caster, v, tick_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
		return FrameTime()
	end)
end