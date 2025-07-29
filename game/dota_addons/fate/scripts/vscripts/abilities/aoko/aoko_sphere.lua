LinkLuaModifier("modifier_aoko_sphere_dummy", "abilities/aoko/aoko_sphere", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_sphere_slow", "abilities/aoko/aoko_sphere", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_sphere_meltdown", "abilities/aoko/aoko_sphere", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_aoko_sphere_healres", "abilities/aoko/aoko_sphere", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_1", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
aoko_sphere = class({})

function aoko_sphere:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("aoko_facebreaker"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("aoko_facebreaker"):SetLevel(self:GetLevel())
    end
end

function aoko_sphere:GetManaCost()
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("aoko_circuits")

	local stacks = ability:GetStacks()

	local base_manacost = self:GetSpecialValueFor("mana_cost")
	local increment = ability:GetSpecialValueFor("manacost_increase_per_stack")

	local result = math.min(base_manacost*(1 + stacks*increment/100), caster:GetMaxMana())

	return result
end

function aoko_sphere:GetAbilityChargeRestoreTime()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_aoko_circuits_overload") then
		return caster:FindAbilityByName("aoko_circuits"):GetSpecialValueFor("overload_sphere_charge_time")
	end
	return self:GetSpecialValueFor("base_charge_restore_time")
end

function aoko_sphere:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	local range = self:GetSpecialValueFor("range")
	local ori = caster:GetAbsOrigin()
	local vec = target - ori
	if vec:Length2D() > range then
		target = ori + vec:Normalized()*range
	end

	caster:EmitSound("aoko_sphere_throw_sfx")
	caster:EmitSound("aoko_sphere_"..math.random(1, 6))

	local height_att = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")).z - caster:GetAbsOrigin().z
	local part9 = caster:GetAbsOrigin() + Vector(0, 0, height_att) + caster:GetForwardVector()*150

	local particle = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, part9)
	ParticleManager:SetParticleControl(particle, 9, part9)

	local vision_radius = self:GetSpecialValueFor("vision_radius")

	local dummy = CreateUnitByName("aoko_sphere", caster:GetAbsOrigin() + caster:GetForwardVector()*150, false, nil, nil, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive_fly_pathing"):SetLevel(1)
	dummy:SetDayTimeVisionRange(vision_radius)
	dummy:SetNightTimeVisionRange(vision_radius)
	dummy:SetForwardVector(caster:GetForwardVector())
	dummy:AddNewModifier(caster, self, "modifier_aoko_sphere_dummy", {Duration  = self:GetSpecialValueFor("duration"), posx = target.x, posy = target.y, posz = target.z})
end

modifier_aoko_sphere_dummy = class({})

function modifier_aoko_sphere_dummy:OnCreated(keys)
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.target = Vector(keys.posx, keys.posy, keys.posz)
	self.radius = self.ability:GetSpecialValueFor("radius")

	local vec = (self.target - self.parent:GetAbsOrigin())
	vec.z = 0
	self.direction = vec:Normalized()
	self.range = vec:Length2D()

	self.stacks_gained = false

	self.moving = true

	self.count = 1

	self.fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)

	self:AddParticle(self.fx, false, false, -1, false, false)

	self.parent:EmitSound("aoko_sphere_sfx")

	self.explodable = true
	self.explodable_jumpback = true
	self.explodable_short = true
	self.explodable_lazers = true
	self.explodable_intimidation = true

	self.severe_exploded = false

	self.explosions_remaining = 12
	self.proximity_explosions_remaining = self.ability:GetSpecialValueFor("proximity_explosion_count")
	self.proximity_radius = self.ability:GetSpecialValueFor("proximity_radius")
	self.AttackedTargets = {}

	self:StartIntervalThink(FrameTime())
end

function modifier_aoko_sphere_dummy:OnRefresh(keys)
	if not IsServer() then return end

	if keys.unbreakable == 1 then
		self.unbreakable = true
	end
end

function modifier_aoko_sphere_dummy:OnIntervalThink()
	if not IsServer() then return end
	if not self.parent or self.parent:IsNull() then return end
	if self.moving then
		local point = self.parent:GetAbsOrigin() + 2*(15-self.count)/15*self.range/15*self.direction
		self.parent:SetAbsOrigin(GetGroundPosition(point, self.parent))

		self.count = self.count + 1
		if self.count >= 14 then
			self.moving = false
			self:ProximityExplode()
		end
	end

	local pos = self.parent:GetAbsOrigin()

	if self.severe_exploded then
		local severe_enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(),
	                                        pos, 
	                                        nil, 
	                                        self.radius, 
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                        DOTA_UNIT_TARGET_ALL, 
	                                        0, 
	                                        FIND_ANY_ORDER, 
	                                        false)

	    for _,severe_enemy in ipairs(severe_enemies) do
	    	severe_enemy:AddNewModifier(self.caster, self.ability, "modifier_aoko_sphere_meltdown", {duration = 0.1 + FrameTime()})
	    end
	end

	--[[if self.proximity_explosions_remaining <= 0 then return end

	local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(),
                                        pos, 
                                        nil, 
                                        self.proximity_radius,--radius, 
                                        DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                        DOTA_UNIT_TARGET_HERO, 
                                        0, 
                                        FIND_ANY_ORDER, 
                                        false)

    for _,enemy in ipairs(enemies) do
    	if not self.AttackedTargets[enemy:entindex()] then
        	local triggered = self:ProximityExplode(true)
        	if triggered then
        		self.AttackedTargets[enemy:entindex()] = true
        		self.proximity_explosions_remaining = self.proximity_explosions_remaining - 1
        	end
        end
    end]]
end

function modifier_aoko_sphere_dummy:ProximityExplode()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")
	local attr_duration = ability:GetSpecialValueFor("attribute_healres_duration")

	local circuits = caster:FindAbilityByName("aoko_circuits")
	local stacks = ability:GetSpecialValueFor("explosion_stacks")

	local ori = self.parent:GetAbsOrigin()

	local explosion_fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_aoe_area.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(explosion_fx, 0, ori)
	ParticleManager:SetParticleControl(explosion_fx, 2, ori)
	ParticleManager:SetParticleControl(explosion_fx, 7, Vector(radius, 0, 0))

	ParticleManager:ReleaseParticleIndex(explosion_fx)

	local enemies = FindUnitsInRadius(caster:GetTeam(), ori, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	for _, enemy in pairs(enemies) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
	    	if not self.stacks_gained then
	    		circuits:GainStacks(stacks)
	    		self.stacks_gained = true
	    	end
	    	if not enemy.AokoSphereExploded then 
	    		enemy.AokoSphereExploded = true
	        	Timers:CreateTimer(FrameTime(), function()
	        		enemy.AokoSphereExploded = false
	        	end)
	        	if caster.FirstStarAcquired then
	        		--enemy:AddNewModifier(caster, ability, "modifier_aoko_sphere_healres", {duration = attr_duration})
					enemy:AddNewModifier(caster, ability, "modifier_heal_reduction_tier_1", {duration = attr_duration})
	        	end
	        	DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        end
	    end
	end

	return true
end

function modifier_aoko_sphere_dummy:JumpbackExplode()
	if not IsServer() then return end

	if not self.explodable_jumpback then return end

	self.explodable_jumpback = false
	Timers:CreateTimer(FrameTime(), function()
		if self then
			self.explodable_jumpback = true
		end
	end)

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local par_ability = caster:FindAbilityByName("aoko_jumpback")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = par_ability:GetSpecialValueFor("sphere_damage")
	local lock_duration = par_ability:GetSpecialValueFor("sphere_lock")

	local circuits = caster:FindAbilityByName("aoko_circuits")
	local stacks = ability:GetSpecialValueFor("explosion_stacks")

	local ori = self.parent:GetAbsOrigin()

	local explosion_fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_aoe_area.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(explosion_fx, 0, ori)
	ParticleManager:SetParticleControl(explosion_fx, 2, ori)
	ParticleManager:SetParticleControl(explosion_fx, 7, Vector(radius, 0, 0))

	ParticleManager:ReleaseParticleIndex(explosion_fx)

	local enemies = FindUnitsInRadius(caster:GetTeam(), ori, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	for _, enemy in pairs(enemies) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
	    	if not self.stacks_gained then
	    		circuits:GainStacks(stacks)
	    		self.stacks_gained = true
	    	end
	    	if not enemy.AokoSphereExplodedJumpback then 
	    		enemy.AokoSphereExplodedJumpback = true
	        	Timers:CreateTimer(FrameTime(), function()
	        		enemy.AokoSphereExplodedJumpback = false
	        	end)
	        	giveUnitDataDrivenModifier(caster, enemy, "locked", lock_duration)
	        	DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        end
	    end
	end

	self:Destroy()

	return true
end

function modifier_aoko_sphere_dummy:ShortExplode()
	if not IsServer() then return end
	if not self.explodable_short then return end

	self.explodable_short = false
	Timers:CreateTimer(FrameTime(), function()
		if self then
			self.explodable_short = true
		end
	end)

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local par_ability = caster:FindAbilityByName("aoko_short_beam")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = par_ability:GetSpecialValueFor("sphere_damage")
	local root_duration = par_ability:GetSpecialValueFor("sphere_root")

	local circuits = caster:FindAbilityByName("aoko_circuits")
	local stacks = ability:GetSpecialValueFor("explosion_stacks")

	local ori = self.parent:GetAbsOrigin()

	--damage = damage*self.explosions_remaining/self.ability:GetSpecialValueFor("explosion_count")

	local explosion_fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_aoe_area.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(explosion_fx, 0, ori)
	ParticleManager:SetParticleControl(explosion_fx, 2, ori)
	ParticleManager:SetParticleControl(explosion_fx, 7, Vector(radius, 0, 0))

	ParticleManager:ReleaseParticleIndex(explosion_fx)

	local enemies = FindUnitsInRadius(caster:GetTeam(), ori, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	for _, enemy in pairs(enemies) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
	    	if not self.stacks_gained then
	    		circuits:GainStacks(stacks)
	    		self.stacks_gained = true
	    	end
	    	if not enemy.AokoSphereExplodedShort then 
	    		enemy.AokoSphereExplodedShort = true
	        	Timers:CreateTimer(FrameTime(), function()
	        		enemy.AokoSphereExplodedShort = false
	        	end)
	        	enemy:AddNewModifier(caster, ability, "modifier_rooted", {duration = root_duration})
	        	enemy:AddNewModifier(caster, ability, "modifier_disarmed", {duration = root_duration})
	        	DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)

	        end
	    end
	end

	self:Destroy()

	return true
end

function modifier_aoko_sphere_dummy:LazersExplode()
	if not IsServer() then return end
	if not self.explodable_lazers then return end

	self.explodable_lazers = false
	Timers:CreateTimer(0, function()
		if self then
			self.explodable_lazers = true
		end
	end)

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local par_ability = caster:FindAbilityByName("aoko_lazers")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = par_ability:GetSpecialValueFor("sphere_damage")
	local slow_duration = par_ability:GetSpecialValueFor("sphere_slow_duration")

	local circuits = caster:FindAbilityByName("aoko_circuits")
	local stacks = ability:GetSpecialValueFor("explosion_stacks")

	local ori = self.parent:GetAbsOrigin()

	local explosion_fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_aoe_area.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(explosion_fx, 0, ori)
	ParticleManager:SetParticleControl(explosion_fx, 2, ori)
	ParticleManager:SetParticleControl(explosion_fx, 7, Vector(radius, 0, 0))

	ParticleManager:ReleaseParticleIndex(explosion_fx)

	local enemies = FindUnitsInRadius(caster:GetTeam(), ori, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	for _, enemy in pairs(enemies) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
	    	if not self.stacks_gained then
	    		circuits:GainStacks(stacks)
	    		self.stacks_gained = true
	    	end
	    	if not enemy.AokoSphereExplodedLazers then 
	    		enemy.AokoSphereExplodedLazers = true
	        	Timers:CreateTimer(0, function()
	        		enemy.AokoSphereExplodedLazers = false
	        	end)
	        	enemy:AddNewModifier(caster, ability, "modifier_aoko_sphere_slow", {duration = slow_duration})
	        	DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        end
	    end
	end

	self.explosions_remaining = self.explosions_remaining - 1

	if self.explosions_remaining <= 0 then
		self:Destroy()
	end

	return true
end

function modifier_aoko_sphere_dummy:IntimidationExplode(point)
	if not IsServer() then return end
	if not self.explodable_intimidation then return end

	self.explodable_intimidation = false
	Timers:CreateTimer(FrameTime(), function()
		if self then
			self.explodable_intimidation = true
		end
	end)

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local par_ability = caster:FindAbilityByName("aoko_intimidation")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = par_ability:GetSpecialValueFor("sphere_damage")

	local circuits = caster:FindAbilityByName("aoko_circuits")
	local stacks = ability:GetSpecialValueFor("explosion_stacks")

	local ori = point--self.parent:GetAbsOrigin()

	damage = damage*self.explosions_remaining/self.ability:GetSpecialValueFor("explosion_count")

	local explosion_fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_aoe_area.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(explosion_fx, 0, ori)
	ParticleManager:SetParticleControl(explosion_fx, 2, ori)
	ParticleManager:SetParticleControl(explosion_fx, 7, Vector(radius, 0, 0))

	ParticleManager:ReleaseParticleIndex(explosion_fx)

	local enemies = FindUnitsInRadius(caster:GetTeam(), ori, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	for _, enemy in pairs(enemies) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
	    	if not self.stacks_gained then
	    		circuits:GainStacks(stacks)
	    		self.stacks_gained = true
	    	end
	    	if not enemy.AokoSphereExplodedIntimidation then 
	    		enemy.AokoSphereExplodedIntimidation = true
	        	Timers:CreateTimer(FrameTime(), function()
	        		enemy.AokoSphereExplodedIntimidation = false
	        	end)
	        	DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        end
	    end
	end
	
	self:Destroy()

	return true
end

function modifier_aoko_sphere_dummy:SevereExplode()
	if not IsServer() then return end
	if self.severe_exploded then return end

	self.severe_exploded = true
	
	self.meltdown_fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_meltdown.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)

	self:AddParticle(self.meltdown_fx, false, false, -1, false, false)

	return true
end

function modifier_aoko_sphere_dummy:OnDestroy()
	if not IsServer() then return end
	self:ProximityExplode()
	self:GetParent():RemoveSelf()
end

--

modifier_aoko_sphere_slow = class({})

function modifier_aoko_sphere_slow:IsHidden() return false end
function modifier_aoko_sphere_slow:IsDebuff() return true end
function modifier_aoko_sphere_slow:RemoveOnDeath() return true end
function modifier_aoko_sphere_slow:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
           }
end

function modifier_aoko_sphere_slow:GetModifierMoveSpeedBonus_Percentage(keys)
    return -1*self:GetCaster():FindAbilityByName("aoko_lazers"):GetSpecialValueFor("sphere_slow")
end

--

modifier_aoko_sphere_meltdown = class({})

function modifier_aoko_sphere_meltdown:IsHidden() return false end
function modifier_aoko_sphere_meltdown:IsDebuff() return true end
function modifier_aoko_sphere_meltdown:RemoveOnDeath() return true end
function modifier_aoko_sphere_meltdown:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
           }
end

function modifier_aoko_sphere_meltdown:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.damage = self.caster:FindAbilityByName("aoko_3_beams"):GetSpecialValueFor("sphere_dps")*0.1

	self:StartIntervalThink(0.1)
end

function modifier_aoko_sphere_meltdown:OnIntervalThink()
	if not IsServer() then return end

	DoDamage(self.caster, self.parent, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
end

function modifier_aoko_sphere_meltdown:GetModifierMoveSpeedBonus_Percentage(keys)
    return -1*self:GetCaster():FindAbilityByName("aoko_3_beams"):GetSpecialValueFor("sphere_slow")
end

--

modifier_aoko_sphere_healres = class({})

function modifier_aoko_sphere_healres:IsDebuff() return true end
function modifier_aoko_sphere_healres:IsHidden() return false end

function modifier_aoko_sphere_healres:RemoveOnDeath()
	return true
end

function modifier_aoko_sphere_healres:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_aoko_sphere_healres:GetModifierHealAmplify_PercentageTarget()
	return self:GetAbility():GetSpecialValueFor("attribute_healres")
end

function modifier_aoko_sphere_healres:GetModifierHPRegenAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("attribute_healres")
end