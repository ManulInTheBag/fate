gawain_artificial_sun = class({})

LinkLuaModifier("modifier_artificial_sun_aura", "abilities/gawain/gawain_artificial_sun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artificial_sun", "abilities/gawain/gawain_artificial_sun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artificial_sun_aura_enemy", "abilities/gawain/gawain_artificial_sun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artificial_sun_enemy", "abilities/gawain/gawain_artificial_sun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sun_remover", "abilities/gawain/gawain_artificial_sun", LUA_MODIFIER_MOTION_NONE)
 

function gawain_artificial_sun:GetAbilityDamageType()
    return DAMAGE_TYPE_MAGICAL
end
 
function gawain_artificial_sun:GetIntrinsicModifierName()
    return "modifier_sun_remover"
end


function gawain_artificial_sun:GenerateArtificialSun(caster, location, isLockedOnTarget, ability)
	local ply = caster:GetPlayerOwner()
	local IsSunActive = true
	local radius = self:GetSpecialValueFor("area_of_effect")
	local artSun = CreateUnitByName("gawain_artificial_sun", location, true, nil, nil, caster:GetTeamNumber())
 
    ----To prevent suns from same abilities exist at same time. Could have written it better but lazy AF
    if(ability == "gawain_sun_of_galatine") then
        if( not self.SOG_Sun or self.SOG_Sun:IsNull()) then
            self.SOG_Sun = artSun
        else
            self.SOG_Sun:RemoveSelf() 
            self.SOG_Sun = artSun
        end
       
    elseif(ability == "gawain_blade_of_the_devoted") then
        if( not self.Blade_sun or self.Blade_sun:IsNull()) then
            self.Blade_sun = artSun
        else
            self.Blade_sun:RemoveSelf() 
            self.Blade_sun = artSun
        end
     
    else
        if( not self.Ult_sun or self.Ult_sun:IsNull()) then
            self.Ult_sun = artSun
        else
            self.Ult_sun:RemoveSelf() 
            self.Ult_sun = artSun
        end
        
    end

	artSun:SetDayTimeVisionRange(radius)
	artSun:SetNightTimeVisionRange(radius)
	artSun:AddNewModifier(caster, self, "modifier_kill", {duration = 15})
    Timers:CreateTimer(15, function()
        if IsNotNull(artSun) then
            artSun:RemoveSelf()
        end
    end)
    artSun:AddNewModifier(caster, self, "modifier_artificial_sun_aura", {duration = 15})
    artSun:AddNewModifier(caster, self, "modifier_artificial_sun_aura_enemy", {duration = 15})
	artSun:SetAbsOrigin(artSun:GetAbsOrigin() + Vector(0,0, 0))

    if caster.IsDawnAcquired then
		artSun:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 333}) 
	end
	 
end

 
-------------------------------------AURA FOR ALLIES-----------------------------
  
modifier_artificial_sun_aura = class({})

 

function modifier_artificial_sun_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY   
end

function modifier_artificial_sun_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_artificial_sun_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_artificial_sun_aura:GetAuraRadius()
	return 600
end

function modifier_artificial_sun_aura:GetModifierAura()
	return "modifier_artificial_sun"
end

function modifier_artificial_sun_aura:IsHidden()
	return true
end

function modifier_artificial_sun_aura:RemoveOnDeath()
	return true
end

function modifier_artificial_sun_aura:IsDebuff()
	return false 
end

function modifier_artificial_sun_aura:IsAura()
	return true 
end

function modifier_artificial_sun_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_artificial_sun_aura:CheckState()
    if IsServer() then
        local vLoc = GetGroundPosition(self:GetParent():GetAbsOrigin(), self:GetParent()) + Vector(0,0,500)
        self:GetParent():SetAbsOrigin(vLoc)
    end
end

modifier_artificial_sun = class({})


function modifier_artificial_sun:IsHidden() return false end
function modifier_artificial_sun:IsDebuff() return false end
function modifier_artificial_sun:RemoveOnDeath() return true end
function modifier_artificial_sun:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
      }
end
 
function modifier_artificial_sun:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("regen")  
end

function modifier_artificial_sun:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("mr")  
end

function modifier_artificial_sun:GetTexture()
    return "custom/gawain_suns_embrace"
end


-------------------------------------AURA FOR ENEMIES-----------------------------
modifier_artificial_sun_aura_enemy = class({})

function modifier_artificial_sun_aura_enemy:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY 
end

function modifier_artificial_sun_aura_enemy:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_artificial_sun_aura_enemy:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_artificial_sun_aura_enemy:GetAuraRadius()
	return self:GetParent():HasModifier("modifier_meltdown") and 1000 or  600
end

function modifier_artificial_sun_aura_enemy:GetModifierAura()
	return "modifier_artificial_sun_enemy"
end

function modifier_artificial_sun_aura_enemy:IsHidden()
	return true
end

function modifier_artificial_sun_aura_enemy:RemoveOnDeath()
	return true
end

function modifier_artificial_sun_aura_enemy:IsDebuff()
	return false 
end

function modifier_artificial_sun_aura_enemy:IsAura()
	return true 
end

function modifier_artificial_sun_aura_enemy:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


modifier_artificial_sun_enemy = class({})

 

function modifier_artificial_sun_enemy:IsHidden() return false end
function modifier_artificial_sun_enemy:IsDebuff() return true end
function modifier_artificial_sun_enemy:RemoveOnDeath() return true end
function modifier_artificial_sun_enemy:DeclareFunctions()
	return { 
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS ,
           }
end

 

function modifier_artificial_sun_enemy:GetModifierMagicalResistanceBonus()
	return -1*self:GetAbility():GetSpecialValueFor("mr")  
end

 

function modifier_artificial_sun_enemy:GetTexture()
    return "custom/gawain_suns_embrace"
end

 
modifier_sun_remover = class({})

 

function modifier_sun_remover:IsHidden() return true end
function modifier_sun_remover:IsDebuff() return false end
function modifier_sun_remover:RemoveOnDeath() return false end
function modifier_sun_remover:DeclareFunctions()
	return { 
        MODIFIER_EVENT_ON_RESPAWN ,
           }
end

 
function modifier_sun_remover:OnRespawn(args) 
    local caster = self:GetCaster() 
    if(caster ~= args.unit) then return end
    local ability = self:GetAbility()
    if not( not ability.Ult_sun or ability.Ult_sun:IsNull()) then
        ability.Ult_sun:RemoveSelf() 
    end
    if not( not ability.Blade_sun or ability.Blade_sun:IsNull()) then
        ability.Blade_sun:RemoveSelf() 
    end
    if not( not ability.SOG_Sun or ability.SOG_Sun:IsNull()) then
        ability.SOG_Sun:RemoveSelf() 
    end


   
end

 