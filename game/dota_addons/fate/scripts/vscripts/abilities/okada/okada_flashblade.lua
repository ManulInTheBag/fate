okada_flashblade = okada_flashblade or class({})
LinkLuaModifier("modifier_okada_flashblade_marker", "abilities/okada/okada_flashblade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okada_combo_switch", "abilities/okada/okada_flashblade", LUA_MODIFIER_MOTION_NONE)
SetDirectionByAngles = function(hUnit, vDirection) --Explained why I am using that in the first ability modifier.
    vDirection = VectorToAngles(vDirection)
    return hUnit:SetAbsAngles(vDirection[1], vDirection[2], vDirection[3])
end
function okada_flashblade:GetAOERadius() 
    return self:GetSpecialValueFor("distance")
end

function okada_flashblade:CheckCombo()
	local caster = self:GetCaster()
    local num = 29.1
	if caster:GetStrength() >= num and caster:GetAgility() >= num and caster:GetIntellect() >= num then
		if caster:FindAbilityByName("okada_combo"):IsCooldownReady()  then
			return true
		end
	end
    return false
end


function okada_flashblade:OnSpellStart()
    local hCaster   = self:GetCaster()
    hCaster:RemoveModifierByName("modifier_okada_earth_motion")
    local nDuration = (self:GetAOERadius()/self:GetSpecialValueFor("speed")) + 0.1
    self:GetCaster():EmitSound("okada_sword_draw")
    if self:GetAutoCastState() then
        if self:CheckCombo() then
            hCaster:AddNewModifier(hCaster, self, "modifier_okada_combo_switch", { Duration = 3 })
        end
    end
    if hCaster:HasModifier("modifier_okada_manslayer") then
        hCaster:EmitSound("okada_w2")
        local vec = (self:GetCursorPosition() - hCaster:GetAbsOrigin())
        vec.z = 0
        vec = vec:Normalized()
        local distance =  (self:GetCursorPosition() - hCaster:GetAbsOrigin()):Length2D()
        if distance > self:GetAOERadius() then
            distance = self:GetAOERadius()
        end
        
        self.AuraDummy = CreateUnitByName("okada_clone", hCaster:GetAbsOrigin(), false, nil, nil, hCaster:GetTeamNumber())
		self.AuraDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
        self.AuraDummy:SetModelScale(1.3)
		self.AuraDummy:SetDayTimeVisionRange(0)
		self.AuraDummy:SetNightTimeVisionRange(0)
        self.AuraDummy:SetForwardVector(vec)
        self.AuraDummy:AddNewModifier(hCaster, self, "modifier_okada_flashblade_motion", {duration = distance/self:GetSpecialValueFor("speed")/1.5, state = 1}) 
        self.AuraDummy:AddNewModifier(hCaster, self, "modifier_kill", { Duration = distance/self:GetSpecialValueFor("speed") + 1 })
        self.AuraDummy:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY )
        local hDummy = self.AuraDummy
        Timers:CreateTimer(distance/self:GetSpecialValueFor("speed")/1.5 - 0.03, function()
            if IsNotNull(hDummy) then
                hDummy:RemoveSelf()
            end
        end)
        FindClearSpaceForUnit(hCaster, hCaster:GetAbsOrigin() + vec * distance, true)
        hCaster:SetForwardVector(vec)

    else
        hCaster:EmitSound("okada_w")
        hCaster:AddNewModifier(hCaster, self, "modifier_okada_flashblade_motion", {duration = nDuration, state = 0}) 

    end

end
---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_okada_flashblade_motion", "abilities/okada/okada_flashblade", LUA_MODIFIER_MOTION_HORIZONTAL) 

modifier_okada_flashblade_motion = modifier_okada_flashblade_motion or class({})

function modifier_okada_flashblade_motion:IsHidden()                                                                return true end
function modifier_okada_flashblade_motion:IsDebuff()                                                                return false end
function modifier_okada_flashblade_motion:IsPurgable()                                                              return false end
function modifier_okada_flashblade_motion:IsPurgeException()                                                        return false end
function modifier_okada_flashblade_motion:RemoveOnDeath()                                                           return true end 
function modifier_okada_flashblade_motion:CheckState()

    return self.state
end

function modifier_okada_flashblade_motion:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nRadius = self.hAbility:GetAOERadius()

    self.nSpeed = self.hAbility:GetSpecialValueFor("speed")

    self.nImageRadius       = self.hAbility:GetSpecialValueFor("radius")
    self.nImageDamage       = self.hAbility:GetSpecialValueFor("damage") 
    if self.hCaster.OkadaSa1Acquired then
         self.nImageDamage  =  self.nImageDamage  +  self.hAbility:GetSpecialValueFor("sa_bonus_damage") or 0
    end
    self.nImageCreationDist = self.hAbility:GetSpecialValueFor("slash_create_dist")
    self.soundController = 1
    self.iMoveState = tTable.state
    self.animationTimeAccumulated = 0
    self.animTable = {
            ACT_DOTA_RAZE_1,
            ACT_DOTA_RAZE_2,
            ACT_DOTA_RAZE_3,
            ACT_DOTA_ICE_VORTEX

        }
    self.state =  {
            [MODIFIER_STATE_SILENCED] = true, 
            [MODIFIER_STATE_MUTED] = true, 
            [MODIFIER_STATE_ROOTED] = true, 
            [MODIFIER_STATE_DISARMED] = true, 
        }

    if self.iMoveState == 1 then
            self.state =  {
            [MODIFIER_STATE_SILENCED] = true, 
            [MODIFIER_STATE_MUTED] = true, 
            [MODIFIER_STATE_ROOTED] = true, 
            [MODIFIER_STATE_DISARMED] = true, 
            [MODIFIER_STATE_FLYING] = true,

        }
        self.nSpeed = self.nSpeed * 1.5
        self.nRadius = self.nRadius + 300
        

    end
    self:PlayRandomAttackAnimation()

    if IsServer() then
        self.nDamageType           = self.hAbility:GetAbilityDamageType()

        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        self.vStartLoc = self.hParent:GetAbsOrigin()

        self.vPoint = self.hAbility:GetCursorPosition() + (self.hParent:GetForwardVector() * 10) 

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


        self.hParent:EmitSound("okada_dash_test")

    end
end
function modifier_okada_flashblade_motion:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_okada_flashblade_motion:OnHorizontalMotionInterrupted()
    if IsServer() then
      
        self.hParent:RemoveHorizontalMotionController(self) --This is basically necessary when another motion interruptions happens to you, in F/A 2 basically nothing that can't interrupt your hero, as many use Physics, but you can write special custom manipulations in update motion and interrupt it if anything happens.
    end
end
function modifier_okada_flashblade_motion:UpdateHorizontalMotion(hUnit, nTime)

    if IsServer() then
        if self.hParent:IsStunned() then
            return nil
        end
        local vCurrentLoc = hUnit:GetAbsOrigin()
        self.animationTimeAccumulated = self.animationTimeAccumulated + nTime
        if self.animationTimeAccumulated >= 0.15 then
            self.animationTimeAccumulated = 0
            self:PlayRandomAttackAnimation()
        end
        local vDirection = self.vMainDirection

        local nDistancePerTick = self.nSpeed * nTime
        local nMaxDistance     = self.vMainDistance > self.nRadius and self.nRadius or self.vMainDistance

        local nMinUnitsStep = 10
        local nStepsCount   = math.ceil(nDistancePerTick / nMinUnitsStep)

        local bShouldDestroy = false

        self.nSlashesCreated = self.nSlashesCreated or 0

        for nStep = 1, nStepsCount do
            nDistancePerTick = ( nMinUnitsStep * nStep )

            local vNextStepPos  = vCurrentLoc + vDirection * nDistancePerTick
            local vNextStepDist = GetDistance(vNextStepPos, self.vStartLoc)

            if self.iMoveState == 0 and (not GridNav:IsTraversable(vNextStepPos) or GridNav:IsBlocked(vNextStepPos) or vNextStepDist > nMaxDistance) then
                bShouldDestroy = true
                break
            else
    

                if vNextStepDist >= ( self.nImageCreationDist + ( self.nImageCreationDist * self.nSlashesCreated ) ) then
                    self.nSlashesCreated = self.nSlashesCreated + 1
                    self:DoEffect(hUnit, vNextStepPos + vDirection * 150)
                end
            end
        end

        local vNextMovePoint = vCurrentLoc + vDirection * nDistancePerTick --Get next position based on interval tick time and speed.

        hUnit:SetAbsOrigin(vNextMovePoint ) 

        if bShouldDestroy then
            self:Destroy()
        end
    end
end

function modifier_okada_flashblade_motion:PlayRandomAttackAnimation()
    if IsServer() then
        local number = math.random( #self.animTable )
        local value = self.animTable[number  ]
        table.remove(self.animTable, number)
        --EndAnimation(self.hParent)
       StartAnimation( self.hParent, {duration=0.2, activity=value , rate=6})
    end
end
function modifier_okada_flashblade_motion:OnDestroy()

    if IsServer() then
            -- OnDestroy прилетает и изнутри RemoveSelf() клона — тогда хендл уже мёртв
            if IsNotNull(self.hParent) then
                self.hParent:StopSound("okada_dash_test")
            end
       --FindClearSpaceForUnit(self.hParent, self.hParent:GetAbsOrigin(), true) --Only for resolving possible errors by finding clear space.
       --Uncomment if there will be any problem with that in the future.
       --EndAnimation(self.hParent)
       --self.hParent:RemoveGesture(self:GetOverrideAnimation()) --This line is necessary to prevent animation loop issues when modifiers are not exist but you are still animated.
    end
end
function modifier_okada_flashblade_motion:DoEffect(hUnit, vPosition)
    local sImagePFX = "particles/okada/okada_dash_slashes.vpcf"
    if self.hCaster:HasModifier("modifier_okada_manslayer") then
        sImagePFX = "particles/okada/okada_dash_slashes_red.vpcf"
    end
    self.hParent:EmitSound("okada_dash_slash_"..self.soundController)
    if self.soundController == 2 then
        self.soundController = 1
    else
        self.soundController = 2
    end

    --EmitSoundOnLocationWithCaster(vPosition, "Saito.Flashblade.Impact", hUnit)

    local hEntities = FindUnitsInRadius(
                                            self.nCASTER_TEAM,
                                            vPosition,
                                            nil,
                                            self.nImageRadius,
                                            self.nABILITY_TARGET_TEAM,
                                            self.nABILITY_TARGET_TYPE,
                                            self.nABILITY_TARGET_FLAGS,
                                            FIND_CLOSEST,
                                            false
                                        )
    --=================================--
    for _, hEntity in pairs(hEntities) do
        if IsNotNull(hEntity) then
            if not hEntity:HasModifier("modifier_okada_flashblade_marker") then
                DoDamage(self.hCaster, hEntity, self.nImageDamage, self.nDamageType, DOTA_DAMAGE_FLAG_NONE, self.hAbility, false)
                hEntity:AddNewModifier(self.hCaster, self:GetAbility(), "modifier_okada_flashblade_marker", {duration = 0.3})

                hEntity:EmitSound("okada_dash_slash_enemy")
            end
        end
    end
    local particle = ParticleManager:CreateParticle(sImagePFX, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 7, vPosition)
    ParticleManager:SetParticleControl(particle, 0, vPosition)
    ParticleManager:SetParticleControl(particle, 1, vPosition)
    ParticleManager:SetParticleControl(particle, 2, vPosition)
    --ParticleManager:SetParticleShouldCheckFoW(particle, false)


    ParticleManager:ReleaseParticleIndex(particle)
     

end

function modifier_okada_flashblade_motion:GetStatusEffectName()
    return "particles/econ/items/invoker/invoker_ti7/status_effect_alacrity_ti7.vpcf"
end

 


modifier_okada_flashblade_marker = class({})
function modifier_okada_flashblade_marker:IsHidden() return false end
function modifier_okada_flashblade_marker:IsDebuff() return false end
function modifier_okada_flashblade_marker:RemoveOnDeath() return true end



modifier_okada_combo_switch = class({})

function modifier_okada_combo_switch:IsHidden()
	return false 
end

function modifier_okada_combo_switch:RemoveOnDeath()
	return true
end

if IsServer() then
	function modifier_okada_combo_switch:OnCreated(args)
		local caster = self:GetParent()
         if caster:GetAbilityByIndex(4):GetName() == "okada_mark" then
		     caster:SwapAbilities("okada_mark", "okada_combo", false, true)
         end
	end

	function modifier_okada_combo_switch:OnDestroy()	
		local caster = self:GetParent()	
        if caster:GetAbilityByIndex(4):GetName() == "okada_combo" then
		     caster:SwapAbilities("okada_mark", "okada_combo", true, false)
        end
      
	end
end

