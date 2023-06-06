LinkLuaModifier("modifier_merlin_charisma_aura", "abilities/merlin/merlin_charisma", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_charisma", "abilities/merlin/merlin_charisma", LUA_MODIFIER_MOTION_NONE) 
LinkLuaModifier("modifier_rapid_chanting", "abilities/merlin/merlin_charisma", LUA_MODIFIER_MOTION_NONE) 
merlin_charisma = class({})


function merlin_charisma:AttStack() 
	local caster = self:GetCaster()
	if  not caster.KingAssistantAcquired then return end
	if(caster:HasModifier("modifier_rapid_chanting")) then
		local repeatedStacks = caster:GetModifierStackCount("modifier_rapid_chanting", caster)
		if(repeatedStacks <=self:GetMaxStackCount()) then    
			caster:AddNewModifier(caster,self,"modifier_rapid_chanting",{duration = self:GetSpecialValueFor("att_duration")})       
			caster:SetModifierStackCount("modifier_rapid_chanting",caster, repeatedStacks +1)
		else
			caster:AddNewModifier(caster,self,"modifier_rapid_chanting",{duration = self:GetSpecialValueFor("att_duration")})     
		end
	else
		caster:AddNewModifier(caster,self,"modifier_rapid_chanting",{duration = self:GetSpecialValueFor("att_duration")})   
		caster:SetModifierStackCount("modifier_rapid_chanting",caster, 1)    
	end
	
end

function merlin_charisma:GetMaxStackCount()  
	return 5
end

function merlin_charisma:GetIntrinsicModifierName()
	return "modifier_merlin_charisma_aura"
end

modifier_merlin_charisma_aura = class({})

function modifier_merlin_charisma_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_merlin_charisma_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_merlin_charisma_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_merlin_charisma_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_merlin_charisma_aura:GetModifierAura()
	return "modifier_merlin_charisma"
end

function modifier_merlin_charisma_aura:IsHidden()
	return true
end

function modifier_merlin_charisma_aura:RemoveOnDeath()
	return false
end

function modifier_merlin_charisma_aura:IsDebuff()
	return false 
end

function modifier_merlin_charisma_aura:IsAura()
	if self:GetParent():IsIllusion() then return false end
	return true 
end

function modifier_merlin_charisma_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--

modifier_merlin_charisma = class({})

function modifier_merlin_charisma:IsHidden() return false end
function modifier_merlin_charisma:IsDebuff() return false end
function modifier_merlin_charisma:DeclareFunctions()
	return { MODIFIER_PROPERTY_HEALTH_BONUS, 
	MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
	MODIFIER_PROPERTY_MANA_REGEN_CONSTANT     }
end
function modifier_merlin_charisma:GetModifierHealthBonus()
	return  self:GetAbility():GetSpecialValueFor("health_bonus"); 
end
function modifier_merlin_charisma:GetModifierHealthRegenPercentage()
	return self:GetAbility():GetSpecialValueFor("health_regen_bonus");  
end

function modifier_merlin_charisma:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("mana_regen_bonus");  
end


function modifier_merlin_charisma:GetTexture()
    return "custom/merlin/merlin_dreamlike_charisma_attribute"
end



modifier_rapid_chanting = class({})

function modifier_rapid_chanting:IsHidden() return false end
function modifier_rapid_chanting:IsDebuff() return false end
function modifier_rapid_chanting:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, 
     }
end
function modifier_rapid_chanting:GetModifierAttackSpeedBonus_Constant()
	return  self:GetAbility():GetSpecialValueFor("att_attackspeed_per_stack")*self:GetStackCount(); 
end
 

function modifier_rapid_chanting:GetTexture()
    return "custom/merlin/merlin_rapid_chanting"
end
