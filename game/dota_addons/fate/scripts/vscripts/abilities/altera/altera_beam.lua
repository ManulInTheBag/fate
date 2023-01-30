altera_beam = class({})

function altera_beam:OnAbilityPhaseStart()
	self:GetCaster():EmitSound("altera_photon")
	return true
end

function altera_beam:OnAbilityPhaseInterrupted()
	self:GetCaster():StopSound("altera_photon")
end

function altera_beam:OnSpellStart()
    local hCaster = self:GetCaster()

    hCaster:AddNewModifier(hCaster, self, "modifier_altera_beam", {duration = self:GetSpecialValueFor("duration")})
end

---------------------------------------------------------------------------------------------------------------------
LinkLuaModifier("modifier_altera_beam", "abilities/altera/altera_beam", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_beam_slow", "abilities/altera/altera_beam", LUA_MODIFIER_MOTION_NONE)

modifier_altera_beam = class({})

function modifier_altera_beam:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_COMMAND_RESTRICTED] = true}
end

function modifier_altera_beam:IsHidden() return true end

function modifier_altera_beam:OnCreated()
    if IsServer() then
    	self.ability = self:GetAbility()
    	self.caster = self:GetCaster()
    	self.parent = self:GetParent()
    	self.caster_team = self.caster:GetTeamNumber()

    	self.form = "neutral"
        self.particlename = "particles/altera/altera_beam.vpcf"
        self.particlename2 = "particles/altera/altera_beam_mane.vpcf"

        if self.caster:HasModifier("modifier_altera_form_str") then
        	self.form = "str"
        	self.particlename = "particles/altera/altera_beam_red.vpcf"
        	self.particlename2 = "particles/altera/altera_beam_mane_red.vpcf"
        end
        if self.caster:HasModifier("modifier_altera_form_agi") then
        	self.form = "agi"
        	self.particlename = "particles/altera/altera_beam_green.vpcf"
        	self.particlename2 = "particles/altera/altera_beam_mane_green.vpcf"
        end
        if self.caster:HasModifier("modifier_altera_form_int") then
        	self.form = "int"
        	self.particlename = "particles/altera/altera_beam_blue.vpcf"
        	self.particlename2 = "particles/altera/altera_beam_mane_blue.vpcf"
        end

        self.team_flag = DOTA_UNIT_TARGET_TEAM_ENEMY
		if self.form == "int" then
			self.team_flag = DOTA_UNIT_TARGET_TEAM_BOTH
		end

        self.point     = self.ability:GetCursorPosition() + self.caster:GetForwardVector()
        self.distance  = self.ability:GetSpecialValueFor("distance")
        if self.form == "int" then
        	self.distance = self.distance + self.ability:GetSpecialValueFor("int_bonus_distance")
        end
        self.direction = (Vector(self.point.x, self.point.y, self.point.z) - Vector(self.caster:GetAbsOrigin().x, self.caster:GetAbsOrigin().y, self.caster:GetAbsOrigin().z)):Normalized()
        self.vAttachLoc = self.caster:GetAttachmentOrigin(self.caster:ScriptLookupAttachment("attach_attack1")) - self.direction * 30 + Vector(0, 0, 50)
        self.point     = self.vAttachLoc + self.direction * self.distance

        self.start_width = self.ability:GetSpecialValueFor("start_width")
        self.end_width = self.ability:GetSpecialValueFor("end_width")

        self.damage = self.ability:GetSpecialValueFor("damage")
        
        if self.parent.ErosionAcquired then
        	if self.form == "str" then
        		self.damage = self.damage + self.ability:GetSpecialValueFor("str_damage_mult")*self.parent:GetStrength()
        	end
        	if self.form == "agi" then
        		self.damage = self.damage + self.ability:GetSpecialValueFor("agi_damage_mult")*self.parent:GetAgility()
        	end
        	if self.form == "int" then
        		self.damage = self.damage + self.ability:GetSpecialValueFor("int_damage_mult")*self.parent:GetIntellect()
        	end
        end

        self.duration = self.ability:GetSpecialValueFor("duration")
        self.damage = ( self.damage / self.duration ) * FrameTime()
        self.heal = self.damage/2

        self.cdr = self.ability:GetSpecialValueFor("int_cdr")
        self.cdr = (self.cdr/self.duration) * FrameTime()

        self.particle =    ParticleManager:CreateParticle(self.particlename, PATTACH_WORLDORIGIN, self.caster)
                            ParticleManager:SetParticleShouldCheckFoW(self.particle, false)
                            ParticleManager:SetParticleControl(self.particle, 0, self.vAttachLoc)
                            ParticleManager:SetParticleControl(self.particle, 1, self.point)
                            ParticleManager:SetParticleControl(self.particle, 3, self.point)
                            ParticleManager:SetParticleControl(self.particle, 9, self.vAttachLoc)

        self.particle2 =    ParticleManager:CreateParticle(self.particlename2, PATTACH_WORLDORIGIN, self.caster)
                            ParticleManager:SetParticleShouldCheckFoW(self.particle2, false)
                            ParticleManager:SetParticleControl(self.particle2, 0, self.caster:GetAbsOrigin() + Vector(0, 0, 50))

        self:AddParticle(self.particle, false, false, -1, false, false)
        self:AddParticle(self.particle2, false, false, -1, false, false)

        self.sound = "altera_beam_loop"

        EmitSoundOn(self.sound, self.caster)
        self:StartIntervalThink(FrameTime())
    end
end
function modifier_altera_beam:OnIntervalThink()
    local hEnemies =   FindUnitsInLine(
								        self.caster_team,
								        self.caster:GetAbsOrigin(),
								        self.point,
								        nil,
								        self.start_width,
										self.team_flag,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_NONE
    								)

    local hEnemies2 = FindUnitsInRadius(self.caster_team, self.point, nil, self.end_width, self.team_flag, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

    local AttackedTargets    = {}

    for _, hEnemy in pairs(hEnemies) do
        self:Impact(hEnemy, 1)
        AttackedTargets[hEnemy:entindex()] = true
    end
    for _, hEnemy in pairs(hEnemies2) do
    	if not AttackedTargets[hEnemy:entindex()] then
    		self:Impact(hEnemy, 1)
    	end
        self:Impact(hEnemy, 0.5)
    end
end

function modifier_altera_beam:Impact(target, mult)
	if IsNotNull(target) --then
        and target ~= self.caster then
        if target:GetTeamNumber() == self.caster_team then
            target:Heal(self.heal*mult, self.ability)
            if self.form == "int" and self.parent.ErosionAcquired then
        	   	for j=0, 5 do 
					local pepe_ability = target:GetAbilityByIndex(j)
					if pepe_ability ~= nil then
						rCooldown = pepe_ability:GetCooldownTimeRemaining()
						pepe_ability:EndCooldown()
						pepe_ability:StartCooldown(rCooldown - self.cdr)
					end
				end
			end
        else
        	local damage = self.damage
            if self.form == "agi" then
            	damage = damage*(2 - target:GetHealth()/target:GetMaxHealth())
			end
            if self.form == "str" then
               	target:AddNewModifier(self.caster, self.ability, "modifier_altera_beam_slow", {Duration = self.ability:GetSpecialValueFor("str_slow_duration")})
               	if self.parent.ErosionAcquired then
					giveUnitDataDrivenModifier(self.caster, target, "locked", self.ability:GetSpecialValueFor("str_lock_duration"))
				end
			end
			if self.form == "agi" and self.parent.ErosionAcquired then
				DoDamage(self.caster, target, damage/2*mult, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
				DoDamage(self.caster, target, damage/2*mult, DAMAGE_TYPE_PURE, 0, self.ability, false)
			else
				DoDamage(self.caster, target, damage*mult, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
			end
        end
    end
end

function modifier_altera_beam:OnDestroy()
    if IsServer() then
        StopSoundOn(self.sound, self.caster)
    end
end

modifier_altera_beam_slow = class({})

function modifier_altera_beam_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_altera_beam_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("str_slow")
end

function modifier_altera_beam_slow:IsHidden()
	return true 
end