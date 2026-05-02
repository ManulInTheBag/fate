ozy_anchor_passive = class({})

LinkLuaModifier("modifier_ozy_anchor_passive", "abilities/ozy/ozy_anchor_passive", LUA_MODIFIER_MOTION_NONE)
 

 

function ozy_anchor_passive:GetIntrinsicModifierName()
    return "modifier_ozy_anchor_passive"
end

modifier_ozy_anchor_passive = class({})

 

function modifier_ozy_anchor_passive:IsHidden() return true end
function modifier_ozy_anchor_passive:IsDebuff() return false end
function modifier_ozy_anchor_passive:RemoveOnDeath() return true end
function modifier_ozy_anchor_passive:DeclareFunctions()
	return { 
         
           }
end

 
function modifier_ozy_anchor_passive:OnCreated(args) 
    -- self.sun = self:GetParent()
    -- self.sunFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_artificial_sun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.sun )
	-- ParticleManager:SetParticleControl(  self.sunFx, 0, self.sun:GetAbsOrigin())
    -- ParticleManager:SetParticleControl(  self.sunFx, 1, Vector(100,0,0))
end

 
function modifier_ozy_anchor_passive:OnDestroy(args)
    -- ParticleManager:DestroyParticle(  self.sunFx, false )
    -- ParticleManager:ReleaseParticleIndex(  self.sunFx)
end

function modifier_ozy_anchor_passive:Meltdown() 

end


function modifier_ozy_anchor_passive:CheckState()
    local state = { 
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_FLYING] = false,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
                }
    return state
end

 