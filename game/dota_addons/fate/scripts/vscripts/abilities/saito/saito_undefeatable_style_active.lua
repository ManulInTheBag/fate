 

saito_undefeatable_style_active = class({})
 
 
function saito_undefeatable_style_active:GetAOERadius()
    return self:GetSpecialValueFor("range")
end

 


function saito_undefeatable_style_active:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")
	local stun_duration = self:GetSpecialValueFor("stun_duration")

    self.cast = ParticleManager:CreateParticle("particles/saito/saito_combo_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    Timers:CreateTimer(self:GetCastPoint(), function()
        ParticleManager:DestroyParticle(self.cast, false)
        ParticleManager:ReleaseParticleIndex(self.cast)
    
    
    end)
 
    local point = caster:GetAbsOrigin()  
 
 
 

    local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do            
        DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
        v:AddNewModifier(caster, self, "modifier_stunned", {Duration = stun_duration})     
        v:EmitSound("saito_combo_kick")
        local pushback = Physics:Unit(v)
					v:PreventDI()
					v:SetPhysicsFriction(0)
					v:SetPhysicsVelocity((v:GetAbsOrigin() -  caster:GetAbsOrigin()):Normalized() * 2000)
					v:SetNavCollisionType(PHYSICS_NAV_NOTHING)
					v:FollowNavMesh(false)

					Timers:CreateTimer(0.15, function()  
						v:PreventDI(false)
						v:SetPhysicsVelocity(Vector(0,0,0))
						v:OnPhysicsFrame(nil)
						FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
						return 
					end)
    end 

   
end

 