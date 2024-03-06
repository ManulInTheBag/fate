aoko_jumpback = class({})

LinkLuaModifier("modifier_aoko_jumpback", "abilities/aoko/aoko_jumpback", LUA_MODIFIER_MOTION_NONE)

function aoko_jumpback:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=0.80, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
    return true
end

function aoko_jumpback:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function aoko_jumpback:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	local origin = caster:GetAbsOrigin()
	local direction = (caster:GetAbsOrigin() - target):Normalized()
	direction.z = 0
	caster:SetForwardVector(-direction)
	local range = self:GetSpecialValueFor("range")

	--[[if (Vector(target.x, target.y, 0) == Vector(origin.x, origin.y, 0)) then
		direction = caster:GetForwardVector()
	end]]

	caster:AddNewModifier(caster, self, "modifier_aoko_jumpback", {duration = 0.25})
	Timers:CreateTimer(0, function()
		if not caster:IsAlive() then
			return
		end
		if not caster:HasModifier("modifier_aoko_jumpback") then
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
			return
		end

		local origin_t = caster:GetAbsOrigin()
		--caster:SetForwardVector(direction)
		caster:SetAbsOrigin(GetGroundPosition(origin_t + direction*range/0.35*0.033, caster))
		return 0.033
	end)

	local counter = 0
	local ori = caster:GetAbsOrigin()
	local forward = caster:GetForwardVector()
	local right = caster:GetRightVector()

	Timers:CreateTimer(0.0, function()
		if counter >= 10 then return end
		self:FireGroundBeam(GetGroundPosition(ori + forward*(counter*75), caster), forward, right)
		counter = counter + 1
		return 0.033
	end)
end

function aoko_jumpback:FireGroundBeam(position, forward, right)
	local caster = self:GetCaster()

	for i = 1, 3 do
		local pos = position + right*75*(i-2)
		local part1 = pos + forward*200 + Vector(0, 0, 400)
		local part9 = pos

		EmitSoundOn("edmon_short_beam", caster)
		local particle = ParticleManager:CreateParticle("particles/aoko/aoko_beam_laser_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 0, part9)
		ParticleManager:SetParticleControl(particle, 1, part1)
		ParticleManager:SetParticleControl(particle, 9, part9)
		--ParticleManager:SetParticleControlEnt(particle,	1, args.target,	PATTACH_POINT, "attach_hitloc", args.target:GetOrigin(), true)
		--ParticleManager:SetParticleControlEnt(particle,	9, self.parent,	PATTACH_POINT, "attach_attack"..self.seq, self.parent:GetOrigin(), true)
		ParticleManager:ReleaseParticleIndex(particle)
	end

	local damage = self:GetSpecialValueFor("damage")
	local enemieshit = {}
	local enemies = FindUnitsInRadius(caster:GetTeam(), position + right*75, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	local enemies2 = FindUnitsInRadius(caster:GetTeam(), position, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	local enemies3 = FindUnitsInRadius(caster:GetTeam(), position - right*75, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	for _, enemy in pairs(enemies) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) and not enemieshit[enemy:entindex()] then
	    	enemieshit[enemy:entindex()] = true
	    	EmitSoundOn("edmon_beam_hit", enemy)
	    	enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})

	        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	    end
	end
	for _, enemy in pairs(enemies2) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) and not enemieshit[enemy:entindex()] then
	    	enemieshit[enemy:entindex()] = true
	    	EmitSoundOn("edmon_beam_hit", enemy)
	    	enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})

	        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	    end
	end
	for _, enemy in pairs(enemies3) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) and not enemieshit[enemy:entindex()] then
	    	enemieshit[enemy:entindex()] = true
	    	EmitSoundOn("edmon_beam_hit", enemy)
	    	enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})

	        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	    end
	end

	local spherecheck = FindUnitsInRadius(caster:GetTeam(), position + right*75, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
	local spherecheck2 = FindUnitsInRadius(caster:GetTeam(), position, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
	local spherecheck3 = FindUnitsInRadius(caster:GetTeam(), position - right*75, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)

	for _, check in pairs(spherecheck) do
		if check and not check:IsNull() and check:HasModifier("modifier_aoko_sphere_dummy") then
			check:FindModifierByName("modifier_aoko_sphere_dummy"):Explode()
		end
	end
	for _, check in pairs(spherecheck2) do
		if check and not check:IsNull() and check:HasModifier("modifier_aoko_sphere_dummy") then
			check:FindModifierByName("modifier_aoko_sphere_dummy"):Explode()
		end
	end
	for _, check in pairs(spherecheck3) do
		if check and not check:IsNull() and check:HasModifier("modifier_aoko_sphere_dummy") then
			check:FindModifierByName("modifier_aoko_sphere_dummy"):Explode()
		end
	end
end

modifier_aoko_jumpback = class({})

function modifier_aoko_jumpback:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_STUNNED] = true}
end

function modifier_aoko_jumpback:IsHidden() return true end