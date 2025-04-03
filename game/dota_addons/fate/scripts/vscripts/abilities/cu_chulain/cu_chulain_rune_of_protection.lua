cu_chulain_rune_of_protection = class({})

LinkLuaModifier("modifier_rune_of_protection", "abilities/cu_chulain/modifiers/modifier_rune_of_protection", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_rush", "abilities/cu_chulain/cu_chulain_rune_of_protection", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_cu_rotation_lock","abilities/cu_chulain/cu_chulain_rune_of_protection", LUA_MODIFIER_MOTION_NONE)
function cu_chulain_rune_of_protection:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=1, activity=ACT_DOTA_RAZE_2, rate=1.5})
end

function cu_chulain_rune_of_protection:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end

function cu_chulain_rune_of_protection:GetManaCost(iLevel)
	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		return 0
	else
		return 100
	end
end

function cu_chulain_rune_of_protection:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		cooldown = cooldown - (cooldown * 0.75)
	end

	return cooldown
end
function cu_chulain_rune_of_protection:OnRuneProck()
	local caster = self:GetCaster()
	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, self:GetSpecialValueFor("maximum_distance"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST , false)
	if #targets < 1 then 
        caster:RemoveModifierByName("pause_sealenabled")
		return
	 end
     caster:StopSound("cu_protection_1") 
     caster:EmitSound("cu_protection_2") 
	local target = targets[1]
	caster.dash_target = target
	caster:AddNewModifier(caster, self, "modifier_cu_rotation_lock", {Duration = 0.1})
    
	Timers:CreateTimer(0.1, function() 


        self.damage = self:GetSpecialValueFor("damage")
        self.speed = self:GetSpecialValueFor("dash_speed")
        caster:AddNewModifier(caster, self, "modifier_cu_rush", {damage = self.damage,
                                                                        speed = self.speed })

    end)              
end
function cu_chulain_rune_of_protection:OnSpellStart()
	local caster = self:GetCaster()
	caster.dash_target = nil
	caster:AddNewModifier(caster, self, "modifier_rune_of_protection", { Duration = self:GetSpecialValueFor("duration") })
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.9)  
    caster:EmitSound("cu_protection_1") 
	if not caster:HasModifier("modifier_celtic_rune_attribute") then
		local ability = caster:FindAbilityByName("cu_chulain_rune_magic")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))		
	end
end


modifier_cu_rush = class({})

function modifier_cu_rush:OnCreated(hui)
    if not IsServer() then return end
    self.bSoundReady = true
	self.parent = self:GetParent()
    self.parent:Stop() 
	self.ability = self:GetAbility()
    self.damage_dealth = false
    self.parent:StartGesture(ACT_DOTA_AMBUSH)
	self.target = self.parent.dash_target
    self.oldfw = self.parent:GetForwardVector()
    local vector = (self.target:GetOrigin() - self.parent:GetOrigin()):Normalized()
    vector.z = 0
	self.parent:SetForwardVector(vector)

	self.parent:FaceTowards(self.target:GetAbsOrigin())
    if IsServer() then
		self.damage = hui.damage
		self.speed = hui.speed
       

        self.targetpos = self.target:GetAbsOrigin()

		self:StartIntervalThink(FrameTime())
		if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end
	end
end
function modifier_cu_rush:OnRefresh(hui)
    self:OnCreated(hui)
end
function modifier_cu_rush:IsHidden() return false end
function modifier_cu_rush:IsDebuff() return false end
function modifier_cu_rush:RemoveOnDeath() return true end
function modifier_cu_rush:GetPriority() return MODIFIER_PRIORITY_HIGH end

function modifier_cu_rush:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true, }

    if self.target and not self.target:IsNull() and self.target:HasFlyMovementCapability() then
        state[MODIFIER_STATE_FLYING] = true
    else
        state[MODIFIER_STATE_FLYING] = false
    end
    
    return state
end

 

function modifier_cu_rush:OnDestroy()
    if not IsServer() then return end
    self.parent:AddNewModifier(self.parent, self.ability, "modifier_cu_rotation_lock", {duration = 0.15})

    
    local pos = self.parent:GetOrigin()
    local direction = self.targetpos - pos
    direction.z = 0     
   
	local particle = ParticleManager:CreateParticle("particles/cu_chulain/gae_bolg_pierce.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlTransformForward(particle, 0, self.parent:GetAbsOrigin() + Vector(0,0,130)+self.parent:GetRightVector() * - 20,self.parent:GetForwardVector())
    ParticleManager:SetParticleControlTransformForward(particle, 1, self.parent:GetAbsOrigin()+ Vector(0,0,130)+self.parent:GetRightVector() * - 20,self.parent:GetForwardVector())
	ParticleManager:SetParticleControlTransformForward(particle, 5, self.parent:GetAbsOrigin()+ Vector(0,0,130) + self.parent:GetForwardVector() *  50,self.parent:GetForwardVector())
    ParticleManager:ReleaseParticleIndex(particle)
	local blow_fx =     ParticleManager:CreateParticle("particles/econ/items/void_spirit/void_spirit_immortal_2021/void_spirit_immortal_2021_astral_step_dmg_blood.vpcf", PATTACH_CUSTOMORIGIN, self.target)
	ParticleManager:SetParticleControl(blow_fx, 0, position)
	ParticleManager:ReleaseParticleIndex(blow_fx)
	--ParticleManager:SetParticleControlTransformForward(attackFx, 0, self.parent:GetAbsOrigin(), direction)

	self.parent:SetForwardVector(self.oldfw)
	self.parent:FaceTowards(self.target:GetAbsOrigin())
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
        if self.parent:HasModifier("jump_pause_nosilence") then
        	self.parent:RemoveModifierByName("jump_pause_nosilence")
        end


    end
end

function modifier_cu_rush:UpdateHorizontalMotion(me, dt)
    local UFilter = UnitFilter( self.target,
                                self.ability:GetAbilityTargetTeam(),
                                self.ability:GetAbilityTargetType(),
                                self.ability:GetAbilityTargetFlags(),
                                self.parent:GetTeamNumber() )

    if UFilter ~= UF_SUCCESS then
        self:Destroy()

        return nil
    end

    if (self.targetpos - self.target:GetAbsOrigin()):Length2D() > 300 then
        self:Destroy()

        return nil
    end

    self.targetpos = self.target:GetAbsOrigin() 
    self.distance = (self.target:GetOrigin() - self.parent:GetOrigin()):Length2D()


 
    if self.distance < 300 and self.damage_dealth == false then
        self:BOOM()

        return nil
    end
    if self.distance < 150 then
        self:Destroy()
        return nil
    end
    self:Rush(me, dt)
end
function modifier_cu_rush:BOOM()
    local position = self.target:GetAbsOrigin()
    local damage = self.damage
    self.damage_dealth = true
    if IsSpellBlocked(self.target) then return end
   
	self.parent:RemoveGesture(ACT_DOTA_AMBUSH)
    StartAnimation( self.parent, {duration=0.45, activity=ACT_DOTA_RAZE_3, rate=1.5})



    	if not self.target:IsMagicImmune() then
            Timers:CreateTimer(0.1, function()
                DoDamage(self.parent, self.target, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
                self.target:EmitSound("cu_pierce_new")
                self.target:EmitSound("cu_pierce_new_2")
				giveUnitDataDrivenModifier(self.parent, self.target, "silenced", self.ability:GetSpecialValueFor("silence_duration"))
                if self.parent:GetHealth() < self.parent:GetMaxHealth() then
                    local diff = self.parent:GetMaxHealth() - self.parent:GetHealth()

                 end
            end)
            
        end
    


end
function modifier_cu_rush:Rush(me, dt)
    --[[if self.parent:IsStunned() then
        return nil
    end]]

    local pos = self.parent:GetOrigin()
    local targetpos = self.target:GetOrigin()

    local direction = targetpos - pos
    direction.z = 0     
    local target = pos + direction:Normalized() * (self.speed * dt)
	--self.parent:SetForwardVector((self.target:GetOrigin() - self.parent:GetOrigin()):Normalized())
    self.parent:SetOrigin(target)
    self.parent:FaceTowards(self.targetpos)

end

function modifier_cu_rush:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end

function modifier_cu_rush:GetEffectName()
    return "particles/hijikata/hijikata_run_test.vpcf"
end

function modifier_cu_rush:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
 

modifier_cu_rotation_lock = class({})


function modifier_cu_rotation_lock:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING  }

	return funcs
end

function modifier_cu_rotation_lock:GetModifierDisableTurning() 
	return 1
end
 


function modifier_cu_rotation_lock:CheckState()
    local state =   { 
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		
                    }
    return state
end
 
function modifier_cu_rotation_lock:IsHidden() return true end
function modifier_cu_rotation_lock:RemoveOnDeath() return true end
