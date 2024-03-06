aoko_beam = class({})

function aoko_beam:OnSpellStart()
	local caster = self:GetCaster()
	local target_point = self:GetCursorPosition()
	local range = self:GetSpecialValueFor("range")
	local damage = self:GetSpecialValueFor("damage")

	local or1 = GetGroundPosition((caster:GetAbsOrigin() + caster:GetForwardVector()*range), caster)
	local or2 = caster:GetAbsOrigin()

	local height_att = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_beamu")).z - caster:GetAbsOrigin().z

	local height = or1.z - or2.z + height_att

	local part1 = caster:GetAbsOrigin() + caster:GetForwardVector()*range + Vector(0, 0, height)
	local part9 = caster:GetAbsOrigin() + Vector(0, 0, height_att) + caster:GetForwardVector()*100

	EmitSoundOn("edmon_short_beam", caster)
	local particle = ParticleManager:CreateParticle("particles/aoko/aoko_beam_laser_simple.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, part9)
	ParticleManager:SetParticleControl(particle, 1, part1)
	ParticleManager:SetParticleControl(particle, 9, part9)
	--ParticleManager:SetParticleControlEnt(particle,	1, args.target,	PATTACH_POINT, "attach_hitloc", args.target:GetOrigin(), true)
	--ParticleManager:SetParticleControlEnt(particle,	9, self.parent,	PATTACH_POINT, "attach_attack"..self.seq, self.parent:GetOrigin(), true)
	ParticleManager:ReleaseParticleIndex(particle)

	local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        part1,
								        caster:GetAbsOrigin(),
								        nil,
								        75,
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
								        part1,
								        caster:GetAbsOrigin(),
								        nil,
								        75,
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