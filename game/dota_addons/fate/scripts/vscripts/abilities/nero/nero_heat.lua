LinkLuaModifier("modifier_nero_heat", "abilities/nero/nero_heat", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_laus_saint_ready_checker", "abilities/nero/modifiers/modifier_laus_saint_ready_checker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imperial_buff_h", "abilities/nero/nero_imperial", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_heat_stacks", "abilities/nero/nero_heat", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_performance", "abilities/nero/nero_heat", LUA_MODIFIER_MOTION_NONE)

nero_heat = class({})

function nero_heat:GetIntrinsicModifierName()
	return "modifier_nero_heat"
end

function nero_heat:GetAbilityTextureName()
	local rank = self:GetSequence()
 	
	return  "custom/nero/rank_"..rank 	
end
 
function nero_heat:OnSpellStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration = 2.0, activity = ACT_DOTA_CAST_ABILITY_1_END, rate = 1})
	caster:RemoveModifierByName("modifier_laus_saint_ready_checker")
	--if not caster:HasModifier("modifier_aestus_domus_aurea_nero") then return end
	if caster:FindModifierByName("modifier_nero_heat").rank >= 4 then
		caster.UpgradeBase = true
	end
	if caster:FindModifierByName("modifier_nero_heat").rank == 7 then
		caster.UpgradeLSK = true
	end
	Timers:CreateTimer(FrameTime(), function()
		caster:AddNewModifier(caster, self, "modifier_laus_saint_ready_checker", {duration = 4})
	end)
end

function nero_heat:IncreaseHeat(caster)
	local caster = caster
	local modifier = caster:FindModifierByName("modifier_nero_heat")

	if(not caster:HasModifier("modifier_nero_heat_stacks")) then
		caster:AddNewModifier(caster, self, "modifier_nero_heat_stacks", {})
	end
	modifier.duration_remaining = self:GetSpecialValueFor("duration")
	if not modifier.rank then
		modifier.rank = 0
		caster:FindModifierByName("modifier_nero_heat_stacks"):SetStackCount(0)
	end

	if caster.DiabolisVectisAcquired then
		local damage = self:GetSpecialValueFor("vectis_damage") + self:GetSpecialValueFor("vectis_damage_per_stack")*caster:FindModifierByName("modifier_nero_heat").rank
		local particle = ParticleManager:CreateParticle("particles/custom/berserker/nine_lives/hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

		ParticleManager:SetParticleControl(particle, 2, Vector(1,1,350))
		ParticleManager:SetParticleControl(particle, 3, Vector(350 / 350,1,1))

		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
		end)

		local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 350, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
		for _,enemy in pairs(enemies) do
			DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
	end

	if modifier.rank < 6 or (modifier.rank < 7 and caster:HasModifier("modifier_aestus_domus_aurea_nero")) then
		modifier.rank = modifier.rank + 1
		caster:FindModifierByName("modifier_nero_heat_stacks"):SetStackCount(modifier.rank)
		modifier:UpdateParticle()
	end

	--[[
	if(caster:HasModifier("modifier_aestus_domus_aurea_nero") and modifier.rank == 7) then
		self:EndCooldown()
	end
	]]--Ended bad, no D cd in arena after reaching SSS

	caster:AddNewModifier(caster, self, "modifier_imperial_buff_h", {duration = 5})
	
end

function nero_heat:RefreshHeatDuration(caster)
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_nero_heat")

	caster:AddNewModifier(caster, self, "modifier_imperial_buff_h", {duration = 5})
	

	modifier.duration_remaining = self:GetSpecialValueFor("duration")
end
 
function nero_heat:GetSequence()
	local caster = self:GetCaster()
	if( not caster:HasModifier("modifier_nero_heat_stacks")) then return 0 end
	return caster:GetModifierStackCount("modifier_nero_heat_stacks", caster)
end

function nero_heat:StartPerformance(vel_z, acc_z)
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_nero_performance", {vel_z = vel_z, acc_z = acc_z})
end

function nero_heat:PausePerformance(time)
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_nero_performance") then
		caster:FindModifierByName("modifier_nero_performance").pause_time = time
	end
end

function nero_heat:EndPerformance()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_nero_performance") then
		caster:RemoveModifierByName("modifier_nero_performance")
	end
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end

modifier_nero_performance = class({})

function modifier_nero_performance:IsHidden() return true end
function modifier_nero_performance:IsDebuff() return false end
function modifier_nero_performance:IsPurgable() return false end
function modifier_nero_performance:IsPurgeException() return false end
function modifier_nero_performance:RemoveOnDeath() return true end
function modifier_nero_performance:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_nero_performance:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_nero_performance:CheckState()
    local state =   { 
                        --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        --[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        --[MODIFIER_STATE_DISARMED] = true,
                        --[MODIFIER_STATE_SILENCED] = true,
                        --[MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_nero_performance:OnCreated(args)
    self.parent = self:GetParent()
    self.pause_time = 0
    self.vel = Vector(0, 0, args.vel_z)
    self.acc = Vector(0, 0, args.acc_z)
    self.first_frame = true
    self.position = self.parent:GetAbsOrigin()

    if IsServer() then
        self:StartIntervalThink(FrameTime())
    end
end
function modifier_nero_performance:OnIntervalThink()
    self:UpdateVerticalMotion(self.parent, FrameTime())
end
function modifier_nero_performance:OnRefresh(args)
    self:OnCreated(args)
end
function modifier_nero_performance:UpdateVerticalMotion(me, dt)
    if IsServer() then
    	if self.pause_time > 0 then
    		self.pause_time = self.pause_time - dt
    		return
    	end
        if self.first_frame or GetGroundPosition(self.parent:GetAbsOrigin(), self.parent).z <= self.parent:GetAbsOrigin().z then
        	self.first_frame = false
        	local ori = self.parent:GetAbsOrigin()
        	--print(GetGroundPosition(self.parent:GetAbsOrigin(), self.parent).z)
        	--print(self.parent:GetAbsOrigin().z)
        	local next_pos = Vector(ori.x, ori.y, self.position.z) + self.vel*dt
        	self.parent:SetAbsOrigin(next_pos)
        	self.position = self.parent:GetAbsOrigin()
        	self.vel = self.vel - self.acc*dt + (-1 * 0.05 * self.vel)
        else
            self:Destroy()
        end
    end
end
function modifier_nero_performance:OnVerticalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_nero_performance:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end

modifier_nero_heat = class({})

function modifier_nero_heat:IsHidden() return false end
function modifier_nero_heat:IsDebuff() return false end
function modifier_nero_heat:RemoveOnDeath() return false end
function modifier_nero_heat:OnCreated()
	self.rank = 0
end
function modifier_nero_heat:OnTakeDamage(args)
	if args.attacker ~= self:GetCaster() then return end

	self.ability = self:GetAbility()

	self.ability:RefreshHeatDuration()
end
function modifier_nero_heat:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_nero_heat:UpdateParticle()
	if not self.particle then
		self.particle = ParticleManager:CreateParticle("particles/nero/nero.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	    ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
	    self:StartIntervalThink(FrameTime())
	end
	ParticleManager:SetParticleControl(self.particle, 1, Vector(self.rank, 0, 0))
 
end
function modifier_nero_heat:OnIntervalThink()
	if not self:GetParent():HasModifier("modifier_aestus_domus_aurea_nero") then
		self.duration_remaining = self.duration_remaining - FrameTime()
	end
	--print(self.duration_remaining)
	if self.duration_remaining <= 0 then
		self.rank = 0
		if(  self:GetParent():HasModifier("modifier_nero_heat_stacks")) then  
			self:GetParent():FindModifierByName("modifier_nero_heat_stacks"):SetStackCount(0)
		end
	end
	self:UpdateParticle()
 
end
function modifier_nero_heat:DeclareFunctions()
    return {
    	--MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

 
function modifier_nero_heat:GetTexture()
	local rank = self:GetAbility():GetSequence()
 	
		return  "custom/nero/rank_"..rank 	
 
 
end


modifier_nero_heat_stacks = class({})

function modifier_nero_heat_stacks:IsHidden() return true end
function modifier_nero_heat_stacks:IsDebuff() return false end
function modifier_nero_heat_stacks:RemoveOnDeath() return false end