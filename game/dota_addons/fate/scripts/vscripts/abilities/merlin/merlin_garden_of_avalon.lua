LinkLuaModifier("modifier_merlin_garden_of_avalon","abilities/merlin/merlin_garden_of_avalon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_garden_of_avalon_aura","abilities/merlin/merlin_garden_of_avalon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_avalon_self","abilities/merlin/merlin_garden_of_avalon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_avalon_self_disable","abilities/merlin/merlin_garden_of_avalon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_combo_cd", "abilities/merlin/merlin_garden_of_avalon", LUA_MODIFIER_MOTION_NONE)
merlin_garden_of_avalon = class({})


 
 
function merlin_garden_of_avalon:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
	caster:AddNewModifier(caster, self, "modifier_merlin_combo_cd", {duration = self:GetCooldown(1)})
	caster:RemoveModifierByName("modifier_merlin_avalon")
	caster:AddNewModifier(caster, self, "modifier_merlin_avalon_self_disable", {duration = 3})

	local counter = 0	 
	self.sound = "garden_of_avalon_"..math.random(1,2)
	EmitGlobalSound(self.sound)

	Timers:CreateTimer(3, function()       
		if(caster:IsAlive() == false) then    
			StopGlobalSound(self.sound)
			return end
		self.particle = ParticleManager:CreateParticle("particles/merlin/garden_of_avalon_flowers.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(    self.particle , 0,  caster:GetAbsOrigin()   )  
		caster:AddNewModifier(caster, self, "modifier_merlin_garden_of_avalon_aura",{duration = self:GetSpecialValueFor("duration")+4 })
		if(caster:HasModifier( "modifier_share_damage")) then
			caster:RemoveModifierByName( "modifier_share_damage")
		end
		caster:AddNewModifier(caster, self, "modifier_merlin_avalon_self", {duration = self:GetSpecialValueFor("duration")+4})	
		StartAnimation(caster, {duration=  self:GetSpecialValueFor("duration")+4, activity=ACT_DOTA_CAST_ABILITY_7, rate=1 })
		
		EmitGlobalSound("garden_of_avalon_long")
	end)
    Timers:CreateTimer(3.05, function()     
		if(caster:IsAlive() == false) then    	return end
		
		if(counter < 5) then
			counter = counter +2
		else
			counter = counter +1 
		end
		ParticleManager:SetParticleControl(self.particle , 1, Vector(32*counter,counter*17+150,0) )  
		if(counter == 50) then
	 
			caster:SwapAbilities("merlin_avalon", "merlin_avalon_garden_stop", false, true)
			EmitGlobalSound("avalon_flowers") 
			Timers:CreateTimer(4, function() 
				EmitGlobalSound("avalon_flowers") 
				Timers:CreateTimer(2, function() 
					StopGlobalSound("avalon_flowers") 
				
					
				end)
				
			end)
			Timers:CreateTimer(self:GetSpecialValueFor("duration"), function() 
				ParticleManager:DestroyParticle(self.particle, true)
				ParticleManager:ReleaseParticleIndex(self.particle)
			
				
			end)
			return  
		end
		return 0.08
	
	end)    
    
	
end


modifier_merlin_garden_of_avalon_aura = class({})

function modifier_merlin_garden_of_avalon_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_merlin_garden_of_avalon_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_merlin_garden_of_avalon_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_merlin_garden_of_avalon_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_merlin_garden_of_avalon_aura:GetModifierAura()
	return "modifier_merlin_garden_of_avalon"
end

function modifier_merlin_garden_of_avalon_aura:IsHidden()
	return true
end

function modifier_merlin_garden_of_avalon_aura:RemoveOnDeath()
	return true
end

function modifier_merlin_garden_of_avalon_aura:IsDebuff()
	return false 
end

function modifier_merlin_garden_of_avalon_aura:IsAura()
	return true 
end

function modifier_merlin_garden_of_avalon_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end



modifier_merlin_garden_of_avalon = class({})

function modifier_merlin_garden_of_avalon:OnCreated( )
	self:StartIntervalThink(0.3)
	--self.flag = 0
end
 
function modifier_merlin_garden_of_avalon:OnIntervalThink()
	if(self:GetParent() ~= self:GetCaster()) then
		HardCleanse(self:GetParent())
		--self.flag = 1
	end
end
--[[ 
function modifier_merlin_garden_of_avalon:OnTakeDamage(args)
    local caster =self:GetParent()
         if(self.flag == 1)then
            caster:SetHealth(caster:GetHealth()+args.damage)
			self.flag = 0
        end
end
]]
function modifier_merlin_garden_of_avalon:OnDestroy( )
 
end


function modifier_merlin_garden_of_avalon:IsHidden() return false end
function modifier_merlin_garden_of_avalon:IsDebuff() return false end
function modifier_merlin_garden_of_avalon:RemoveOnDeath() return true end
function modifier_merlin_garden_of_avalon:DeclareFunctions()
	return { 
	MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
    MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	MODIFIER_PROPERTY_HEALTH_BONUS  }
end

function modifier_merlin_garden_of_avalon:GetModifierHealthBonus()
	return  600
end

function modifier_merlin_garden_of_avalon:GetModifierHealthRegenPercentage()
	return self:GetAbility():GetSpecialValueFor("health_regen_bonus");  
end

function modifier_merlin_garden_of_avalon:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("health_regen_bonus_const");  
end

function modifier_merlin_garden_of_avalon:GetModifierTotalPercentageManaRegen()
	return self:GetAbility():GetSpecialValueFor("mana_regen_bonus");  
end

 

function modifier_merlin_garden_of_avalon:GetTexture()
    return "custom/merlin/merlin_garden_of_avalon"
end



 


modifier_merlin_avalon_self = class({})

function modifier_merlin_avalon_self:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING,
	MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	MODIFIER_PROPERTY_PROVIDES_FOW_POSITION   }

	return funcs
end

function modifier_merlin_avalon_self:GetModifierDisableTurning() 
	return 1
end

function modifier_merlin_avalon_self:OnRespawn() 
	 if(self:GetAbility().particle ~= null) then
		ParticleManager:DestroyParticle(self:GetAbility().particle, true)
		ParticleManager:ReleaseParticleIndex(self:GetAbility().particle)
		self:Destroy()
	 end
end

function modifier_merlin_avalon_self:OnDestroy() 
	if(self:GetAbility().particle ~= null) then
		ParticleManager:DestroyParticle(self:GetAbility().particle, true)
		ParticleManager:ReleaseParticleIndex(self:GetAbility().particle)
		self:GetCaster():RemoveModifierByName("modifier_merlin_garden_of_avalon_aura")
		if(self:GetCaster():GetAbilityByIndex(3):GetName() == "merlin_avalon_garden_stop" ) then
			self:GetCaster():SwapAbilities("merlin_avalon", "merlin_avalon_garden_stop", true, false)
		end
	end
end



function modifier_merlin_avalon_self:GetModifierIncomingDamage_Percentage() 
	return -70
end
function modifier_merlin_avalon_self:GetModifierProvidesFOWVision()
    return 1
end
 
function modifier_merlin_avalon_self:CheckState()
    local state =   { 
 
						--[MODIFIER_STATE_INVULNERABLE] = true,
						[MODIFIER_STATE_ROOTED] = true,
						[MODIFIER_STATE_DISARMED] = true,
						--[MODIFIER_STATE_UNTARGETABLE] = true,
						--[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
						--[MODIFIER_STATE_NO_HEALTH_BAR] = true,
						[MODIFIER_STATE_STUNNED] = true,
						  
						  
                 

                    }
    return state
end


 
function modifier_merlin_avalon_self:IsHidden() return true end
function modifier_merlin_avalon_self:RemoveOnDeath() return true end



modifier_merlin_avalon_self_disable = class({})

 

 
 
function modifier_merlin_avalon_self_disable:CheckState()
    local state =   { 
                        
						[MODIFIER_STATE_SILENCED] = true,
						--[MODIFIER_STATE_MUTED] = true,
                     }
    return state
end


 
function modifier_merlin_avalon_self_disable:IsHidden() return true end
function modifier_merlin_avalon_self_disable:RemoveOnDeath() return true end


modifier_merlin_combo_cd = class({})

function modifier_merlin_combo_cd:GetTexture()
    return "custom/merlin/merlin_garden_of_avalon"
end

function modifier_merlin_combo_cd:IsHidden()
    return false 
end

function modifier_merlin_combo_cd:RemoveOnDeath()
    return false
end

function modifier_merlin_combo_cd:IsDebuff()
    return true 
end

function modifier_merlin_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end