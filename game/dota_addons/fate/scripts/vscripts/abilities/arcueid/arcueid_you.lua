LinkLuaModifier("modifier_arcueid_you_tracker", "abilities/arcueid/arcueid_you", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcueid_you", "abilities/arcueid/arcueid_you", LUA_MODIFIER_MOTION_NONE)

arcueid_you = class({})

function arcueid_you:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function arcueid_you:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_arcueid_you_tracker") then
		local stack = caster:GetModifierStackCount("modifier_arcueid_you_tracker", caster)

		return stack
	else
		return 1
	end
end

function arcueid_you:GetManaCost()
	if self:CheckSequence() > 1 then
		return 0
	end
end

function arcueid_you:SequenceSkill()
	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_arcueid_you_tracker")

	if not modifier then
		caster:AddNewModifier(caster, ability, "modifier_arcueid_you_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_arcueid_you_tracker", ability, 2)
	else
		caster:AddNewModifier(caster, ability, "modifier_arcueid_you_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_arcueid_you_tracker", ability, modifier:GetStackCount() + 1)
	end
end

function arcueid_you:GetCastAnimation()
	local seq = self:CheckSequence()
	if seq == 1 then
		return ACT_DOTA_ATTACK2
	elseif seq == 2 then
		return ACT_DOTA_ATTACK
	end
	return ACT_DOTA_CAST_ABILITY_2
end

function arcueid_you:OnSpellStart()
	local caster = self:GetCaster()
	local seq = self:CheckSequence()

	if seq == 1 then
		self:SequenceSkill()
		self:EndCooldown()

		self:SimpleKick(seq)
	elseif seq == 2 then
		self:SequenceSkill()
		self:EndCooldown()

		self:SimpleKick(seq)
	else
		self:EndSequence()

		self:SimpleKick(seq)
	end
end

function arcueid_you:EndSequence()
	self:GetCaster():RemoveModifierByName("modifier_arcueid_you_tracker")
end

function arcueid_you:SimpleKick(seq)
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local sound = 3 + seq

	local part_vec = Vector(0, 20, 180)

	if seq == 1 then
		part_vec = Vector(-30, 0, 180)
	elseif seq == 2 then
		part_vec = Vector(30, 180, 0)
	end

	caster:EmitSound("arcueid_ready_"..sound)

	--caster:AddNewModifier(caster, self, "modifier_arcueid_you", {duration = 0.1})
	
	local particle = ParticleManager:CreateParticle("particles/arcueid/arcueid_slash_red.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
	ParticleManager:SetParticleControl(particle, 10, part_vec)
	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)
	
	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        self:GetSpecialValueFor("radius"),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)
	for _,enemy in pairs(enemies) do
		local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
		local origin_diff_norm = origin_diff:Normalized()
		if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
			enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration"..seq)})
			if caster.RecklesnessAcquired then
				caster:PerformAttack( enemy, true, true, true, true, false, false, true )
			end
		    for i = 0,1 do
			   	Timers:CreateTimer(FrameTime()*i*3, function()
			   		
			   		DoDamage(caster, enemy, damage/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
			    	EmitSoundOn("arcueid_hit", enemy)
		        end)
		    end
		end
	end
end

modifier_arcueid_you_tracker = class({})

function modifier_arcueid_you_tracker:OnCreated()
	if IsServer() then
	end
end 

function modifier_arcueid_you_tracker:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()

		local ability = self:GetAbility()
		ability:EndCooldown()
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1))
	end
end

function modifier_arcueid_you_tracker:IsPurgable()
	return false
end

function modifier_arcueid_you_tracker:IsHidden()
	return true
end

function modifier_arcueid_you_tracker:IsDebuff()
	return false
end

function modifier_arcueid_you_tracker:RemoveOnDeath()
	return true
end

function modifier_arcueid_you_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--[[function arcueid_you:OnAbilityPhaseStart()
    self:GetCaster():EmitSound("arcueid_ult_1")
    return true
end

function arcueid_you:OnAbilityPhaseInterrupted()
    self:GetCaster():StopSound("arcueid_ult_1")
end]]

modifier_arcueid_you = class({})

function modifier_arcueid_you:IsHidden() return true end
function modifier_arcueid_you:IsDebuff() return false end
function modifier_arcueid_you:RemoveOnDeath() return true end

function modifier_arcueid_you:OnCreated()
	if IsServer() then
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.speed = 1000

		self:StartIntervalThink(FrameTime())
	end
end

function modifier_arcueid_you:OnIntervalThink()
	if IsServer() then
		local caster = self.caster
		local vector = caster:GetForwardVector()
		vector.z = 0
		local target = caster:GetAbsOrigin() + vector*self.speed*FrameTime()
		if GridNav:IsTraversable(target) and (not GridNav:IsBlocked(target)) then
			caster:SetAbsOrigin(GetGroundPosition(target, caster))
		end
	end
end

function modifier_arcueid_you:CheckState()
	return {  [MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_arcueid_you:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE}
end

function modifier_arcueid_you:GetModifierTurnRate_Percentage()
	return -50
end
