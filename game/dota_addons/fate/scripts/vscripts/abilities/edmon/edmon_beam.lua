LinkLuaModifier("modifier_edmon_beam_tracker", "abilities/edmon/edmon_beam", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edmon_beam", "abilities/edmon/edmon_beam", LUA_MODIFIER_MOTION_NONE)

edmon_beam = class({})

function edmon_beam:OnAbilityPhaseStart()
	local seq = self:CheckSequence() + 1
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_edmon_beam_stacks")
	self.sound = 1
	if modifier then
		if modifier:GetStackCount() == 6 then
			self.sound = 2
		end
	end
	self:GetCaster():EmitSound("edmon_q"..self.sound..seq)
	return true
end

function edmon_beam:OnAbilityPhaseInterrupted()
	for i = 1,3 do
		self:GetCaster():StopSound("edmon_q"..self.sound..i)
	end
end

function edmon_beam:GetAOERadius()
	return self:GetSpecialValueFor("range")
end

function edmon_beam:GetManaCost()
	return self:CheckSequence() == 0 and 100 or 0 
end

function edmon_beam:GetBehavior()
	if (self:CheckSequence() ~= 2) then
		return DOTA_ABILITY_BEHAVIOR_POINT
	end
	return DOTA_ABILITY_BEHAVIOR_POINT
end

function edmon_beam:GetCastPoint()
	if (self:CheckSequence() ~= 2) then
		return 0.2
	end
	return 0.2
end
function edmon_beam:GetCastAnimation()
	if self:CheckSequence() == 0 then
		return ACT_DOTA_RAZE_1
	elseif self:CheckSequence() == 1 then
		return ACT_DOTA_RAZE_2
	end
	return ACT_DOTA_IDLE
end

function edmon_beam:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_edmon_beam_tracker") then
		local stack = caster:GetModifierStackCount("modifier_edmon_beam_tracker", caster)

		return stack
	else
		return 0
	end	
end

function edmon_beam:SequenceSkill()
	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_edmon_beam_tracker")

	if not modifier then
		caster:AddNewModifier(caster, ability, "modifier_edmon_beam_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_edmon_beam_tracker", ability, 1)
	else
		caster:AddNewModifier(caster, ability, "modifier_edmon_beam_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_edmon_beam_tracker", ability, modifier:GetStackCount() + 1)
	end
end

function edmon_beam:OnSpellStart()
	local caster = self:GetCaster()
	local range = self:GetSpecialValueFor("range")
	local seq = 0

	if (self:CheckSequence() == 0) then
		seq = 1
	elseif (self:CheckSequence() == 1) then
		seq = 2
	end

	if seq ~= 0 then
		local or1 = GetGroundPosition((caster:GetAbsOrigin() + caster:GetForwardVector()*range), caster)
		local or2 = caster:GetAbsOrigin()
		local or3 = caster:GetAbsOrigin()
		local height = or1.z - or2.z
		if height < 0 then
			height = 0
		end

		or1.z = 0
		or2.z = 0
		
		local compens = 0

		local att_or = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack"..seq))
		if seq == 1 then
			compens = 41
		elseif seq == 2 then
			compens = 80
		end
		local part1 = caster:GetAbsOrigin() + caster:GetForwardVector()*range + Vector(0, 0, height)
		local part9 = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack"..seq)) + caster:GetForwardVector()*25

		self:EndCooldown()
		self:SequenceSkill()

		self:MiniDarkBeam(part1, part9, false, false, false, "false")
	else
		caster:RemoveModifierByName("modifier_edmon_beam_tracker")
		seq = 2
		caster:FaceTowards(Vector(self:GetCursorPosition().x, self:GetCursorPosition().y, caster:GetAbsOrigin().z))
		local modifier = caster:FindModifierByName("modifier_edmon_beam_stacks")
		local or1 = GetGroundPosition((caster:GetAbsOrigin() + caster:GetForwardVector()*range), caster)
		local or2 = caster:GetAbsOrigin()
		local height = or1.z - or2.z
		if height < 0 then
			height = 0
		end
		local stacks = 0
		local activity = ACT_DOTA_RAZE_1
		if modifier then
			stacks = modifier:GetStackCount()
			caster:RemoveModifierByName("modifier_edmon_beam_stacks")
		end
		local compens = 0
		caster:AddNewModifier(caster, self, "modifier_edmon_beam", {duration = stacks*0.132+0.353})
		for i = 1, stacks + 1 do
			if (i ~= stacks + 1) then
				if seq == 2 then
					seq = 1
					compens = 41
				elseif seq == 1 then
					seq = 2
					compens = 80
				end
				local part1 = caster:GetAbsOrigin() + caster:GetForwardVector()*range + Vector(0, 0, height + 136)--caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack"..seq)) + caster:GetForwardVector()*(range - compens) + Vector(0, 0, height)
				local part9 = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack"..seq)) + caster:GetForwardVector()*25
				Timers:CreateTimer(0.132*(i-1), function()
					if seq == 2 then
						StartAnimation(caster, {duration=0.132, activity=ACT_DOTA_RAZE_2, rate=3.25})
					elseif seq == 1 then
						StartAnimation(caster, {duration=0.132, activity=ACT_DOTA_RAZE_1, rate=3.25})
					end
					Timers:CreateTimer(0.066, function()
						self:MiniDarkBeam(part1, part9, false, false, true, "false")
					end)
					Timers:CreateTimer(0.132, function()
						self:MiniDarkBeam(part1, part9, false, false, true, "false")
					end)
				end)
			else
				Timers:CreateTimer(0.132*(i-1), function()
					StartAnimation(caster, {duration=0.8, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.5})
					Timers:CreateTimer(0.353, function()
						local part1 = GetGroundPosition(caster:GetAbsOrigin() + self:GetSpecialValueFor("last_range")*caster:GetForwardVector(), caster) + Vector(0, 0, 130)
						local part9 = caster:GetAbsOrigin() + caster:GetForwardVector()*50 + Vector(0, 0, 130)
						if part1.z < part9.z then
							part1.z = part9.z
						end

						local damage = self:GetSpecialValueFor("last_damage")*self:GetSpecialValueFor("damage") + 2*caster:GetLevel()*self:GetSpecialValueFor("damage_per_level")
						EmitSoundOn("edmon_short_beam", caster)

						local particle = ParticleManager:CreateParticle("particles/edmon/edmon_beam_laser_big.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
						ParticleManager:SetParticleControl(particle, 1, part1)
						ParticleManager:SetParticleControl(particle, 9, part9)
						--ParticleManager:SetParticleControlEnt(particle,	1, args.target,	PATTACH_POINT, "attach_hitloc", args.target:GetOrigin(), true)
						--ParticleManager:SetParticleControlEnt(particle,	9, self.parent,	PATTACH_POINT, "attach_attack"..self.seq, self.parent:GetOrigin(), true)
						ParticleManager:ReleaseParticleIndex(particle)

						local enemies = FindUnitsInLine(
													        caster:GetTeamNumber(),
													        part1,
													        part9,
													        nil,
													        200,
															DOTA_UNIT_TARGET_TEAM_ENEMY,
															DOTA_UNIT_TARGET_ALL,
															0
					    								)

						for _, enemy in pairs(enemies) do
							if caster.FlamesAcquired then
								local modifier = caster:AddNewModifier(caster, caster:FindAbilityByName("edmon_mythologie"), "modifier_edmon_melee_stacks", {duration = 5})
								if modifier:GetStackCount() < 6 then
									modifier:IncrementStackCount()
								end
							end
							DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

							--self:PlayEffects2(enemy)

							EmitSoundOn("edmon_beam_hit_hard", enemy)
						end
					end)
				end)
			end
		end
	end
end

function edmon_beam:MiniDarkBeam(part1, part9, isAA, isMelee, isBeams, seq)
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage") + caster:GetLevel()*self:GetSpecialValueFor("damage_per_level")

	if isAA then
		damage = damage*0.5
	end
	if isBeams then
		damage = damage/4
	end

	if not isMelee then
		EmitSoundOn("edmon_short_beam", caster)
		local particle = ParticleManager:CreateParticle("particles/edmon/edmon_beam_laser.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 1, part1)
		ParticleManager:SetParticleControl(particle, 9, part9)
		--ParticleManager:SetParticleControlEnt(particle,	1, args.target,	PATTACH_POINT, "attach_hitloc", args.target:GetOrigin(), true)
		--ParticleManager:SetParticleControlEnt(particle,	9, self.parent,	PATTACH_POINT, "attach_attack"..self.seq, self.parent:GetOrigin(), true)
		ParticleManager:ReleaseParticleIndex(particle)

		local enemies = FindUnitsInLine(
									        caster:GetTeamNumber(),
									        part1,
									        part9,
									        nil,
									        75,
											DOTA_UNIT_TARGET_TEAM_ENEMY,
											DOTA_UNIT_TARGET_ALL,
											0
	    								)

		for _, enemy in pairs(enemies) do
			if not isBeams then
				if caster.FlamesAcquired then
					local modifier = caster:AddNewModifier(caster, caster:FindAbilityByName("edmon_mythologie"), "modifier_edmon_melee_stacks", {duration = 5})
					if modifier:GetStackCount() < 6 then
						modifier:IncrementStackCount()
					end
				end
			end
			DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

			--self:PlayEffects2(enemy)

			EmitSoundOn("edmon_beam_hit", enemy)
		end
	else
		if part9 == "fast" then
			EmitSoundOn("edmon_fast_melee", caster)
			local param1 = 0
			local param2 = 0
			if seq == 1 then
				param1 = 0
				param2 = 150
			else
				param1 = 180
				param2 = 30
			end
			local particle2 = ParticleManager:CreateParticle("particles/edmon/edmon_fast_trail.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*100)
			ParticleManager:SetParticleControl(particle2, 5, Vector(200, 0, 140))
			ParticleManager:SetParticleControl(particle2, 10, Vector(0, param1, param2))
			Timers:CreateTimer(1, function()
				ParticleManager:DestroyParticle(particle2, false)
				ParticleManager:ReleaseParticleIndex(particle2)
			end)
		else
			EmitSoundOn("edmon_common_melee", caster)
		end
		if not part1:IsMagicImmune() then
			DoDamage(caster, part1, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
		local firstImpactIndex = ParticleManager:CreateParticle( "particles/edmon/edmon_hit_indicator.vpcf", PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControlEnt(firstImpactIndex,	3, part1, PATTACH_POINT, "attach_hitloc", part1:GetOrigin(), true)
	    ParticleManager:SetParticleControl(firstImpactIndex, 1, Vector(0,0,0))
	    ParticleManager:SetParticleControl(firstImpactIndex, 2, Vector(0.4,0,0))
	end
end

modifier_edmon_beam_tracker = class({})

function modifier_edmon_beam_tracker:OnCreated()
	if IsServer() then
	end
end 

function modifier_edmon_beam_tracker:OnDestroy()
	if IsServer() then
		local ability = self:GetAbility()
		ability:EndCooldown()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1) - ability:GetSpecialValueFor("window_duration"))
	end
end

function modifier_edmon_beam_tracker:IsPurgable()
	return false
end

function modifier_edmon_beam_tracker:IsHidden()
	return true
end

function modifier_edmon_beam_tracker:IsDebuff()
	return false
end

function modifier_edmon_beam_tracker:RemoveOnDeath()
	return true
end

function modifier_edmon_beam_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_edmon_beam = class({})

function modifier_edmon_beam:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true}
end

function modifier_edmon_beam:IsHidden() return true end