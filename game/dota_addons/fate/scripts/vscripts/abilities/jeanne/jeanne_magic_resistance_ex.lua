LinkLuaModifier("modifier_jeanne_mrex", "abilities/jeanne/jeanne_magic_resistance_ex", LUA_MODIFIER_MOTION_NONE)

jeanne_magic_resistance_ex = class({})

function jeanne_magic_resistance_ex:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_jeanne_mrex", {})
end

modifier_jeanne_mrex = class({})

function modifier_jeanne_mrex:IsHidden() return false end
function modifier_jeanne_mrex:IsDebuff() return false end

function modifier_jeanne_mrex:OnCreated()

end

function modifier_jeanne_mrex:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT
					}
	return hFunc
end
--[[function modifier_jeanne_mrex:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end]]
function modifier_jeanne_mrex:GetModifierIncomingSpellDamageConstant(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.original_damage
            local blocked = 0
            if block_check > 0 then
            	blocked = keys.original_damage
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
            	blocked = keys.original_damage--block_now
            	local damage = keys.original_damage - block_now
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
--[[function modifier_jeanne_mrex:GetModifierMagical_ConstantBlock(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.damage
            if block_check > 0 then
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
                self:Destroy()
            end

            return block_now
        end
	end
end]]

function modifier_jeanne_mrex:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	if not self.fBarrierBlock then
		self.fBarrierBlock = 0
	end

	self.fBarrierBlock = math.min(self.fBarrierBlock + self.hAbility:GetSpecialValueFor("barrier_per_cast"), self.hAbility:GetSpecialValueFor("barrier_cap"))
    
    if not self.iShieldPFX then
	    self.iShieldPFX = ParticleManager:CreateParticle( "particles/jeanne/jeanne_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
	    ParticleManager:SetParticleControl(self.iShieldPFX, 0, self.hParent:GetAbsOrigin())

	    self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
	else
		local flashFX = ParticleManager:CreateParticle("particles/jeanne/jeanne_shield_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent)
		ParticleManager:SetParticleControl(flashFX, 0, self.hParent:GetAbsOrigin())

		ParticleManager:ReleaseParticleIndex(flashFX)
	end

	if IsServer() then
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_jeanne_mrex:OnRefresh(hTable)
	self:OnCreated(hTable)
end