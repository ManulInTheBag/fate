emiya_rho_aias = class({})

LinkLuaModifier("modifier_rho_aias_emiya", "abilities/emiya/emiya_rho_aias", LUA_MODIFIER_MOTION_NONE)

 

function emiya_rho_aias:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	local ability = self
	local ply = caster:GetPlayerOwner()
	local shield = self:GetSpecialValueFor("shield_amount")
	if   caster:HasModifier("modifier_shroud_of_martin")   then
		shield = shield  + 1000
	end


	local soundQueue = math.random(1,2)

	if soundQueue == 1 then
		caster:EmitSound("Archer.RhoAias" ) 
	else
		caster:EmitSound("Emiya_Rho_Aias_Alt")
	end
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true    then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_emiya_d"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	caster:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")

	target:AddNewModifier(caster, self, "modifier_rho_aias_emiya", { duration = self:GetSpecialValueFor("duration"), block = shield })
end
 





 
modifier_rho_aias_emiya = class({})

function modifier_rho_aias_emiya:IsHidden() return false end
function modifier_rho_aias_emiya:IsDebuff() return false end

function modifier_rho_aias_emiya:DeclareFunctions()
	local hFunc = 	{	
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT 
					}
	return hFunc
end
 
function modifier_rho_aias_emiya:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end


function modifier_rho_aias_emiya:GetModifierIncomingDamageConstant(keys)
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
 
function modifier_rho_aias_emiya:OnCreated(hTable)
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
function modifier_rho_aias_emiya:OnRefresh(hTable)
	self:OnCreated(hTable)
end