muramasa_forge = class({})
LinkLuaModifier("modifier_muramasa_forge_aura", "abilities/muramasa/muramasa_forge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_forge", "abilities/muramasa/muramasa_forge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_sword_drop_forge", "abilities/muramasa/muramasa_forge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muramasa_sword_drop_forge_buff", "abilities/muramasa/muramasa_forge", LUA_MODIFIER_MOTION_NONE)
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
    Timers:CreateTimer(10, function()
        if caster.SoulSwordAcquired then
            CreateModifierThinker(caster, self, "modifier_muramasa_sword_drop_forge", {duration = 6, Duration = 6, radius = 175,
            x = self.forge_position.x, y = self.forge_position.y},  Vector(self.forge_position.x, self.forge_position.y), caster:GetTeamNumber(), false)
        end
    
    end)
    CreateModifierThinker(caster, self, "modifier_muramasa_forge_aura", {duration = 10, x = forge_position.x, y = forge_position.y}, forge_position, caster:GetTeamNumber(), false)
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
    self.damage = self.ability:GetSpecialValueFor("damage") + self.caster:GetLevel()*0.5
    self.damage_ring = self.ability:GetSpecialValueFor("damage_ring")+ self.caster:GetLevel()*1.5
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
 
 
modifier_muramasa_sword_drop_forge = modifier_muramasa_sword_drop_forge or class({})

function modifier_muramasa_sword_drop_forge:IsHidden() return false end
function modifier_muramasa_sword_drop_forge:IsDebuff() return false end
function modifier_muramasa_sword_drop_forge:IsPurgable() return false end
function modifier_muramasa_sword_drop_forge:IsPurgeException() return false end
function modifier_muramasa_sword_drop_forge:RemoveOnDeath() return true end
function modifier_muramasa_sword_drop_forge:CheckState()
    local state = { [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true, }
    return state
end
function modifier_muramasa_sword_drop_forge:OnCreated(hTable)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.duration = hTable.duration
    self.radius = hTable.radius
    self.start_pos = Vector(hTable.x, hTable.y, 0)
    if IsServer() then
        self:StartIntervalThink(FrameTime())
        if not self.swordfx then
            local sword_fx = "particles/muramasa/muramasa_sword_drop.vpcf"

            self.swordfx =   ParticleManager:CreateParticle( sword_fx, PATTACH_ABSORIGIN_FOLLOW, self.parent )
                            ParticleManager:SetParticleControl( self.swordfx, 0, self.start_pos  )
                            ParticleManager:SetParticleControl( self.swordfx, 1, Vector(self.radius,0,0) )
                            ParticleManager:SetParticleControl( self.swordfx, 2, Vector(6,0,0) )

            self:AddParticle(self.swordfx, true, false, -1, false, false)
        
            --EmitSoundOn("Archer.Kab.Throw."..RandomInt(1, 1), self.parent)
        end
    end
end
function modifier_muramasa_sword_drop_forge:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_muramasa_sword_drop_forge:OnIntervalThink()
    if IsServer() and IsNotNull(self.parent) then
        local allies = FindUnitsInRadius(  self.caster:GetTeamNumber(), 
                                            self.parent:GetAbsOrigin(), 
                                            nil, 
                                            self.radius, 
                                            DOTA_UNIT_TARGET_TEAM_FRIENDLY , 
                                            DOTA_UNIT_TARGET_HERO, 
                                            DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 
                                            FIND_CLOSEST, 
                                            false)
        if allies[1] ~= nil then 
            allies[1]:AddNewModifier(self.caster, self.ability, "modifier_muramasa_sword_drop_forge_buff",{duration = self.duration })   
            self:Destroy()
        end
    end
end


function modifier_muramasa_sword_drop_forge:OnDestroy()

end
 
 

modifier_muramasa_sword_drop_forge_buff = class({})

function modifier_muramasa_sword_drop_forge_buff:OnCreated(args)

    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.BurnDamage = 20
    self.radius = 550
    self:StartIntervalThink(0.2)
end
  
  
function modifier_muramasa_sword_drop_forge_buff:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
	}
end



function modifier_muramasa_sword_drop_forge_buff:GetModifierMoveSpeedBonus_Percentage()
    local caster = self:GetCaster()
    return  self:GetAbility():GetSpecialValueFor("attribute_ms")
end

function modifier_muramasa_sword_drop_forge_buff:OnIntervalThink()	
    local caster = self:GetCaster()

    if caster ~= nil then
        local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetOrigin(), nil, self.radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
        for k,v in pairs(targets) do
            DoDamage(caster, v, self.BurnDamage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
        end
    end
end





function modifier_muramasa_sword_drop_forge_buff:IsHidden()
	return false
end

function modifier_muramasa_sword_drop_forge_buff:IsPurgable()
	return false
end

function modifier_muramasa_sword_drop_forge_buff:IsPurgeException()
	return false
end

function modifier_muramasa_sword_drop_forge_buff:IsDebuff()
	return false
end

function modifier_muramasa_sword_drop_forge_buff:RemoveOnDeath()
	return true
end

function modifier_muramasa_sword_drop_forge_buff:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_muramasa_sword_drop_forge_buff:GetEffectName()
	 return "particles/gawain/gawain_heat.vpcf"
end

function modifier_muramasa_sword_drop_forge_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
