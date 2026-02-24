okada_reduced_earth = class({})

SetDirectionByAngles = function(hUnit, vDirection) --Explained why I am using that in the first ability modifier.
    vDirection = VectorToAngles(vDirection)
    return hUnit:SetAbsAngles(vDirection[1], vDirection[2], vDirection[3])
end

LinkLuaModifier("modifier_okada_earth_motion", "abilities/okada/okada_reduced_earth", LUA_MODIFIER_MOTION_HORIZONTAL) 

function okada_reduced_earth:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local target_flag = DOTA_UNIT_TARGET_FLAG_NONE
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or (IsServer() and IsLocked(caster)) then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end


function okada_reduced_earth:PerformStrike(unit, caster, target, addVector, dmgMod)


	--caster:EmitSound("hijikata_serya")
    local diff = (target:GetAbsOrigin() - unit:GetAbsOrigin() ):Normalized() 
	unit:SetAbsOrigin(target:GetAbsOrigin() + diff * 600 + addVector) 
	--FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	unit:FaceTowards(target:GetAbsOrigin())
	local vector = -(unit:GetAbsOrigin() - target:GetAbsOrigin())
	vector.z = 0
	unit:SetForwardVector(vector)

	
	local damage = self:GetSpecialValueFor("damage") 

    local nDuration = (600/self:GetSpecialValueFor("speed")) + 0.1
    local targetOrigin  = target:GetAbsOrigin()
    local x = targetOrigin.x
    local y = targetOrigin.y
    local z = targetOrigin.z
    unit:AddNewModifier(caster, self, "modifier_okada_earth_motion", {duration = nDuration, point_x = x, point_y = y, point_z = z }) 
    
	--DoDamage(caster, target, damage, self:GetAbilityDamageType(), 0, self, false)


	--particle
    local vec = -(unit:GetAbsOrigin() - targetOrigin):Normalized()
    local particle_name = "particles/okada/okada_pierce.vpcf"
     if caster:HasModifier("modifier_okada_manslayer") then
        particle_name = "particles/hijikata/hijikata_demon_pierce.vpcf"
     end
    Timers:CreateTimer(0.1, function()
        --unit:EmitSound("okada_pierce")
            local enemies = FindUnitsInLine(
                                                                unit:GetTeamNumber(),
                                                                unit:GetAbsOrigin(),
                                                                unit:GetAbsOrigin() + vec * 500,
                                                                nil,
                                                                200,
                                                                DOTA_UNIT_TARGET_TEAM_ENEMY,
                                                                DOTA_UNIT_TARGET_ALL,
                                                                0
                                                            )

        for _, enemy in pairs(enemies) do
            DoDamage(caster, enemy, damage * dmgMod, self:GetAbilityDamageType(), 0, self, false)
            if caster.OkadaSa4Acquired then
                giveUnitDataDrivenModifier(caster, enemy, "rooted", self:GetSpecialValueFor("sa_debuff_duration"))
                giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("sa_debuff_duration"))
            end
            EmitSoundOn("okada_pierce", enemy)

        end
    	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, nil)
	    ParticleManager:SetParticleControlTransformForward(particle, 0, unit:GetAbsOrigin() + Vector(0,0,130), vec)
        ParticleManager:SetParticleControlTransformForward(particle, 1, unit:GetAbsOrigin()+ Vector(0,0,130), vec)
        Timers:CreateTimer( 2.0, function()
		--ParticleManager:DestroyParticle( particle, false )
		    ParticleManager:ReleaseParticleIndex( particle )
	    end)
    end)








end

function okada_reduced_earth:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if IsSpellBlocked(target) then return end -- Linken effect checker
    caster:EmitSound("okada_blink")
    local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
	if((target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > self:GetSpecialValueFor("radius")) then
		self:EndCooldown()
		return
	end
    caster:RemoveModifierByName("modifier_okada_earth_motion")
    caster.QDashTargetIzo = target
    self:PerformStrike(caster, caster, target, Vector(0,0,0), 1)
    if caster:HasModifier("modifier_okada_manslayer") then
        caster:EmitSound("okada_q2")
        if IsValidEntity(Dummy1) then
            Dummy1:RemoveSelf()
        end
        if IsValidEntity(Dummy2) then
            Dummy2:RemoveSelf()
        end
        Dummy1 = CreateUnitByName("okada_clone", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
		Dummy1:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		Dummy1:SetDayTimeVisionRange(0)
        Dummy1:SetModelScale(1.3)
		Dummy1:SetNightTimeVisionRange(0)
        Dummy2 = CreateUnitByName("okada_clone", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
		Dummy2:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		Dummy2:SetDayTimeVisionRange(0)
		Dummy2:SetNightTimeVisionRange(0)
        Dummy2:SetModelScale(1.3)
        diff = - diff
        local rightVec = Vector(diff.y, -diff.x, 0) 
        -- Dummy1:EmitSound("okada_blink")
        -- Dummy2:EmitSound("okada_blink")
        self:PerformStrike(Dummy1, caster, target, rightVec * 300, self:GetSpecialValueFor("clones_damage")/100)
        self:PerformStrike(Dummy2, caster, target,rightVec * -300, self:GetSpecialValueFor("clones_damage")/100)

        Timers:CreateTimer(0.37, function()
            Dummy1:RemoveSelf()
            Dummy2:RemoveSelf()
        end)
       

    else
        caster:EmitSound("okada_q")
    end
	
end




modifier_okada_earth_motion = modifier_okada_earth_motion or class({})

function modifier_okada_earth_motion:IsHidden()                                                                return true end
function modifier_okada_earth_motion:IsDebuff()                                                                return false end
function modifier_okada_earth_motion:IsPurgable()                                                              return false end
function modifier_okada_earth_motion:IsPurgeException()                                                        return false end
function modifier_okada_earth_motion:RemoveOnDeath()                                                           return true end 
function modifier_okada_earth_motion:CheckState()
    local tState =  {
                        [MODIFIER_STATE_STUNNED] = true, 
                        [MODIFIER_STATE_FLYING] = true,

                    }
    return tState
end
function modifier_okada_earth_motion:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_OVERRIDE_ANIMATION
                    }
    return tFunc
end
function modifier_okada_earth_motion:GetOverrideAnimation(keys) 
    return ACT_DOTA_OVERRIDE_ABILITY_1
end
function modifier_okada_earth_motion:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nRadius = self.hAbility:GetAOERadius()

    self.nSpeed = self.hAbility:GetSpecialValueFor("speed")
    self.target = self.hCaster.QDashTargetIzo

    self.nImageRadius       = self.hAbility:GetSpecialValueFor("radius")
    self.nImageDamage       = self.hAbility:GetSpecialValueFor("damage") 
 


 

    if IsServer() then
        self.nDamageType           = self.hAbility:GetAbilityDamageType()

        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        self.vStartLoc = self.hParent:GetAbsOrigin()

        self.vPoint = Vector(tTable.point_x, tTable.point_y, tTable.point_z)+ (self.hParent:GetForwardVector() * 10) 

        self.vMainDirection = GetDirection(self.vPoint, self.vStartLoc)
        self.vMainDistance  = GetDistance(self.vPoint, self.vStartLoc)

        SetDirectionByAngles(self.hParent, self.vMainDirection)
        self.hParent:FaceTowards(self.vPoint) 

        if not self:ApplyHorizontalMotionController() then 
            self:Destroy()
        end
        local particleJopaName = "particles/okada/okada_dash.vpcf"

        if self.hCaster:HasModifier("modifier_okada_manslayer") then
            particleJopaName = "particles/_2okada/okada_dash_red.vpcf"
        end
        if not self.nDashPFX then
            self.nDashPFX =     ParticleManager:CreateParticle(particleJopaName, PATTACH_ABSORIGIN_FOLLOW, self.hParent)
                                ParticleManager:SetParticleControlEnt(
                                                                        self.nDashPFX,
                                                                        0,
                                                                        self.hParent,
                                                                        PATTACH_POINT_FOLLOW,
                                                                        "attach_hitloc",
                                                                        Vector(0,0,0), -- unknown
                                                                        true -- unknown, true
                                                                    )

            self:AddParticle(self.nDashPFX, false, false, -1, false, false)
        end

        -- self.sEmitSound = "Saito.Flashblade.Cast"
        -- self.hParent:EmitSound(self.sEmitSound)

    end
end
function modifier_okada_earth_motion:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_okada_earth_motion:OnHorizontalMotionInterrupted()
    if IsServer() then
        self.hParent:RemoveHorizontalMotionController(self) --This is basically necessary when another motion interruptions happens to you, in F/A 2 basically nothing that can't interrupt your hero, as many use Physics, but you can write special custom manipulations in update motion and interrupt it if anything happens.
    end
end
function modifier_okada_earth_motion:UpdateHorizontalMotion(hUnit, nTime)
    if IsServer() then
        local vCurrentLoc = hUnit:GetAbsOrigin()

        local vDirection = self.vMainDirection

        local nDistancePerTick = self.nSpeed * nTime
        local nMaxDistance     = self.vMainDistance > self.nRadius and self.nRadius or self.vMainDistance

        local nMinUnitsStep = 10
        local nStepsCount   = math.ceil(nDistancePerTick / nMinUnitsStep)

        local bShouldDestroy = false
        hUnit:FaceTowards(self.target:GetAbsOrigin())
        local vec = (self.target:GetAbsOrigin() - hUnit:GetAbsOrigin()):Normalized()
        vec.z = 0
        --hUnit:SetForwardVector(vec)

  

        local vNextMovePoint = vCurrentLoc + vDirection * nDistancePerTick --Get next position based on interval tick time and speed.

        hUnit:SetAbsOrigin(vNextMovePoint) 

        if bShouldDestroy then
            self:Destroy()
        end
    end
end
function modifier_okada_earth_motion:OnDestroy()
    if IsServer() then
        if IsValidEntity(self.hParent) then
             FindClearSpaceForUnit(self.hParent, self.hParent:GetAbsOrigin(), true) --Only for resolving possible errors by finding clear space.
              self.hParent:RemoveGesture(self:GetOverrideAnimation()) 
        end
       --Uncomment if there will be any problem with that in the future.
      --This line is necessary to prevent animation loop issues when modifiers are not exist but you are still animated.
    end
end

function modifier_okada_earth_motion:GetStatusEffectName()
    return "particles/econ/items/invoker/invoker_ti7/status_effect_alacrity_ti7.vpcf"
end
