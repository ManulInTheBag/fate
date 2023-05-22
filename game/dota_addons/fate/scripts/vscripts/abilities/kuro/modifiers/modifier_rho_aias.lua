modifier_rho_aias = class({})

LinkLuaModifier("modifier_rho_aias_particle", "abilities/emiya/modifiers/modifier_rho_aias_particle", LUA_MODIFIER_MOTION_NONE)

 
modifier_rho_aias = class({})

function modifier_rho_aias:IsHidden() return false end
function modifier_rho_aias:IsDebuff() return false end

function modifier_rho_aias:DeclareFunctions()
	local hFunc = 	{	
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT 
					}
	return hFunc
end
 
function modifier_rho_aias:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end


function modifier_rho_aias:GetModifierIncomingDamageConstant(keys)
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
 
function modifier_rho_aias:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()
    local block =  hTable.block

    
    if not self.aiasfx then
		self.aiasfx = ParticleManager:CreateParticle("particles/emiya/emiya_aias_self.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self:GetParent() )
		ParticleManager:SetParticleControl( self.aiasfx, 1, Vector(1,0,0) )

	    self:AddParticle(self.aiasfx, false, false, -1, false, false)
	end

	if IsServer() then
		self:SetStackCount(block)
	end
end
function modifier_rho_aias:OnRefresh(hTable)
	self:OnCreated(hTable)
end