gawain_sun_passive = class({})

LinkLuaModifier("modifier_gawain_sun_passive", "abilities/gawain/gawain_sun_passive", LUA_MODIFIER_MOTION_NONE)
 

 

function gawain_sun_passive:GetIntrinsicModifierName()
    return "modifier_gawain_sun_passive"
end

modifier_gawain_sun_passive = class({})

 

function modifier_gawain_sun_passive:IsHidden() return true end
function modifier_gawain_sun_passive:IsDebuff() return false end
function modifier_gawain_sun_passive:RemoveOnDeath() return true end
function modifier_gawain_sun_passive:DeclareFunctions()
	return { 
         
           }
end

 
function modifier_gawain_sun_passive:OnCreated(args) 
    self.sun = self:GetParent()
    self.sunFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_artificial_sun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.sun )
	ParticleManager:SetParticleControl(  self.sunFx, 0, self.sun:GetAbsOrigin())
    ParticleManager:SetParticleControl(  self.sunFx, 1, Vector(100,0,0))
end

 
function modifier_gawain_sun_passive:OnDestroy(args)
    print("iamzuzup")
    ParticleManager:DestroyParticle(  self.sunFx, false )
    ParticleManager:ReleaseParticleIndex(  self.sunFx)
end

function modifier_gawain_sun_passive:Meltdown() 
    ParticleManager:DestroyParticle(  self.sunFx, false )
    ParticleManager:ReleaseParticleIndex(  self.sunFx)
    self.sunFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_artificial_sun_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.sun )
	ParticleManager:SetParticleControl(  self.sunFx, 0, self.sun:GetAbsOrigin())
    ParticleManager:SetParticleControl(  self.sunFx, 1, Vector(170,0,0))
end


function modifier_gawain_sun_passive:CheckState()
    local state = { 
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_FLYING] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
                }
    return state
end

 