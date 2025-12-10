
modifier_barrier_new = class({})

function modifier_barrier_new:IsHidden() return false end
function modifier_barrier_new:IsDebuff() return false end

function modifier_barrier_new:GetPriority() return MODIFIER_PRIORITY_ULTRA end

function modifier_barrier_new:OnCreated(args)
	self.state = {}

	self.decreaseDamageOnProck = args.decreaseDamageOnProck
	self.beforeBScroll = args.beforeBScroll
	self.ShouldEndChannel = args.ShouldEndChannel
	if args.debuff_immune then
		self.state = {[MODIFIER_STATE_DEBUFF_IMMUNE] =true }
	end
	self.fBarrierBlock = args.shield_amount
	self.HasCounter = args.HasCounter
	print(self.HasCounter)
	self.hAbility = self:GetAbility()

	if IsServer() then
		if self.fBarrierBlock == nil then
			self:Destroy()
			return
		end
		if self.fBarrierBlock <= 0 then
			self:Destroy()
		end
		self:SetStackCount(self.fBarrierBlock)
	end
end

function modifier_barrier_new:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
function modifier_barrier_new:CheckState()
	return self.state
end
function modifier_barrier_new:GetModifierIncomingDamageConstant(keys)
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
				if self.beforeBScroll then
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
				end
				damage = damage - self.decreaseDamageOnProck
				self:ActivateCounter()
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


function modifier_barrier_new:OnRefresh(hTable)
	self:OnCreated(hTable)
end

function modifier_barrier_new:ActivateCounter()
	if IsServer() then 
		if self.ShouldEndChannel then
			self.hAbility:EndChannel(false)
		end
		if self.HasCounter == 1 then
			self.hAbility:Counter()
		end
	end
end
