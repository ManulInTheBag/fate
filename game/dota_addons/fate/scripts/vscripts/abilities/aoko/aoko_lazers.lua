aoko_lazers = class({})

function aoko_lazers:OnSpellStart()
	local caster = self:GetCaster()
	local range = self:GetSpecialValueFor("range")
	local forward = caster:GetForwardVector()
	local right = caster:GetRightVector()

	local height_att = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_beamu")).z - caster:GetAbsOrigin().z
	local part9 = caster:GetAbsOrigin() + Vector(0, 0, height_att) + forward*100

	local initpos = part9 + Vector(0, 0, 150)

	for i = 1,12 do
		Timers:CreateTimer(FrameTime()*i, function()
			local pos = self:CalculateCirclePositions(part9, 75, right, i, 6) -- RotatePosition(part9, QAngle(30*i, 30*i, 30*i), initpos)

			self:FireBeamFromThere(pos, forward)
		end)
	end
end

function aoko_lazers:CalculateCirclePositions(mid, radius, right, num, count)
	local angle = 8/count

	angle = angle*num

	local position = mid + radius*(math.cos(angle)*right + math.sin(angle)*Vector(0, 0, 1))
	return position
end

function aoko_lazers:FireBeamFromThere(pos, forward)
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local range = self:GetSpecialValueFor("range")

	local dummy = CreateUnitByName("aoko_sphere", pos, false, nil, nil, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive_fly_pathing"):SetLevel(1)

	dummy:SetForwardVector(forward)

	Timers:CreateTimer(1, function()
		dummy:RemoveSelf()
	end)

	local part9 = pos
	local part1 = pos + range*forward

	EmitSoundOn("edmon_short_beam", caster)
	local particle = ParticleManager:CreateParticle("particles/aoko/aoko_beam_laser_rapid.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
	ParticleManager:SetParticleControl(particle, 0, part9)
	ParticleManager:SetParticleControl(particle, 1, part1)
	ParticleManager:SetParticleControl(particle, 9, part9)
	--ParticleManager:SetParticleControlEnt(particle,	1, args.target,	PATTACH_POINT, "attach_hitloc", args.target:GetOrigin(), true)
	--ParticleManager:SetParticleControlEnt(particle,	9, self.parent,	PATTACH_POINT, "attach_attack"..self.seq, self.parent:GetOrigin(), true)
	ParticleManager:ReleaseParticleIndex(particle)

	local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        part9,
								        part1,
								        nil,
								        100,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										0
	   								)

	for _, enemy in pairs(enemies) do
		DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

		EmitSoundOn("edmon_beam_hit", enemy)
	end

	local spherecheck = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        part9,
								        part1,
								        nil,
								        100,
										DOTA_UNIT_TARGET_TEAM_FRIENDLY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_INVULNERABLE
	   								)

	for _, check in pairs(spherecheck) do
		if check:HasModifier("modifier_aoko_sphere_dummy") then
			check:FindModifierByName("modifier_aoko_sphere_dummy"):Explode()
		end
	end
end