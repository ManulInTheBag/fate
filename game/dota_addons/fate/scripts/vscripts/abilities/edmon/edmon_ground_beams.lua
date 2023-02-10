edmon_ground_beams = class({})

function edmon_ground_beams:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function edmon_ground_beams:OnAbilityPhaseStart()
	self:GetCaster():EmitSound("edmon_e")
	return true
end

function edmon_ground_beams:OnAbilityPhaseInterrupted()
	self:GetCaster():StopSound("edmon_e")
end

function edmon_ground_beams:OnSpellStart()
	local caster = self:GetCaster()

	local origin = caster:GetAbsOrigin()
	local direction = caster:GetForwardVector()

	for i = 1,4 do
		local ori = GetGroundPosition(RotatePosition(origin, QAngle(0, 360/4*i, 0), origin + direction*150), caster)
		self:CreateWhiteBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
		self:CreateBlackBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
		Timers:CreateTimer(0.2, function()
			self:CreateWhiteBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
			self:CreateBlackBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
		end)
	end
	for i = 1,8 do
		local ori = GetGroundPosition(RotatePosition(origin, QAngle(0, 360/8*i, 0), origin + direction*300), caster)
		self:CreateWhiteBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
		self:CreateBlackBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
		Timers:CreateTimer(0.2, function()
			self:CreateWhiteBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
			self:CreateBlackBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
		end)
	end
	self:Impact(origin)
	Timers:CreateTimer(0.2, function()
		self:Impact(origin)
	end)
	--[[for i = 1,15 do
		local ori = RotatePosition(origin, QAngle(0, 360/5*i, 0), origin + direction*450)
		self:CreateWhiteBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
		self:CreateBlackBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
		Timers:CreateTimer(0.2, function()
			self:CreateWhiteBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
			self:CreateBlackBeam(ori + RandomVector(750) + Vector(0, 0, 3000), ori)
		end)
	end]]

	--[[local forwardpos = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*450, caster) + Vector(0, 0, 50)
	local forwardpos2 = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*225, caster) + Vector(0, 0, 50)
	local backpos = GetGroundPosition(caster:GetAbsOrigin() - caster:GetForwardVector()*150, caster) + Vector(0, 0, 50)
	local backpos2 = GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0, 0, 50)

	local posforwh = {}
	local posforbl = {}
	for i = 1,2 do
		posforwh[i] = forwardpos + RandomVector(750) + Vector(0, 0, 3000)
	end
	for i = 1,2 do
		posforbl[i] = forwardpos + RandomVector(750) + Vector(0, 0, 3000)
	end

	for i = 1, 20 do
		local k = 0
		local j = 0
		if i < 11 then
			k = 0
			j = i
		else
			k = 1
			j = i-10
		end
		Timers:CreateTimer(FrameTime()*5*k, function()
			pos1 = backpos2 + RandomVector(50*j)
			pos2 = backpos2 + RandomVector(50*j)
			self:CreateWhiteBeam(pos1 + RandomVector(750) + Vector(0, 0, 3000), pos1)
			self:CreateBlackBeam(pos2 + RandomVector(750) + Vector(0, 0, 3000), pos2)
		end)
	end]]
end

function edmon_ground_beams:CreateWhiteBeam(part1, part9)
	local caster = self:GetCaster()
	EmitSoundOnLocationWithCaster(part9, "edmon_short_beam", caster)

	--self:Impact(part9)

	local particle = ParticleManager:CreateParticle("particles/edmon/edmon_beam_laser_ground_white.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 1, part1)
	ParticleManager:SetParticleControl(particle, 9, part9)
end
function edmon_ground_beams:CreateBlackBeam(part1, part9)
	local caster = self:GetCaster()
	EmitSoundOnLocationWithCaster(part9, "edmon_short_beam", caster)

	--self:Impact(part9)

	local particle = ParticleManager:CreateParticle("particles/edmon/edmon_beam_laser_ground.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 1, part1)
	ParticleManager:SetParticleControl(particle, 9, part9)
end

function edmon_ground_beams:Impact(part1)
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local enemies = FindUnitsInRadius(caster:GetTeam(), part1, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	for _, enemy in pairs(enemies) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
	    	EmitSoundOn("edmon_beam_hit", enemy)
	    	enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
	    	--[[local knockback = { should_stun = 1,
		            knockback_duration = FrameTime(),
		            duration = FrameTime(),
		            knockback_distance = 15,
		            knockback_height = 0,
		            center_x = caster:GetAbsOrigin().x,
		            center_y = caster:GetAbsOrigin().y,
		            center_z = caster:GetAbsOrigin().z }

		    enemy:RemoveModifierByName("modifier_knockback")
	        enemy:AddNewModifier(caster, self, "modifier_knockback", knockback)]]

	        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	    end
	end
end