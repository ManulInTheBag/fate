muramasa_forge = class({})
LinkLuaModifier("modifier_muramasa_forge_aura", "abilities/muramasa/muramasa_forge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_forge", "abilities/muramasa/muramasa_forge", LUA_MODIFIER_MOTION_NONE)
function muramasa_forge:OnSpellStart()
    local caster = self:GetCaster()
    local cast_point = self:GetCursorPosition()
    local forge_position =  cast_point

    local forge_fx = ParticleManager:CreateParticle("particles/muramasa/muramasa_forge_zone.vpcf", PATTACH_WORLDORIGIN  , nil)
    ParticleManager:SetParticleControl(forge_fx, 0, forge_position)
    ParticleManager:SetParticleControl(forge_fx, 1, Vector(1000,10,0))
    ParticleManager:SetParticleControl(forge_fx, 2, Vector(10,0,0))
    ParticleManager:SetParticleShouldCheckFoW(forge_fx, false)
    ParticleManager:SetParticleAlwaysSimulate(forge_fx)
    local forge_fx_anvil = ParticleManager:CreateParticle("particles/muramasa/muramasa_forge_anvil.vpcf", PATTACH_WORLDORIGIN  , nil)
    ParticleManager:SetParticleControl(forge_fx_anvil, 0, forge_position)
    ParticleManager:SetParticleControl(forge_fx_anvil, 2, Vector(10,0,0))
    self.forge_position = forge_position
    CreateModifierThinker(caster, self, "modifier_muramasa_forge_aura", {duration = 10}, forge_position, caster:GetTeamNumber(), false)
    if(caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1) then
        if caster:FindAbilityByName("muramasa_tsumukari_combo"):IsCooldownReady()  then
             
            caster:SwapAbilities("muramasa_tsumukari_combo", "muramasa_tsumukari_release", true, false)
    
            Timers:CreateTimer("muramasa_combo_window",{
                endTime = 3,
                callback = function()
                local index5ability = caster:GetAbilityByIndex(5):GetName()
                if index5ability == "muramasa_tsumukari_combo"  then
                     caster:SwapAbilities("muramasa_tsumukari_combo", "muramasa_tsumukari_release", false, true)
                end
                 
            end
            })
    
        end

    end


end
 


modifier_muramasa_forge_aura = modifier_muramasa_forge_aura or class({})

function modifier_muramasa_forge_aura:IsHidden() return false end
function modifier_muramasa_forge_aura:IsDebuff() return false end
function modifier_muramasa_forge_aura:IsPurgable() return false end
function modifier_muramasa_forge_aura:IsPurgeException() return false end
function modifier_muramasa_forge_aura:RemoveOnDeath() return true end
function modifier_muramasa_forge_aura:CheckState()
    local state = { [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_PROVIDES_VISION] = true, }
    return state
end
function modifier_muramasa_forge_aura:OnCreated(hTable)
end
function modifier_muramasa_forge_aura:OnRefresh(hTable)
    self:OnCreated(hTable)
end
 
function modifier_muramasa_forge_aura:GetModifierAura()
	return "modifier_muramasa_forge"
end
function modifier_muramasa_forge_aura:OnDestroy()
   
end

function modifier_muramasa_forge_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_muramasa_forge_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_muramasa_forge_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end
function modifier_muramasa_forge_aura:IsAura()
	return true 
end

function modifier_muramasa_forge_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end




modifier_muramasa_forge = class({})

function modifier_muramasa_forge:OnCreated(args)

    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    if self.caster == self.parent then
        self.soundCounter = 8
    end
    self.createdBySA = 0
    if args.createdBySA == 1 then
        self.createdBySA = 1
    end

    self:StartIntervalThink(0.25)
    self.forge = self.ability.modifier
    self.damage = self.ability:GetSpecialValueFor("damage")
    self.damage_ring = self.ability:GetSpecialValueFor("damage_ring")
    if self.parent == self.caster then
        self.swordfx = ParticleManager:CreateParticle("particles/muramasa/sword_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self.caster )
        ParticleManager:SetParticleControlEnt(self.swordfx, 1, self.caster, PATTACH_POINT_FOLLOW, "sword_base", Vector(0,0,0), true)
        ParticleManager:SetParticleControlEnt(self.swordfx, 2, self.caster, PATTACH_POINT_FOLLOW, "sword_end", Vector(0,0,0), true)
        self.swordfx2 = ParticleManager:CreateParticle("particles/muramasa/muramasa_blade.vpcf", PATTACH_ABSORIGIN_FOLLOW  , self.caster )
        ParticleManager:SetParticleControlEnt(self.swordfx2, 1, self.caster, PATTACH_POINT_FOLLOW, "sword_base", Vector(0,0,0), true)
        ParticleManager:SetParticleControlEnt(self.swordfx2, 0, self.caster, PATTACH_POINT_FOLLOW, "sword_end", Vector(0,0,0), true)
        
    end
end
  
function modifier_muramasa_forge:OnIntervalThink( )
    if not IsServer() then return end
	if self.parent:GetTeamNumber() ~=  self.caster:GetTeamNumber() then
        if ( (self.parent:GetAbsOrigin() - self.ability.forge_position):Length2D() > 900 ) then
            DoDamage(self.caster, self.parent, self.damage_ring, self.ability:GetAbilityDamageType(), 0, self.ability, false)

        else
            DoDamage(self.caster, self.parent, self.damage, self.ability:GetAbilityDamageType(), 0, self.ability, false)
        end
    end
    if self.parent:HasModifier("modifier_muramasa_no_sword") and self.createdBySA ~= 1 then 
        self.parent:RemoveModifierByName("modifier_muramasa_no_sword")
    end
    if self.parent:HasModifier("modifier_muramasa_sword_creation") and self.createdBySA ~= 1  then 
        if self.soundCounter == 10 then 
            self.parent:EmitSound("muramasa_forge")
            self.soundCounter = 0
        else
            self.soundCounter = self.soundCounter + 1
        end
        local stackcount = self.parent:GetModifierStackCount("modifier_muramasa_sword_creation", self.parent)
        if stackcount < 10 then
            self.parent:SetModifierStackCount("modifier_muramasa_sword_creation", self.parent, stackcount+1)
        end
    end 
end
  
function modifier_muramasa_forge:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
	}
end

function modifier_muramasa_forge:GetModifierMagicalResistanceBonus()
    local caster = self:GetCaster()
	return  self:GetAbility():GetSpecialValueFor("attribute_mr")  * (caster.AppreciationOfSwordsAcquired and 1 or 0) *(self.parent ==caster and 1 or 0)
end

 

function modifier_muramasa_forge:GetModifierPhysicalArmorBonus()
    local caster = self:GetCaster()
    return  self:GetAbility():GetSpecialValueFor("attribute_armor")  * (caster.AppreciationOfSwordsAcquired and 1 or 0) *(self.parent == caster and 1 or 0)
end

function modifier_muramasa_forge:GetModifierMoveSpeedBonus_Percentage()
    local caster = self:GetCaster()
    return  self:GetAbility():GetSpecialValueFor("attribute_ms")  * (caster.AppreciationOfSwordsAcquired and 1 or 0) *
     (self.parent:GetTeamNumber() ~=  self.caster:GetTeamNumber() and -1 or 1)
end


function modifier_muramasa_forge:OnDestroy( )
    if(self.swordfx ~= nil ) then
        ParticleManager:DestroyParticle(self.swordfx, true)
         ParticleManager:ReleaseParticleIndex(self.swordfx)
         ParticleManager:DestroyParticle(self.swordfx2, true)
         ParticleManager:ReleaseParticleIndex(self.swordfx2)
         self.swordfx = nil
         self.swordfx2 = nil
 end

end


function modifier_muramasa_forge:IsHidden() return false end
function modifier_muramasa_forge:IsDebuff() return false end
function modifier_muramasa_forge:RemoveOnDeath() return true end
 
 
 