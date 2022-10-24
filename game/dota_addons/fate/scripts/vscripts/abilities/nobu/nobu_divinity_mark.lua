nobu_divinity_mark = class({})
LinkLuaModifier("modifier_nobu_divinity_mark", "abilities/nobu/nobu_divinity_mark", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nobu_divinity_mark_activated", "abilities/nobu/nobu_divinity_mark", LUA_MODIFIER_MOTION_NONE) 
 
function nobu_divinity_mark:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    hTarget:EmitSound("nobu_divinity_mark_cast")
    hTarget:AddNewModifier(hCaster, self, "modifier_nobu_divinity_mark", {duration = self:GetSpecialValueFor("duration")} )
end

 

modifier_nobu_divinity_mark = class({})
 

function modifier_nobu_divinity_mark:IsHidden()	return false end
function modifier_nobu_divinity_mark:RemoveOnDeath()return true end 
function modifier_nobu_divinity_mark:IsDebuff() 	return true end



 
function modifier_nobu_divinity_mark:OnCreated()
if(not IsServer()) then return end
local caster = self:GetCaster()
self.stacks = 0
self.fx = ParticleManager:CreateParticle("particles/nobu/nobu_divinity_mark.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
ParticleManager:SetParticleControl(self.fx , 1, Vector(self.stacks,0,0) ) 
 
end

 
function modifier_nobu_divinity_mark:OnDestroy()
    if(not IsServer()) then return end
    ParticleManager:DestroyParticle(self.fx, true)
	ParticleManager:ReleaseParticleIndex(self.fx)

end

function modifier_nobu_divinity_mark:OnTakeDamage(args)
    local parent =self:GetParent()
    local caster = self:GetCaster()
    if(  args.attacker == caster  and args.damage_category == 0 )then
        if(args.inflictor:GetName() ~= "nobu_guns" and args.inflictor:GetName() ~= "nobu_shot" and args.inflictor:GetName() ~= "nobu_3000" and args.inflictor:GetName() ~= "nobu_double_shots" ) then return end
        self.stacks = self.stacks + 1
        ParticleManager:DestroyParticle(self.fx, true)
        ParticleManager:ReleaseParticleIndex(self.fx)
        self.fx = ParticleManager:CreateParticle("particles/nobu/nobu_divinity_mark.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(self.fx , 1, Vector(self.stacks,0,0) ) 

    end
    if(self.stacks == 10) then
        parent:AddNewModifier(caster, self:GetAbility(), "modifier_nobu_divinity_mark_activated", {duration = self:GetAbility():GetSpecialValueFor("activated_duration")} )
        parent:EmitSound("nobu_divinity_mark_activated")
        self:Destroy()
    end
end
 
 

modifier_nobu_divinity_mark_activated = class({})
 
function modifier_nobu_divinity_mark_activated:OnCreated()
    if(not IsServer()) then return end
    self.fx = ParticleManager:CreateParticle("particles/nobu/nobu_divinity_mark_activated.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
 
end    
     
 function modifier_nobu_divinity_mark_activated:OnDestroy()
        if(not IsServer()) then return end
        ParticleManager:DestroyParticle(self.fx, true)
        ParticleManager:ReleaseParticleIndex(self.fx)
    
end

function modifier_nobu_divinity_mark_activated:IsHidden()	return false end
function modifier_nobu_divinity_mark_activated:RemoveOnDeath()return true end 
function modifier_nobu_divinity_mark_activated:IsDebuff() 	return true end

function modifier_nobu_divinity_mark_activated:DeclareFunctions()
    return {  MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE     }
end


 
function modifier_nobu_divinity_mark_activated:GetModifierPhysicalArmorBase_Percentage ()
   	    return  0
end
 
 

  