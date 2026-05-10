LinkLuaModifier("modifier_aoko_lazers", "abilities/aoko/aoko_lazers", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

aoko_lazers = class({})

function aoko_lazers:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("aoko_short_beam"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("aoko_short_beam"):SetLevel(self:GetLevel())
    end
end

function aoko_lazers:GetManaCost()
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("aoko_circuits")

	local stacks = ability:GetStacks()

	local base_manacost = self:GetSpecialValueFor("mana_cost")
	local increment = ability:GetSpecialValueFor("manacost_increase_per_stack")

	local result = math.min(base_manacost*(1 + stacks*increment/100), caster:GetMaxMana())

	return result
end

function aoko_lazers:OnSpellStart()
	local caster = self:GetCaster()

	caster:EmitSound("aoko_lazers_"..math.random(1, 2))

	if false then
		local dummy = CreateUnitByName("aoko_sphere",  caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
		dummy:FindAbilityByName("dummy_unit_passive_fly_pathing"):SetLevel(1)

		dummy:SetForwardVector(caster:GetForwardVector())

		dummy:AddNewModifier(caster, self, "modifier_aoko_lazers", {duration = self:GetChannelTime()})

		Timers:CreateTimer(self:GetChannelTime(), function()
			dummy:RemoveSelf()
		end)

		return
	end

	caster:AddNewModifier(caster, self, "modifier_aoko_lazers", {duration = self:GetChannelTime()})
	
	--[[local range = self:GetSpecialValueFor("range")
	local forward = caster:GetForwardVector()
	local right = caster:GetRightVector()

	local height_att = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_beamu")).z - caster:GetAbsOrigin().z
	print(height_att)
	local part9 = caster:GetAbsOrigin() + Vector(0, 0, height_att) + forward*100

	for i = 1,12 do
		Timers:CreateTimer(FrameTime()*i*2, function()
			local pos = self:CalculateCirclePositions(part9, 75, right, i, 6)

			self:FireBeamFromThere(pos, forward)
		end)
	end]]
end

function aoko_lazers:OnChannelFinish()
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_aoko_lazers")
end

function aoko_lazers:CalculateCirclePositions(mid, radius, right, num, count)
	local angle = 8/count

	angle = angle*num

	local position = mid + radius*(math.cos(angle)*right + math.sin(angle)*Vector(0, 0, 1))
	return position
end

--[[function aoko_lazers:FireBeamFromThere(pos, forward)
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
end]]

modifier_aoko_lazers = class({})

function modifier_aoko_lazers:IsHidden() return true end
function modifier_aoko_lazers:IsDebuff() return false end

function modifier_aoko_lazers:OnCreated(hTable)
	if IsServer() then
		self.parent  = self:GetParent()
		self.ability = self:GetAbility()

		self.range = self.ability:GetSpecialValueFor("range")
		self.forward = self.parent:GetForwardVector()
		self.right = self.parent:GetRightVector()

		self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
		self.stack_gain = self.ability:GetSpecialValueFor("stack_gain")

		self.height_att = 112 --caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_beamu")).z - caster:GetAbsOrigin().z
		self.part9 = self.parent:GetAbsOrigin() + Vector(0, 0, self.height_att) + self.forward*100

		self.counter = 0

		self:StartIntervalThink(FrameTime()*2)
		self:OnIntervalThink()
	end
end

function modifier_aoko_lazers:OnIntervalThink()
	if IsServer() then
		self.counter = self.counter + 1
		if self.counter > 12 then return end

		local pos = self.ability:CalculateCirclePositions(self.part9, 75, self.right, self.counter, 6)

		self:FireBeamFromThere(pos, self.forward)
	end
end

function modifier_aoko_lazers:FireBeamFromThere(pos, forward)
	if IsServer() then
		local caster = self:GetCaster()
		local range = self.ability:GetSpecialValueFor("range")
		local damage = self.ability:GetSpecialValueFor("damage")
		local amp = self.ability:GetSpecialValueFor("circuit_amplify_per_stack")

		local vision_duration = self.ability:GetSpecialValueFor("attribute_vision_duration")

		if caster.MagicBulletLoadAcquired then
			damage = damage + self.ability:GetSpecialValueFor("attribute_int_scaling")*caster:GetIntellect()
		end

		local circuits = caster:FindAbilityByName("aoko_circuits")

		--damage = damage * (1 + circuits:GetStacks()*amp/100)

		local pepega = true
		local stacks = 0
		if self.max_stacks > 0 then
			if self.max_stacks - self.stack_gain >= 0 then
				self.max_stacks = self.max_stacks - self.stack_gain
				stacks = self.stack_gain
				pepega = false
			else
				stacks = self.max_stacks
				pepega = false
				self.max_stacks = 0
			end
		end

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

		local enemies = FATE_FindUnitsInLine(
									        caster:GetTeamNumber(),
									        self.part9 - 100*forward,
									        self.part9 + range*forward,
									        290,
											DOTA_UNIT_TARGET_TEAM_ENEMY,
											DOTA_UNIT_TARGET_ALL,
											0,
											FIND_CLOSEST
		   								)

		for _, enemy in pairs(enemies) do
			if not pepega then
				circuits:GainStacks(stacks)
				pepega = true
			end
			if caster.MagicBulletLoadAcquired then
				enemy:AddNewModifier(caster, self, "modifier_vision_provider", { duration = vision_duration })
			end
			DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)

			EmitSoundOn("edmon_beam_hit", enemy)
		end

		local spherecheck = FATE_FindUnitsInLine(
									        caster:GetTeamNumber(),
									        self.part9,
									        self.part9 + range*forward,
									        290,
											DOTA_UNIT_TARGET_TEAM_FRIENDLY,
											DOTA_UNIT_TARGET_ALL,
											DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
											FIND_CLOSEST
		   								)

		for _, check in pairs(spherecheck) do
			if check:HasModifier("modifier_aoko_sphere_dummy") then
				check:FindModifierByName("modifier_aoko_sphere_dummy"):LazersExplode()
			end
		end
	end
end