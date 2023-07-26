LinkLuaModifier("modifier_arcueid_regen", "abilities/arcueid/arcueid_regen", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcueid_what_barrier", "abilities/arcueid/arcueid_regen", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcueid_barrier_cooldown", "abilities/arcueid/arcueid_regen", LUA_MODIFIER_MOTION_NONE)

arcueid_regen = class({})

function arcueid_regen:GetIntrinsicModifierName()
	return "modifier_arcueid_regen"
end

modifier_arcueid_regen = class({})

function modifier_arcueid_regen:IsHidden() return true end
function modifier_arcueid_regen:IsDebuff() return false end
--function modifier_true_assassin_selfmod:IsPurgable() return false end
--function modifier_true_assassin_selfmod:IsPurgeException() return false end
function modifier_arcueid_regen:RemoveOnDeath() return false end
function modifier_arcueid_regen:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_arcueid_regen:DeclareFunctions()
	local func = {	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
				}
	return func
end

function modifier_arcueid_regen:OnCreated()
	if IsServer() then
		self.stack_count = 0
		self.ability = self:GetAbility()
	end
end

function modifier_arcueid_regen:OnTakeDamage(args)
	if IsServer() then
		if args.unit ~= self:GetParent() then return end

		local duration = self.ability:GetSpecialValueFor("duration")

		local delta = args.damage/duration*self.ability:GetSpecialValueFor("regen_percent")/100

		self.stack_count = self.stack_count + delta
		self:SetStackCount(self.stack_count)
		Timers:CreateTimer(duration, function()
			self.stack_count = self.stack_count - delta
			self:SetStackCount(self.stack_count)
		end)

		if args.unit.RegenAcquired and not args.unit:HasModifier("modifier_arcueid_barrier_cooldown") and (args.unit:GetHealth() < self:GetAbility():GetSpecialValueFor("threshold")) then
			args.unit:AddNewModifier(args.unit, self:GetAbility(), "modifier_arcueid_what_barrier", {duration = self:GetAbility():GetSpecialValueFor("barrier_duration")})
			args.unit:AddNewModifier(args.unit, self:GetAbility(), "modifier_arcueid_barrier_cooldown", {duration = self:GetAbility():GetCooldown(-1)})
			self:GetAbility():StartCooldown(self:GetAbility():GetCooldown(-1))
		end
	end
end

function modifier_arcueid_regen:GetModifierConstantHealthRegen()
	return self:GetParent():GetModifierStackCount("modifier_arcueid_regen", self:GetParent())
end

modifier_arcueid_what_barrier = class({})

function modifier_arcueid_what_barrier:IsHidden() return false end
function modifier_arcueid_what_barrier:IsDebuff() return false end

function modifier_arcueid_what_barrier:OnCreated()

end

function modifier_arcueid_what_barrier:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
--[[function modifier_arcueid_what_barrier:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end]]
function modifier_arcueid_what_barrier:GetModifierIncomingDamageConstant(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.damage
            local blocked = 0
            if block_check > 0 then
            	blocked = keys.original_damage
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
            	blocked = keys.damage--block_now
            	local damage = keys.damage - block_now
            	local dmgtable = {
		            attacker = keys.attacker,
		            victim = keys.target,
		            damage = damage,
		            damage_type = keys.damage_type,
		            damage_flags = keys.damage_flags,
		            ability = keys.inflictor
		        }
                self:Destroy()
                ApplyDamage(dmgtable)
            end

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end

function modifier_arcueid_what_barrier:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = self.hAbility:GetSpecialValueFor("barrier_amount")


    
    if not self.iShieldPFX then
	    self.iShieldPFX = ParticleManager:CreateParticle( "particles/arcueid/arcueid_barrier.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
	    ParticleManager:SetParticleControl( self.iShieldPFX, 0, self.hCaster:GetAbsOrigin() )

	    self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
	end

	if IsServer() then
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_arcueid_what_barrier:OnRefresh(hTable)
	self:OnCreated(hTable)
end

modifier_arcueid_barrier_cooldown = class({})

function modifier_arcueid_barrier_cooldown:IsHidden()           return false end
function modifier_arcueid_barrier_cooldown:IsDebuff()           return true end
function modifier_arcueid_barrier_cooldown:IsPurgable()         return false end
function modifier_arcueid_barrier_cooldown:IsPurgeException()   return false end
function modifier_arcueid_barrier_cooldown:RemoveOnDeath()      return false end