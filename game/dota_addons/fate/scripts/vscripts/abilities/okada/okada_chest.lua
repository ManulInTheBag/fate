
okada_chest = class({})
LinkLuaModifier("modifier_okada_chest_clone_motion", "abilities/okada/okada_chest", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_okada_cdr", "abilities/okada/okada_chest", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_2", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE) 
SetDirectionByAngles = function(hUnit, vDirection) --Explained why I am using that in the first ability modifier.
    vDirection = VectorToAngles(vDirection)
    return hUnit:SetAbsAngles(vDirection[1], vDirection[2], vDirection[3])
end
function okada_chest:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
    return true
end

function okada_chest:GetIntrinsicModifierName()
    return "modifier_okada_cdr"
end
function okada_chest:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function okada_chest:PeformCloneDash(clone, caster, dmgMod, delay)
	Timers:CreateTimer(delay, function()
		clone:AddNewModifier(caster, self, "modifier_okada_chest_clone_motion", {duration = 0.4, state = 1}) 
		clone:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY )
		UnfreezeAnimation(clone)
		clone:EmitSound("okada_dash_slash_"..math.random(1,2))

		Timers:CreateTimer(0.2, function()
			local hEntities = FindUnitsInRadius(
                                            caster:GetTeamNumber(),
                                            clone:GetAbsOrigin(),
                                            nil,
                                            300,
                                            self:GetAbilityTargetTeam(),
                                            self:GetAbilityTargetType(),
                                            self:GetAbilityTargetFlags(),
                                            FIND_CLOSEST,
                                            false
                                        )
		--=================================--
		for _, hEntity in pairs(hEntities) do
			if IsNotNull(hEntity) then
                local damage = self:GetSpecialValueFor("damage")
                if caster.OkadaSa1Acquired then
                    damage = damage + self:GetSpecialValueFor("sa_bonus_damage")/100 * caster:GetAgility()
                end
				DoDamage(caster, hEntity,  damage * dmgMod, self:GetAbilityDamageType(), DOTA_DAMAGE_FLAG_NONE,self, false)
				hEntity:EmitSound("okada_dash_slash_enemy")

			end
		end
		
		end)
	end)

end

function okada_chest:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = ability:GetCursorPosition()
	local width = ability:GetSpecialValueFor("width")
	local range = ability:GetSpecialValueFor("range")


	local ori = caster:GetAbsOrigin()
	local vec = (targetPoint - ori):Normalized()
	local target = caster:GetAbsOrigin() + vec * range
	self.target = target
	local enemies = FindUnitsInLine(
                                                                caster:GetTeamNumber(),
                                                                caster:GetAbsOrigin(),
                                                               target,
                                                                nil,
                                                                width,
                                                                DOTA_UNIT_TARGET_TEAM_ENEMY,
                                                                DOTA_UNIT_TARGET_ALL,
                                                                0
                                                            )
	local sImagePFX = "particles/okada/okada_chest_slash.vpcf"
	if caster:HasModifier("modifier_okada_manslayer") then
		sImagePFX = "particles/okada/okada_chest_slash_red.vpcf"
	end

	local fx = ParticleManager:CreateParticle(sImagePFX, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControlTransformForward(fx, 0, caster:GetAbsOrigin()+ Vector(0,0, 100) + caster:GetRightVector() * -50, caster:GetForwardVector())

    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:ReleaseParticleIndex(fx)
	for _, enemy in pairs(enemies) do
        local damage = self:GetSpecialValueFor("damage")
        if caster.OkadaSa1Acquired then
            damage = damage + self:GetSpecialValueFor("sa_bonus_damage")/100 * caster:GetAgility()
        end
		DoDamage(caster, enemy, damage, self:GetAbilityDamageType(), DOTA_DAMAGE_FLAG_NONE,self, false)

        enemy:AddNewModifier(caster, self, "modifier_heal_reduction_tier_2", {duration = self:GetSpecialValueFor("healres_duration")})
        giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("lock_duration"))
        
		--EmitSoundOn("hijikata_demon_sfx", enemy)

		
	end
	caster:EmitSound("okada_e_slash")
	 if caster:HasModifier("modifier_okada_manslayer") then
		caster:EmitSound("okada_e2")

	 else
		caster:EmitSound("okada_e")

	 end

	 if caster:HasModifier("modifier_okada_manslayer") then

        if IsValidEntity(Dummy1) then
            Dummy1:RemoveSelf()
        end
        if IsValidEntity(Dummy2) then
            Dummy2:RemoveSelf()
        end
        Dummy1 = CreateUnitByName("okada_clone", caster:GetAbsOrigin() + caster:GetRightVector() * 250, false, nil, nil, caster:GetTeamNumber())
		Dummy1:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		Dummy1:SetDayTimeVisionRange(0)
        Dummy1:SetModelScale(1.3)
		Dummy1:SetNightTimeVisionRange(0)
        Dummy2 = CreateUnitByName("okada_clone", caster:GetAbsOrigin()+ caster:GetRightVector() * -250, false, nil, nil, caster:GetTeamNumber())
		Dummy2:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		Dummy2:SetDayTimeVisionRange(0)
		Dummy2:SetNightTimeVisionRange(0)
        Dummy2:SetModelScale(1.3)
		local vec = (target - Dummy1:GetAbsOrigin())
        vec.z = 0
        vec = vec:Normalized()
		Dummy1:SetForwardVector(vec)
		local vec = (target - Dummy2:GetAbsOrigin())
        vec.z = 0
        vec = vec:Normalized()
		Dummy2:SetForwardVector(vec)
		self:PeformCloneDash(Dummy1, caster, self:GetSpecialValueFor("clones_damage")/100, self:GetSpecialValueFor("clones_delay"))
		self:PeformCloneDash(Dummy2, caster, self:GetSpecialValueFor("clones_damage")/100, self:GetSpecialValueFor("clones_delay"))
		Dummy1:EmitSound("okada_sword_draw")
		Dummy1:EmitSound("okada_sword_draw")
		StartAnimation(Dummy1, {duration = 0.6, activity = ACT_DOTA_CAST_LIFE_BREAK_START, rate = 1})
		StartAnimation(Dummy2, {duration = 0.6, activity = ACT_DOTA_CAST_LIFE_BREAK_START, rate = 1})
		Timers:CreateTimer(0.15, function()
			FreezeAnimation(Dummy1)
			FreezeAnimation(Dummy2)
		
		end)

        Timers:CreateTimer(0.6, function()
            Dummy1:RemoveSelf()
			 Dummy2:RemoveSelf()
        end)

       

    else
        caster:EmitSound("okada_q")
    end
	
	

end



modifier_okada_chest_clone_motion = modifier_okada_chest_clone_motion or class({})

function modifier_okada_chest_clone_motion:IsHidden()                                                                return true end
function modifier_okada_chest_clone_motion:IsDebuff()                                                                return false end
function modifier_okada_chest_clone_motion:IsPurgable()                                                              return false end
function modifier_okada_chest_clone_motion:IsPurgeException()                                                        return false end
function modifier_okada_chest_clone_motion:RemoveOnDeath()                                                           return true end 
function modifier_okada_chest_clone_motion:CheckState()

    return self.state
end

function modifier_okada_chest_clone_motion:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.nRadius = self.hAbility:GetAOERadius()

    self.nSpeed = 2000

    self.state =  {
            [MODIFIER_STATE_STUNNED] = true, 

        }

    if self.iMoveState == 1 then
            self.state =  {
            [MODIFIER_STATE_STUNNED] = true, 
            [MODIFIER_STATE_FLYING] = true,

    }     

    end


    if IsServer() then
        self.nDamageType           = self.hAbility:GetAbilityDamageType()

        self.nCASTER_TEAM          = self.hCaster:GetTeamNumber()
        self.nABILITY_TARGET_TEAM  = self.hAbility:GetAbilityTargetTeam()
        self.nABILITY_TARGET_TYPE  = self.hAbility:GetAbilityTargetType()
        self.nABILITY_TARGET_FLAGS = self.hAbility:GetAbilityTargetFlags()

        self.vStartLoc = self.hParent:GetAbsOrigin()

        self.vPoint =  self:GetAbility().target   + (self.hParent:GetForwardVector() * 10) 

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


        self.hParent:EmitSound("okada_blink")

    end
end
function modifier_okada_chest_clone_motion:OnRefresh(tTable)
    self:OnCreated(tTable)
end
function modifier_okada_chest_clone_motion:OnHorizontalMotionInterrupted()
    if IsServer() then
      
        self.hParent:RemoveHorizontalMotionController(self) --This is basically necessary when another motion interruptions happens to you, in F/A 2 basically nothing that can't interrupt your hero, as many use Physics, but you can write special custom manipulations in update motion and interrupt it if anything happens.
    end
end
function modifier_okada_chest_clone_motion:UpdateHorizontalMotion(hUnit, nTime)
    if IsServer() then
        local vCurrentLoc = hUnit:GetAbsOrigin()

        local vDirection = self.vMainDirection

        local nDistancePerTick = self.nSpeed * nTime
        local nMaxDistance     = self.vMainDistance > self.nRadius and self.nRadius or self.vMainDistance

        local nMinUnitsStep = 10
        local nStepsCount   = math.ceil(nDistancePerTick / nMinUnitsStep)

        local bShouldDestroy = false

        for nStep = 1, nStepsCount do
            nDistancePerTick = ( nMinUnitsStep * nStep )

            local vNextStepPos  = vCurrentLoc + vDirection * nDistancePerTick
            local vNextStepDist = GetDistance(vNextStepPos, self.vStartLoc)
        end

        local vNextMovePoint = vCurrentLoc + vDirection * nDistancePerTick --Get next position based on interval tick time and speed.

        hUnit:SetAbsOrigin(vNextMovePoint ) 

        if bShouldDestroy then
            self:Destroy()
        end
    end
end


function modifier_okada_chest_clone_motion:GetStatusEffectName()
    return "particles/econ/items/invoker/invoker_ti7/status_effect_alacrity_ti7.vpcf"
end

 

modifier_okada_cdr = class({})

function modifier_okada_cdr:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_okada_cdr:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
  }
  return funcs
end


function modifier_okada_cdr:GetModifierPercentageCooldown(args)
--hero.BaseMS + agility * Attributes.ms_adjustment + hero.MSgained * Attributes.additional_movespeed_adjustment
  if args.ability ~= nil then
    if  args.ability:IsItem() then
      return self:GetStackCount()
    else
        return 0
    end
  end
  return 0
end

function modifier_okada_cdr:OnCreated()
  self:setstackcount(0)
end

function modifier_okada_cdr:IsHidden()
  return true
end

function modifier_okada_cdr:IsDebuff()
  return false
end

function modifier_okada_cdr:RemoveOnDeath()
  return false
end
