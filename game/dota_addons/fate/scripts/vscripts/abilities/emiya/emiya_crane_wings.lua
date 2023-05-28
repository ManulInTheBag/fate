emiya_crane_wings  = emiya_crane_wings or class({})
LinkLuaModifier("emiya_overedge_modifier", "abilities/emiya/emiya_crane_wings", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_emiya_dash_crane", "abilities/emiya/emiya_crane_wings", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_emiya_self_control","abilities/emiya/emiya_double_slash", LUA_MODIFIER_MOTION_NONE)



function emiya_crane_wings:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self

    if caster:FindAbilityByName("emiya_caladbolg"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_caladbolg"):SetLevel(self:GetLevel())
    end
    if caster:FindAbilityByName("emiya_overedge_circle"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_overedge_circle"):SetLevel(self:GetLevel())
    end
end


function emiya_crane_wings:GetManaCost()
    local caster = self:GetCaster()
    local cost = 400
    if caster:HasModifier("modifier_archer_kab_overedge_stacks") then
        cost = 400 - caster:GetModifierStackCount("modifier_archer_kab_overedge_stacks", caster) * 50
    end
    return cost

end
 


function emiya_crane_wings:OnSpellStart()
    local caster = self:GetCaster()
	--giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 1)
	self.htarget = self:GetCursorTarget() 
    local distance = (caster:GetAbsOrigin() - self.htarget:GetAbsOrigin()):Length2D()
    if(distance > 400 ) then
         self:RefundManaCost()
         self:EndCooldown()
         return
    end
    if caster.IsOveredgeAcquired then   
        caster:FindAbilityByName("emiya_double_slash"):EndCooldown()
    end
    if(caster:HasModifier("emiya_overedge_modifier")) then
        caster:RemoveModifierByNameAndCaster("emiya_overedge_modifier",caster)
    end
    Timers:CreateTimer("emiya_crane_wings_sword_dissapear", {
		endTime = 0.15,
		callback = function()
        if caster.IsOveredgeAcquired then   
		    caster:SetBodygroup(0,1)
        end
	end})
    Timers:CreateTimer("emiya_crane_wings_sword_reappear_overedge", {
		endTime = 0.4,
		callback = function()
        if caster.IsOveredgeAcquired then    
            caster:AddNewModifier(caster, self, "emiya_overedge_modifier", {duration = 10})  
        else
            caster:AddNewModifier(caster, self, "emiya_overedge_modifier", {duration = 1}) 
        end
	end})
    local enemypos = self.htarget:GetAbsOrigin()
    enemypos = enemypos + caster:GetForwardVector()*100
    local push_distance = self:GetSpecialValueFor("distance") - distance
    local pull_center = caster:GetForwardVector() * push_distance + self.htarget:GetAbsOrigin()
    local kb_ability = caster:FindAbilityByName("emiya_kanshou_byakuya")
    local vLeft = -caster:GetRightVector()
    local damage = self:GetSpecialValueFor("damage")
    giveUnitDataDrivenModifier(caster,  self.htarget, "stunned", self:GetSpecialValueFor("stun_duration"))
    if not IsKnockbackImmune(self.htarget) then
        self.htarget:EmitSound("muramasa_throw_impact")
        local casterfacing = caster:GetForwardVector()
        local pushTarget = Physics:Unit(self.htarget)
        local casterOrigin = caster:GetAbsOrigin()
        local initialUnitOrigin = self.htarget:GetAbsOrigin()
        self.htarget:PreventDI()
        self.htarget:SetPhysicsFriction(0)
        self.htarget:SetPhysicsVelocity(casterfacing:Normalized() * push_distance*2)
        self.htarget:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
        self.htarget:OnPhysicsFrame(function(unit) 
            local unitOrigin = unit:GetAbsOrigin()
            local diff = unitOrigin - initialUnitOrigin
            local n_diff = diff:Normalized()
            unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
            if diff:Length() > push_distance then
                unit:PreventDI(false)
                unit:SetPhysicsVelocity(Vector(0,0,0))
                unit:OnPhysicsFrame(nil)
                FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
            end
        end)	
        self.htarget:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
            unit:SetBounceMultiplier(0)
            unit:PreventDI(false)
            unit:SetPhysicsVelocity(Vector(0,0,0))
            giveUnitDataDrivenModifier(caster,  self.htarget, "stunned", self:GetSpecialValueFor("stun_duration"))
            self.htarget:EmitSound("Hero_EarthShaker.Fissure")
        end)
    end
                         
    local sword_count = 0
    
    
    -------FOR SA------
    if caster:HasModifier("modifier_archer_kab_overedge_stacks") then
        sword_count = caster:GetModifierStackCount("modifier_archer_kab_overedge_stacks", caster)
    end

  
    -------------------
    Timers:CreateTimer(0.2, function() 
        if(sword_count > 0) then
            kb_ability:ThrowDagger(caster,self,-1,150,enemypos.x,enemypos.y,enemypos.z,caster:GetAbsOrigin() +vLeft*120 ,0.5)
        end
        if(sword_count > 1) then
            kb_ability:ThrowDagger(caster,self,1,150,enemypos.x,enemypos.y,enemypos.z,caster:GetAbsOrigin()+vLeft*-120, 0.5)
        end
        if(sword_count > 2) then
            kb_ability:ThrowDagger(caster,self,-1,100,enemypos.x,enemypos.y,enemypos.z,caster:GetAbsOrigin() +vLeft*120 ,0.55)
        end
        if(sword_count > 3) then
            kb_ability:ThrowDagger(caster,self,1,100,enemypos.x,enemypos.y,enemypos.z,caster:GetAbsOrigin() +vLeft*-120 ,0.55)
        end
        if(sword_count > 4) then
            kb_ability:ThrowDagger(caster,self,-1,400,enemypos.x,enemypos.y,enemypos.z,caster:GetAbsOrigin() +vLeft*120 ,0.6)
        end
        if(sword_count > 5) then
            kb_ability:ThrowDagger(caster,self,1,400,enemypos.x,enemypos.y,enemypos.z,caster:GetAbsOrigin() +vLeft*-120 ,0.6)
        end
    end)
    Timers:CreateTimer(0.4, function() 

        caster:SetAbsOrigin(caster:GetAbsOrigin() + caster:GetForwardVector()*70)
        caster:AddNewModifier(caster, self, "modifier_emiya_dash_crane", {duration = 0.3})
        
        if caster.IsOveredgeAcquired then    
            StartAnimation(caster, {duration= 0.3 , activity=ACT_DOTA_RAZE_3, rate= 1})
        else
            StartAnimation(caster, {duration= 0.3 , activity=ACT_DOTA_LIFESTEALER_RAGE, rate= 1})
        end
    
    end)
   
    Timers:CreateTimer(0.7, function() 
    
        StartAnimation(caster, {duration= 0.65 , activity=ACT_DOTA_RAZE_2, rate= 1.5})
        caster:AddNewModifier(caster, self, "modifier_emiya_self_control", {duration = 0.65, damage = damage, radius = 450,interval = 0.025})
    
    end)
    

end


emiya_overedge_modifier = emiya_overedge_modifier or class({})

function emiya_overedge_modifier:IsHidden() return false end
function emiya_overedge_modifier:IsDebuff() return false end
function emiya_overedge_modifier:IsPurgable() return false end
function emiya_overedge_modifier:RemoveOnDeath() return true end


function emiya_overedge_modifier:DeclareFunctions()
    local hFunc =   {
                        --MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
                        --MODIFIER_EVENT_ON_ATTACK_LANDED
						   
                    }
    return hFunc
end

function emiya_overedge_modifier:OnCreated() 
    local caster = self:GetCaster()
    if IsServer() then
        caster:SetBodygroup(0,3)
        caster:SwapAbilities("emiya_kanshou_byakuya", "emiya_overedge_circle", false, true)
    end
    self.swordfx_left = ParticleManager:CreateParticle("particles/emiya/emiya_left_sword_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControlEnt(self.swordfx_left, 0, caster, PATTACH_POINT_FOLLOW, "sword_left", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.swordfx_left, 1, caster, PATTACH_POINT_FOLLOW, "sword_left_end_overedge", Vector(0,0,0), true)
    self.swordfx_right = ParticleManager:CreateParticle("particles/emiya/emiya_right_sword_glow.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControlEnt(self.swordfx_right, 0, caster, PATTACH_POINT_FOLLOW, "sword_right", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.swordfx_right, 1, caster, PATTACH_POINT_FOLLOW, "sword_right_end_overedge", Vector(0,0,0), true)

end

function emiya_overedge_modifier:OnDestroy() 
    local caster = self:GetCaster()
    if IsServer() then
        caster:SwapAbilities("emiya_kanshou_byakuya", "emiya_overedge_circle", true, false)
    end

    ----return to normal attack range in meele stance
    local swapAbil =caster:FindAbilityByName("emiya_weapon_swap")
    swapAbil.iAttack_range = swapAbil:GetSpecialValueFor("melee_range")
    -----------

    ParticleManager:DestroyParticle( self.swordfx_left, true)
    ParticleManager:ReleaseParticleIndex( self.swordfx_left)
    ParticleManager:DestroyParticle( self.swordfx_right, true)
    ParticleManager:ReleaseParticleIndex( self.swordfx_right)
    if(caster.overedgeFastFix ~= 1) then
        if IsServer() then
            caster:SetBodygroup(0,0)
        end
    else
        caster.overedgeFastFix = 0
    end
end
 

------ i just use modified nero dashes everywhere because lazy to think + want controllable dash 
modifier_emiya_dash_crane = class({})
function modifier_emiya_dash_crane:IsHidden() return true end
function modifier_emiya_dash_crane:IsDebuff() return false end
function modifier_emiya_dash_crane:IsPurgable() return false end
function modifier_emiya_dash_crane:IsPurgeException() return false end
function modifier_emiya_dash_crane:RemoveOnDeath() return true end
function modifier_emiya_dash_crane:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_emiya_dash_crane:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_emiya_dash_crane:CheckState()
    local state =   { 
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
						[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                    }
    return state
end

function modifier_emiya_dash_crane:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    EmitSoundOn("nero_dash", self.parent)

    if IsServer() then
        self.speed          = 900
        self.distance       = 300
        self.point          = self.ability:GetCursorPosition() + RandomVector(1)
        self.direction      = self.parent:GetForwardVector():Normalized()
        self.direction.z    = 0
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance
        self.parent:SetForwardVector(self.direction)
        self:StartIntervalThink(FrameTime())

    end
end
function modifier_emiya_dash_crane:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_emiya_dash_crane:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_emiya_dash_crane:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        if self.distance >= 0 then
        	--self.direction = self.parent:GetForwardVector()
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()
            local next_pos = parent_pos + self.direction * units_per_dt
            local distance_will = self.distance - units_per_dt
            self.parent:SetOrigin(GetGroundPosition(next_pos, self.parent))
            self.distance = self.distance - units_per_dt
        else
            self:Destroy()
        end
    end
end
function modifier_emiya_dash_crane:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_emiya_dash_crane:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end

 