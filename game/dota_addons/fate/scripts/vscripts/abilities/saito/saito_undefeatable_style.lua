LinkLuaModifier("modifier_saito_combo", "abilities/saito/saito_undefeatable_style", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_combo_cd", "abilities/saito/saito_undefeatable_style", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saito_combo_spellblock", "abilities/saito/saito_undefeatable_style", LUA_MODIFIER_MOTION_NONE)

saito_undefeatable_style = class({})

function saito_undefeatable_style:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    self.cast = ParticleManager:CreateParticle("particles/saito/saito_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    caster:EmitSound("saito_combo")
    Timers:CreateTimer(self:GetCastPoint(), function()
        ParticleManager:DestroyParticle(self.cast, true)
        ParticleManager:ReleaseParticleIndex(self.cast)
    
    
    end)

return true
end

function saito_undefeatable_style:OnFateSpellBlocked()
    local caster = self:GetCaster()
    --caster:SetAbsOrigin(caster:GetAbsOrigin()+Vector(math.random(-30,30),math.random(-30,30),0))
end


function saito_undefeatable_style:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
 
    self.fx = ParticleManager:CreateParticle("particles/saito/saito_combo_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

    caster:EmitSound("saito_combo_phrase")

    local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(ability:GetCooldown(1))
    caster:FindAbilityByName("saito_hajime_fdb"):StartCooldown(caster:FindAbilityByName("saito_hajime_fdb"):GetCooldown(caster:FindAbilityByName("saito_hajime_fdb"):GetLevel()))
    caster:RemoveModifierByName( "modifier_saito_fdb_vision")
    caster:AddNewModifier(caster, ability, "modifier_saito_combo",{duration = self:GetSpecialValueFor("duration") })
    caster:AddNewModifier(caster, ability, "modifier_saito_combo_cd",{duration = ability:GetCooldown(1) })
 
  
end



modifier_saito_combo_cd = class({})

function modifier_saito_combo_cd:IsHidden()	return false end
function modifier_saito_combo_cd:RemoveOnDeath()return false end 
function modifier_saito_combo_cd:IsDebuff() 	return true end

    
modifier_saito_combo = class({})

function modifier_saito_combo:OnTakeDamage(args)
    local caster =self:GetParent()
    if(  args.attacker ~= caster) then return end
    if(args.damage_category == 0) then
        local ability = self:GetParent():FindAbilityByName("saito_undefeatable_style")
      
        print(caster:GetMana()+ability:GetSpecialValueFor("mana_refund")) 
        caster:SetMana(caster:GetMana()+ability:GetSpecialValueFor("mana_refund"))
        if(caster.UndefeatableSwordsmanAcquired)then
            caster:SetHealth(caster:GetHealth()+ability:GetSpecialValueFor("health_refund"))
        end

    end


end

function modifier_saito_combo:OnCreated()    
    if IsServer() then	 
        local caster = self:GetCaster()
        self.particleid = self:GetAbility().fx
        caster:SwapAbilities("saito_undefeatable_style", "saito_undefeatable_style_active", false, true)
        self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("spellblock_cd"))
    end

end
 
    
  
function modifier_saito_combo:OnDestroy()   
    if IsServer() then 	 
        local caster = self:GetCaster()
        caster:SwapAbilities("saito_hajime_fdb", "saito_undefeatable_style_active", true, false)
        ParticleManager:DestroyParticle(self.particleid, false)
        ParticleManager:ReleaseParticleIndex(self.particleid)
    end
end



function modifier_saito_combo:OnIntervalThink()
    if IsServer() then
        local caster = self:GetAbility():GetCaster()
        caster:AddNewModifier(caster, self:GetAbility(), "modifier_saito_combo_spellblock", { duration = self:GetAbility():GetSpecialValueFor("spellblock_cd") -0.033} )
    end
end

function modifier_saito_combo:DeclareFunctions()
	return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
 
	}
end

function modifier_saito_combo:GetModifierMagicalResistanceBonus()
	return  self:GetAbility():GetSpecialValueFor("magic_res") 
end

function modifier_saito_combo:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_saito_combo:GetTexture()
	return "custom/saito/saito_undefeatable_style"
end

function modifier_saito_combo:IsHidden()	return false end
function modifier_saito_combo:RemoveOnDeath()return true end 
function modifier_saito_combo:IsDebuff() 	return false end


modifier_saito_combo_spellblock = class({})

 
function modifier_saito_combo:GetTexture()
	return "custom/saito/saito_undefeatable_style"
end

function modifier_saito_combo:IsHidden()	return false end
function modifier_saito_combo:RemoveOnDeath()return true end 
function modifier_saito_combo:IsDebuff() 	return false end