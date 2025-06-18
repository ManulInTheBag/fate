modifier_rune_of_protection = class({})

function modifier_rune_of_protection:IsHidden()
	return false 
end

function modifier_rune_of_protection:RemoveOnDeath()
	return true
end
function modifier_rune_of_protection:GetEffectName()
    return "particles/zlodemon/immunity_sphere_buff_red.vpcf"
end
function modifier_rune_of_protection:GetEffectAttachType()
    return PATTACH_CUSTOMORIGIN_FOLLOW
end



function modifier_rune_of_protection:IsDebuff() 
	return false
end




function modifier_rune_of_protection:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end



function modifier_rune_of_protection:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end

function modifier_rune_of_protection:GetModifierIncomingDamageConstant(keys)
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

            	local IsBScrollIgnored = false
            	if keys.damage_type == DAMAGE_TYPE_MAGICAL then
			        if keys.inflictor then
			        	if BIgnoreCheck(keys.inflictor) then
			        		IsBScrollIgnored = true
			        	end


				        if IsBScrollIgnored == false and keys.target:HasModifier("modifier_b_scroll") then 
				            local originalDamage = damage - keys.target.BShieldAmount
				            keys.target.BShieldAmount = keys.target.BShieldAmount - damage
				            if keys.target.BShieldAmount <= 0 then
				                damage = originalDamage
				                keys.target:RemoveModifierByName("modifier_b_scroll")
				            else 
				                damage = 0
				            end
				        end
				    end
			    end

				self:GetAbility():OnRuneProck()
				if damage > 0 then
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
            end

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end

function modifier_rune_of_protection:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = self.hAbility:GetSpecialValueFor("shield_amount")
    


	if IsServer() then
		--self.hCaster:EmitSound("lancelot_parry_sfx")
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_rune_of_protection:OnRefresh(hTable)
	self:OnCreated(hTable)
end


--