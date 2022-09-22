modifier_sex_scroll = class({})

--LinkLuaModifier("modifier_sex_scroll_slow","items/modifiers/modifier_sex_scroll_slow.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_sex_scroll:OnCreated(args)
    local hTarget = self:GetParent()

    self.slowPerc = args.slowPerc
    self.slowDur = args.slowDur
    self.slowPortion = false
    self.remainingSlow = args.slowDur

    self.state = {
        [MODIFIER_STATE_ROOTED] = true,
    } 

    self:StartIntervalThink(args.rootDur)
end

function modifier_sex_scroll:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_sex_scroll:GetModifierMoveSpeedBonus_Percentage()
    return self.slowPerc
end

function modifier_sex_scroll:CheckState()   
    return self.state
end

function modifier_sex_scroll:OnIntervalThink()
    if not self.slowPortion then
        self:StartIntervalThink(0.1)
        self.state = {}
        self.slowPortion = true
    end

    if self:GetParent():GetName() == "npc_dota_hero_sven" then
        self:GetParent():EmitSound("DOTA_Item.LinkensSphere.Activate")
        ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_ABSORIGIN, self:GetParent())
        self:Destroy()
    end

    if self.remainingSlow > 0 then
        
        self.slowPerc = self.slowPerc + (100.0 / 3.0 * 0.1)
        self.slowDur = self.slowDur - 0.1
    else
        self:Destroy()
    end
end

--[[function modifier_sex_scroll:OnDestroy()
    if self:GetParent():GetName() == "npc_dota_hero_sven" then
        self:GetParent():EmitSound("DOTA_Item.LinkensSphere.Activate")
        ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_ABSORIGIN, self:GetParent())
    else
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_sex_scroll_slow", {duration = 3.0})        
    end
end]]

-----------------------------------------------------------------------------------
function modifier_sex_scroll:GetEffectName()
    return "particles/items_fx/diffusal_slow.vpcf"
end

function modifier_sex_scroll:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sex_scroll:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_sex_scroll:IsPurgable()
    return false
end

function modifier_sex_scroll:IsDebuff()
    return true
end


function modifier_sex_scroll:RemoveOnDeath()
    return true
end

function modifier_sex_scroll:GetTexture()
    return "custom/s_scroll"
end
-----------------------------------------------------------------------------------
