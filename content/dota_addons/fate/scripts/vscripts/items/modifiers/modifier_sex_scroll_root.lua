modifier_sex_scroll_root = class({})

--LinkLuaModifier("modifier_sex_scroll_slow","items/modifiers/modifier_sex_scroll_slow.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_sex_scroll_root:OnCreated(args)
    local hTarget = self:GetParent()

    self.state = {
        [MODIFIER_STATE_ROOTED] = true,
    } 

    --[[if IsServer() then 
        if self:GetParent():GetName() == "npc_dota_hero_sven" then
            self:GetParent():EmitSound("DOTA_Item.LinkensSphere.Activate")
            ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_ABSORIGIN, self:GetParent())   
        else
            self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_sex_scroll_slow", {duration = 4.0})
        end
    end]]
end

function modifier_sex_scroll_root:CheckState()   
    return self.state
end

--function modifier_sex_scroll_root:OnDestroy()
    
--end

-----------------------------------------------------------------------------------
function modifier_sex_scroll_root:GetEffectName()
    return "particles/items_fx/diffusal_slow.vpcf"
end

function modifier_sex_scroll_root:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sex_scroll_root:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_sex_scroll_root:IsPurgable()
    return false
end

function modifier_sex_scroll_root:IsDebuff()
    return true
end


function modifier_sex_scroll_root:RemoveOnDeath()
    return true
end

function modifier_sex_scroll_root:GetTexture()
    return "custom/s_scroll"
end
-----------------------------------------------------------------------------------
