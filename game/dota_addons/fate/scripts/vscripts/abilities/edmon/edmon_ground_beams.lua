edmon_ground_beams = class({})

function edmon_ground_beams:OnSpellStart()
	local caster = self:GetCaster()

	local forwardpos = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*450, caster) + Vector(0, 0, 50)
	local forwardpos2 = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*225, caster) + Vector(0, 0, 50)
	local backpos = GetGroundPosition(caster:GetAbsOrigin() - caster:GetForwardVector()*150, caster) + Vector(0, 0, 50)
	local backpos2 = GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0, 0, 50)

	local posforwh = {}
	local posforbl = {}
	local posforwh2 = {}
	local posforbl2 = {}
	local posbackwh = {}
	local posbackbl = {}
	local posbackwh2 = {}
	local posbackbl2 = {}
	for i = 1,2 do
		posforwh[i] = forwardpos + RandomVector(750) + Vector(0, 0, 3000)
	end
	local posforbl = {}
	for i = 1,2 do
		posforbl[i] = forwardpos + RandomVector(750) + Vector(0, 0, 3000)
	end
	for i = 1,2 do
		posforwh2[i] = forwardpos2 + RandomVector(750) + Vector(0, 0, 3000)
	end
	local posforbl2 = {}
	for i = 1,2 do
		posforbl2[i] = forwardpos2 + RandomVector(750) + Vector(0, 0, 3000)
	end
	local posbackwh = {}
	for i = 1,2 do
		posbackwh[i] = backpos + RandomVector(750) + Vector(0, 0, 3000)
	end
	local posbackbk = {}
	for i = 1,2 do
		posbackbl[i] = backpos + RandomVector(750) + Vector(0, 0, 3000)
	end
	for i = 1,2 do
		posbackwh2[i] = backpos2 + RandomVector(750) + Vector(0, 0, 3000)
	end
	local posbackbk = {}
	for i = 1,2 do
		posbackbl2[i] = backpos2 + RandomVector(750) + Vector(0, 0, 3000)
	end

	--[[for i = 1, 2 do
		Timers:CreateTimer(FrameTime()*i, function() 
			self:CreateWhiteBeam(posforwh[i], forwardpos + RandomVector(30))
		end)
		Timers:CreateTimer(FrameTime()*2*i, function()
			self:CreateBlackBeam(posbackbl[i], backpos + RandomVector(30))
		end)
		Timers:CreateTimer(FrameTime()*3*i, function()
			self:CreateWhiteBeam(posbackwh[i], backpos + RandomVector(30))
		end)
		Timers:CreateTimer(FrameTime()*4*i, function()
			self:CreateBlackBeam(posforbl2[i], forwardpos2 + RandomVector(30))
		end)
		Timers:CreateTimer(FrameTime()*5*i, function()
			self:CreateBlackBeam(posforbl[i], forwardpos + RandomVector(30))
		end)
		Timers:CreateTimer(FrameTime()*6*i, function()
			self:CreateWhiteBeam(posforwh2[i], forwardpos2 + RandomVector(30))
		end)
		Timers:CreateTimer(FrameTime()*7*i, function()
			self:CreateBlackBeam(posbackbl2[i], backpos2 + RandomVector(30))
		end)
		Timers:CreateTimer(FrameTime()*8*i, function()
			self:CreateWhiteBeam(posbackwh2[i], backpos2 + RandomVector(30))
		end)
	end]]

	for i = 1, 20 do
		Timers:CreateTimer(FrameTime()*i, function()
			pos1 = backpos2 + RandomVector(25*i)
			pos2 = backpos2 + RandomVector(25*i)
			self:CreateWhiteBeam(pos1 + RandomVector(750) + Vector(0, 0, 3000), pos1)
			self:CreateBlackBeam(pos2 + RandomVector(750) + Vector(0, 0, 3000), pos2)
		end)
	end
end

function edmon_ground_beams:CreateWhiteBeam(part1, part9)
	local caster = self:GetCaster()
	EmitSoundOnLocationWithCaster(part9, "edmon_short_beam", caster)

	self:Impact(part9)

	local particle = ParticleManager:CreateParticle("particles/edmon/edmon_beam_laser_ground_white.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 1, part1)
	ParticleManager:SetParticleControl(particle, 9, part9)
end
function edmon_ground_beams:CreateBlackBeam(part1, part9)
	local caster = self:GetCaster()
	EmitSoundOnLocationWithCaster(part9, "edmon_short_beam", caster)

	self:Impact(part9)

	local particle = ParticleManager:CreateParticle("particles/edmon/edmon_beam_laser_ground.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 1, part1)
	ParticleManager:SetParticleControl(particle, 9, part9)
end

function edmon_ground_beams:Impact(part1)
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")*2
	local enemies = FindUnitsInRadius(caster:GetTeam(), part1, nil, 175, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	for _, enemy in pairs(enemies) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
	    	EmitSoundOn("edmon_beam_hit", enemy)
	    	enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})
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