emiya_kanshou_byakuya  = emiya_kanshou_byakuya or class({})

 ---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_archer_kab", "abilities/emiya/emiya_kanshou_byakuya", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_archer_kab_overedge_stacks", "abilities/emiya/emiya_kanshou_byakuya", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_archer_kab_passive", "abilities/emiya/emiya_kanshou_byakuya", LUA_MODIFIER_MOTION_NONE)


function emiya_kanshou_byakuya:GetIntrinsicModifierName()
    return "modifier_archer_kab_passive"
end

modifier_archer_kab_passive = modifier_archer_kab_passive or class({})
modifier_archer_kab_overedge_stacks= modifier_archer_kab_overedge_stacks or class({})

function modifier_archer_kab_overedge_stacks:IsHidden() return false end
function modifier_archer_kab_overedge_stacks:IsDebuff() return false end
function modifier_archer_kab_overedge_stacks:IsPurgable() return false end
function modifier_archer_kab_overedge_stacks:RemoveOnDeath() return true end



function modifier_archer_kab_passive:IsHidden() return true end
function modifier_archer_kab_passive:IsDebuff() return false end
function modifier_archer_kab_passive:IsPurgable() return false end
function modifier_archer_kab_passive:RemoveOnDeath() return false end
function modifier_archer_kab_passive:GetAttributes()                                                        return MODIFIER_ATTRIBUTE_PERMANENT  end
function modifier_archer_kab_passive:GetPriority()                                                          return MODIFIER_PRIORITY_ULTRA end

function modifier_archer_kab_passive:DeclareFunctions()
    local hFunc =   {
                        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
                        MODIFIER_EVENT_ON_ATTACK_LANDED
						   
                    }
    return hFunc
end

function modifier_archer_kab_passive:GetActivityTranslationModifiers(keys)
    return self.curActivity
end

function modifier_archer_kab_passive:OnCreated()
    self.chance = self:GetAbility():GetSpecialValueFor("double_attack_chance")
    self.infiniteloopfix = 0  
    self:AttackRoll()
end

function modifier_archer_kab_passive:AttackRoll()
    if(math.random(1,100) > self.chance) then
        self.curActivity = "double"
    else
        self.curActivity = "single"
    end

end

function modifier_archer_kab_passive:OnAttackLanded(args)	
    if args.attacker ~= self:GetParent() or self:GetParent():GetAttackCapability() ~= 1 then 
        return 
    end
    local target = args.target
    local caster = self:GetParent()
    if self.curActivity == "double" and self.infiniteloopfix == 0 then
            Timers:CreateTimer(0.1, function()
                self.infiniteloopfix = 1
                caster:PerformAttack(target, true, true, true, true, false, false, false)
                    Timers:CreateTimer(0.05, function()
                    self.infiniteloopfix = 0
                end)
        end)
        
    end	
    self:AttackRoll()
end



function emiya_kanshou_byakuya:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	
	Timers:CreateTimer("emiya_kb_sword_model", {
		endTime = 0.18,
		callback = function()
		caster:SetBodygroup(0,1)
	end})
	Timers:CreateTimer("emiya_kb_sword_model_reappear", {
		endTime = 0.3,
		callback = function()
		caster:SetBodygroup(0,0)
	end})
 
return
end


function emiya_kanshou_byakuya:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    if caster:FindAbilityByName("emiya_arrows"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_arrows"):SetLevel(self:GetLevel())
    end
 
end


function emiya_kanshou_byakuya:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	caster:SetBodygroup(0,0)
	Timers:RemoveTimer("emiya_kb_sword_model")
	Timers:RemoveTimer("emiya_kb_sword_model_reappear")
end


function emiya_kanshou_byakuya:OnSpellStart()
	local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    self.vDirection = GetDirection(point, caster)
    local vLeft = -caster:GetRightVector()
    local speed = 1700
    local damage = self:GetSpecialValueFor("damage")
    local sound = math.random(1,10)

	if sound < 5 then
		caster:EmitSound("emiya_kanshou_byakuya_" .. math.random(1,2))
	end
    if IsNotNull(hTarget)
        and hTarget:TriggerSpellAbsorb(self) then
        return nil
    end

 
    CreateModifierThinker(caster, self, "modifier_archer_kab", { damage = damage, vector_side = -1, spread = 150, initxend = point.x, inityend = point.y,initzend = point.z}, caster:GetAbsOrigin() + self.vDirection * 100 + vLeft*75, caster:GetTeamNumber(), false)
    CreateModifierThinker(caster, self, "modifier_archer_kab", { damage = damage, vector_side = 1, spread = 150, initxend = point.x, inityend = point.y,initzend = point.z}, caster:GetAbsOrigin() + self.vDirection * 100 + vLeft*-50, caster:GetTeamNumber(), false)


	

	 
end

function emiya_kanshou_byakuya:ThrowDagger(caster, ability,  vector_side, spread, initxend, inityend, initzend, startpos, duration )
    local damage = self:GetSpecialValueFor("damage")
    CreateModifierThinker(caster, ability, "modifier_archer_kab", { damage = damage, vector_side = vector_side, spread = spread, initxend = initxend, inityend = inityend,initzend = initzend, duration = duration}, startpos, caster:GetTeamNumber(), false)


end

modifier_archer_kab = modifier_archer_kab or class({})

function modifier_archer_kab:IsHidden() return false end
function modifier_archer_kab:IsDebuff() return false end
function modifier_archer_kab:IsPurgable() return false end
function modifier_archer_kab:IsPurgeException() return false end
function modifier_archer_kab:RemoveOnDeath() return true end
function modifier_archer_kab:CheckState()
    local state = { [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_PROVIDES_VISION] = true, }
    return state
end
function modifier_archer_kab:OnCreated(hTable)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
   
    self.hit_radius = 100

   

    self.HittedTargets = {}

    if IsServer() then
        self.caster:EmitSound("Hero_Luna.Attack")
        self.fw = self.caster:GetForwardVector()
        --self.rw = self.caster:GetRightVector()
        --self.speed     = hTable.speed
        self.damage    = hTable.damage
        self.spreadbase = hTable.spread
        self.vector_side    = hTable.vector_side
        self.forward_fly    = true
        self.latch_offset   = 50

        self.point = Vector(hTable.initxend, hTable.inityend, hTable.initzend)
        self.start_pos      = self.parent:GetAbsOrigin()

        self.fly_distance     = (self.point - self.start_pos):Length2D()
        
        if(self.fly_distance < 500) then
            self.fly_distance = 500
            self.point = self.caster:GetAbsOrigin()+ (self.point - self.caster:GetAbsOrigin()):Normalized()  * 500
        end

        self.spread_peak = self.fly_distance/900 * self.spreadbase
        self.fly_direction    = (self.point - self.start_pos):Normalized()
      

        -- * self.vector_side
        self.fly_direction.z  = 0

        

        self.parent:SetForwardVector(self.fly_direction)
        self.fly_right_vector = self.parent:GetRightVector()

        self.elapsedTime = 0
        self.motionTick = {}
        self.motionTick[0] = 0
        self.motionTick[1] = 0
        self.motionTick[2] = 0

        self.fly_duration  = hTable.duration or  0.4
         
        self.fly_hVelocity = self.fly_distance / self.fly_duration--self.speed
        self.fly_gravity   = -self.spread_peak / ( self.fly_duration * self.fly_duration * 0.125 )
        self.fly_vVelocity = (-0.5) * self.fly_gravity * self.fly_duration

        self:StartIntervalThink(FrameTime())

        if not self.kab_fx then
            local kab_fx = self.vector_side < 0 and "particles/emiya/archer_kab_kanshou.vpcf" or "particles/emiya/archer_kab_bakuya.vpcf"

            self.kab_fx =   ParticleManager:CreateParticle( kab_fx, PATTACH_ABSORIGIN_FOLLOW, self.parent )
                            ParticleManager:SetParticleControl( self.kab_fx, 0, self.start_pos  )
                            ParticleManager:SetParticleControl( self.kab_fx, 1, Vector(0, 0, self.vector_side) )

            self:AddParticle(self.kab_fx, false, false, -1, false, false)
        
            --EmitSoundOn("Archer.Kab.Throw."..RandomInt(1, 1), self.parent)
        end
    end
end
function modifier_archer_kab:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_archer_kab:OnIntervalThink()
    if IsServer() and IsNotNull(self.parent) then
        local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(), 
                                            self.parent:GetAbsOrigin(), 
                                            nil, 
                                            self.hit_radius, 
                                            self.ability:GetAbilityTargetTeam(), 
                                            self.ability:GetAbilityTargetType(), 
                                            self.ability:GetAbilityTargetFlags(), 
                                            FIND_ANY_ORDER, 
                                            false)

        for _, enemy in pairs(enemies) do
            if enemy and not enemy:IsNull() then
                if not self.HittedTargets[enemy:entindex()] then
                    self.HittedTargets[enemy:entindex()] = true

                    local slash_pfx =   ParticleManager:CreateParticle("particles/emiya/emiya_swords_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
                                        ParticleManager:SetParticleControlEnt(slash_pfx, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
                                        ParticleManager:ReleaseParticleIndex(slash_pfx)

                                        enemy:EmitSound("Hero_Juggernaut.OmniSlash.Damage")

                    DoDamage(self.caster, enemy, self.damage, self.ability:GetAbilityDamageType(), 0, self.ability, false)
                    if self.caster.IsOveredgeAcquired then
                        if self.caster:HasModifier("modifier_archer_kab_overedge_stacks") then
                            local currentStacks = self.caster:GetModifierStackCount("modifier_archer_kab_overedge_stacks", self.caster)
                            if currentStacks >= 6 then return end
                            self.caster:AddNewModifier(self.caster, self.ability,"modifier_archer_kab_overedge_stacks", {duration = 10})
                            self.caster:SetModifierStackCount("modifier_archer_kab_overedge_stacks", caster,currentStacks + 1 )
                        else
                            self.caster:AddNewModifier(self.caster, self.ability,"modifier_archer_kab_overedge_stacks", {duration = 10})
                            self.caster:SetModifierStackCount("modifier_archer_kab_overedge_stacks", caster,1 )
                        end
                    end
                end
            end
        end
        self:UpdateHorizontalMotion(self.parent, FrameTime())
    end
end
function modifier_archer_kab:SyncTime( iDir, dt )
    if IsServer() then
        if self.motionTick[1]==self.motionTick[2] then
            self.motionTick[0] = self.motionTick[0] + 1
            self.elapsedTime = self.elapsedTime + dt
        end

        -- sync time
        self.motionTick[iDir] = self.motionTick[0]
        
        -- end motion
        if self.elapsedTime > self.fly_duration + 0.03 and self.motionTick[1] == self.motionTick[2] then
            self.endpos = self.parent:GetAbsOrigin()
            if(IsServer()) then
                Timers:CreateTimer(0.00, function()
                
                    ParticleManager:DestroyParticle(self.kab_fx,true)
                    ParticleManager:ReleaseParticleIndex(self.kab_fx)
                end)
            end
            --[[
                if(self.vector_side == -1) then
                    local endcap_pfx =   ParticleManager:CreateParticle("particles/emiya/archer_kab_bakuya_endcap.vpcf", PATTACH_CUSTOMORIGIN, nil)
                    ParticleManager:SetParticleControl(endcap_pfx,0,  self.endpos + self.fw * 50+self.rw * -10)
                    ParticleManager:SetParticleControl(endcap_pfx,1,  self.endpos + self.fw * 100+self.rw * -10 )
         
                    ParticleManager:ReleaseParticleIndex(endcap_pfx)
        
                    Timers:CreateTimer(1, function()
                        local endcap_pfx_2 =   ParticleManager:CreateParticle("particles/emiya/swords_dissapear.vpcf", PATTACH_CUSTOMORIGIN, nil)
                        ParticleManager:SetParticleControl(endcap_pfx_2, 0,  self.endpos + self.fw * 15 + Vector(0,0,80)+self.rw * -10)
                        ParticleManager:SetParticleControl(endcap_pfx_2, 1,  self.endpos + self.fw * 15 + Vector(0,0,80)+self.rw * -10)
                        ParticleManager:ReleaseParticleIndex(endcap_pfx_2)
                    end)
                end
                ]]
               
            self:Destroy()
        end
    end
end
function modifier_archer_kab:UpdateHorizontalMotion(me, dt)
    if IsServer() then
        self:SyncTime(1, dt)

        local target = self.fly_direction * self.fly_hVelocity * self.elapsedTime

        self:SyncTime(2, dt)

        local side_size = self.fly_vVelocity * self.elapsedTime + 0.5 * self.fly_gravity * self.elapsedTime * self.elapsedTime

        local next_pos = self.start_pos + target
            next_pos = next_pos + self.fly_right_vector * self.vector_side * side_size

        if self.parent and not self.parent:IsNull() then
            self.parent:SetOrigin(next_pos)
            self.parent:FaceTowards(self.point)
        end
    end
end
function modifier_archer_kab:OnDestroy()
   
end