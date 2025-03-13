LinkLuaModifier("modifier_b_scroll", "items/b_scroll", LUA_MODIFIER_MOTION_NONE)

item_b_scroll = class({})
function item_b_scroll:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if caster:HasModifier("jump_pause_nosilence") then
		RefundItem(caster, ability)
		return
	end

	hero.ServStat:useB()
	caster:AddNewModifier(caster, ability, "modifier_b_scroll", {duration = self:GetSpecialValueFor("duration"), barrier = self:GetSpecialValueFor("barrier_block")})
	caster.BShieldAmount = self:GetSpecialValueFor("barrier_block")
	caster:EmitSound("DOTA_Item.ArcaneBoots.Activate")

end

modifier_b_scroll = class({})

function modifier_b_scroll:IsHidden() return false end
function modifier_b_scroll:IsDebuff() return false end

function modifier_b_scroll:OnCreated()

end

function modifier_b_scroll:DeclareFunctions()
	local hFunc = 	{	
						MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT
					}
	return hFunc
end

function modifier_b_scroll:GetModifierIncomingSpellDamageConstant(keys)
	if IsServer() then
		if keys.inflictor then
            if keys.target:HasModifier("modifier_aoko_shield") or keys.target:HasModifier("modifier_heart_of_harmony") then
                return
            end
			if BIgnoreCheck(keys.inflictor) then
				return
			end
		end
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

function modifier_b_scroll:GetEffectName()
	return "particles/units/heroes/hero_oracle/oracle_false_promise_heal_core.vpcf"
end
function modifier_b_scroll:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_b_scroll:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	if not self.fBarrierBlock then
		self.fBarrierBlock = 0
	end

	self.fBarrierBlock = hTable.barrier
    
  

	if IsServer() then
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_b_scroll:OnRefresh(hTable)
	self:OnCreated(hTable)
end
