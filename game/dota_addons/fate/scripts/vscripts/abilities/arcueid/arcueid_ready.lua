LinkLuaModifier("modifier_arcueid_ready", "abilities/arcueid/arcueid_ready", LUA_MODIFIER_MOTION_NONE)

arcueid_ready = class({})

function arcueid_ready:OnAbilityPhaseStart()
    self:GetCaster():EmitSound("arcueid_ult_1")
    return true
end

function arcueid_ready:OnAbilityPhaseInterrupted()
    self:GetCaster():StopSound("arcueid_ult_1")
end

function arcueid_ready:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	

	caster:AddNewModifier(caster, self, "modifier_arcueid_ready", {duration = 1.0})
end

function arcueid_ready:GetAOERadius()
	return self:GetSpecialValueFor("range")
end

modifier_arcueid_ready = class({})

function modifier_arcueid_ready:IsHidden() return true end
function modifier_arcueid_ready:IsDebuff() return false end
function modifier_arcueid_ready:RemoveOnDeath() return true end

function modifier_arcueid_ready:OnCreated()
	if IsServer() then
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		local ori = self.caster:GetAbsOrigin()
		local fw = self.caster:GetForwardVector()
		self.enemy = nil
		self.locked = false
		self.target = ori + fw*600
		local affected = false
		local enemies = FindUnitsInLine(
									        self.caster:GetTeamNumber(),
									        ori,
									        self.target,
									        nil,
									        200,
											DOTA_UNIT_TARGET_TEAM_ENEMY,
											DOTA_UNIT_TARGET_HERO,
											DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	    								)

	    if self.caster and IsValidEntity(self.caster) and enemies and #enemies>0 then
		    for _, enemy in pairs(enemies) do
		    	if not affected then
		    		affected = true
			    	self.enemy = enemy
			    	self.target = self.enemy:GetAbsOrigin() + fw*150
			    	self.locked = true
			    end
			    enemy:AddNewModifier(caster, self.ability, "modifier_stunned", {duration = 0.2})
		    end
		end

		FindClearSpaceForUnit( self.caster, self.target, true )
		local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_arcana_counter_slash_down.vpcf", PATTACH_WORLDORIGIN, caster)
	    ParticleManager:SetParticleControl(slash_fx, 0, ori + Vector(0, 0, 100))
	    ParticleManager:SetParticleControl(slash_fx, 7, ori + Vector(0, 0, 100))
	    ParticleManager:SetParticleControl(slash_fx, 8, self.target + Vector(0, 0, 100))
	    Timers:CreateTimer(1, function()
	        ParticleManager:DestroyParticle(slash_fx, false)
	        ParticleManager:ReleaseParticleIndex(slash_fx)
	    end)

		if not self.enemy then
			self:Destroy()
			return
		end

		--self.caster:EmitSound("arcueid_ult_first")

		StartAnimation(self.caster, {duration=1.3, activity=ACT_DOTA_CAST_ABILITY_5, rate=1.0})

		self.damage = self.ability:GetSpecialValueFor("damage")
		self.collide_damage = self.ability:GetSpecialValueFor("collide_damage")
		self.ori = self.enemy:GetAbsOrigin()
		if self.caster.MonstrousStrengthAcquired then
			self.collide_damage = self.collide_damage + self.caster:GetStrength()*self.ability:GetSpecialValueFor("collide_mult")
		end
		self.direction = (self.ori - self.caster:GetAbsOrigin()):Normalized()
		if self.caster:GetAbsOrigin() == self.ori then
			self.direction = caster:GetForwardVector()
		end
		self.direction.z = 0
		self.factor = 1

        ApplyReattachableAirborneOnly(self.enemy, 1000, 1.0)
        --self.enemy:AddNewModifier(self.caster, self.ability, "modifier_stunned", {duration = 0.5})
        ApplyReattachableAirborneOnly(self.caster, 1000, 1.0)

        self.caster:SetForwardVector(self.direction*self.factor)
        --self:Slash()

		self.rand = math.random(1,2)
		--[[if self.rand == 3 then
			self.caster:EmitSound("arcueid_pepeg")
		end]]

		--[[self.caster:SetAbsOrigin(self.ori - self.factor*self.direction*250)
		self.caster:SetForwardVector(self.direction*self.factor)]]


		self:StartIntervalThink(FrameTime())
		self.tick = 0
	end
end

function modifier_arcueid_ready:OnIntervalThink()
	if IsServer() then
		local caster = self.caster
		self.tick = self.tick + 1
		local target = self.enemy
		local ability = self.ability
		local radius = self.ability:GetSpecialValueFor("radius")

		if (self.enemy:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > 400 then
			self.locked = false
		end

		if self.tick == 3 then
			if self.locked then
				ApplyReattachableAirborneOnly(self.enemy, 1000, 1.0)
			end
        	ApplyReattachableAirborneOnly(self.caster, 1000, 1.0)
        end

		if (self.tick == 4) or (self.tick == 16) or (self.tick == 28) then
			if self.tick == 4 then
				self.factor = 1
				if self.rand == 1 then
					caster:EmitSound("arcueid_ready_1")
				elseif self.rand == 2 then
					caster:EmitSound("arcueid_ult_2")--caster:EmitSound("arcueid_ready_4")
				end
				if self.locked then
					self.enemy:AddNewModifier(caster, self.ability, "modifier_stunned", {duration = 0.5})
				end

				self:Slash()

				caster:SetAbsOrigin(self.ori - self.factor*self.direction*250)
				caster:SetForwardVector(self.direction*self.factor)
			end
			if self.tick == 16 then
				self.factor = -1
				if self.rand == 1 then
					caster:EmitSound("arcueid_ready_2")
				elseif self.rand == 2 then
					caster:EmitSound("arcueid_ult_3")--caster:EmitSound("arcueid_ready_5")
				end
				if self.locked then
					self.enemy:AddNewModifier(caster, self.ability, "modifier_stunned", {duration = 0.5})
					ApplyReattachableAirborneOnly(self.enemy, 1000, 1.0)
				end
       			--ApplyReattachableAirborneOnly(self.caster, 1000, 0.5)

				self:Slash()

				caster:SetAbsOrigin(self.ori - self.factor*self.direction*150 + Vector(0, 0, 400))
				caster:SetForwardVector(self.direction*self.factor)
			end
			if self.tick == 28 then
				self.factor = 1
				if self.rand == 1 then
					caster:EmitSound("arcueid_ready_3")
				elseif self.rand == 2 then
					caster:EmitSound("arcueid_ult_4")--caster:EmitSound("arcueid_ready_6")
				end
				--caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(),caster))
				if self.locked then
					self.enemy:SetAbsOrigin(GetGroundPosition(self.enemy:GetAbsOrigin(),self.enemy))
				end

				self:Smash()

				--[[caster:SetAbsOrigin(self.ori - self.factor*self.direction*100)
				caster:SetForwardVector(self.direction*self.factor)]]
			end
			--[[if not target:IsMagicImmune() then
				DoDamage(caster, self.enemy, self.damage , DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
				caster:FindAbilityByName("arcueid_impulses"):Pepeg(target)

				if caster.RecklesnessAcquired then
					target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})
				end
			end]]
		end
	end
end

function modifier_arcueid_ready:OnDestroy()
	if not IsServer() then return end
	local target = self.caster

	FindClearSpaceForUnit( target, target:GetAbsOrigin(), true )
	target:PreventDI(false)
    target:SetPhysicsVelocity(Vector(0,0,0))
    target:SetPhysicsAcceleration(Vector(0,0,0))
    target:OnPhysicsFrame(nil)
    target:Hibernate(true)
end

function modifier_arcueid_ready:Smash()
	local caster = self:GetCaster()
	local radius = self.ability:GetSpecialValueFor("radius")

	local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_arcana_counter_slash_down.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
    ParticleManager:SetParticleControl(slash_fx, 7, caster:GetAbsOrigin() + caster:GetForwardVector()*150 + Vector(0, 0, 500))
    ParticleManager:SetParticleControl(slash_fx, 8, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
    Timers:CreateTimer(1, function()
        ParticleManager:DestroyParticle(slash_fx, false)
        ParticleManager:ReleaseParticleIndex(slash_fx)
    end)

    local hit_point = caster:GetAbsOrigin() + caster:GetForwardVector()*150
    EmitSoundOnLocationWithCaster(hit_point, "Hero_Leshrac.Split_Earth", caster)  
    local hit_fx = ParticleManager:CreateParticle("particles/nero/atalanta_earthshock.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControl( hit_fx, 0, GetGroundPosition(hit_point, caster))
    ParticleManager:SetParticleControl( hit_fx, 1, Vector(radius, 300, 150))
    local enemies = FindUnitsInRadius(caster:GetTeam(), hit_point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for _,enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
            if not enemy:IsMagicImmune() then
            	EmitSoundOn("arcueid_hit", enemy)
                DoDamage(caster, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
                enemy:AddNewModifier(caster, enemy, "modifier_stunned", {duration = self.ability:GetSpecialValueFor("stun_duration")})
            end
        end
    end
end

function modifier_arcueid_ready:Slash()
	local caster = self:GetCaster()
	local radius = self.ability:GetSpecialValueFor("radius")

	local particle = ParticleManager:CreateParticle("particles/arcueid/arcueid_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, Vector(radius + 50, 0, 70))
	ParticleManager:SetParticleControl(particle, 10, Vector(0, 0, 180))
	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	caster:EmitSound("arcueid_swing")

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
	                                    caster:GetAbsOrigin(),
	                                    nil,
	                                   	radius,
	                                    DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                    DOTA_UNIT_TARGET_ALL,
	                                    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	                                    FIND_ANY_ORDER,
	                                    false)

	for _,enemy in pairs(enemies) do
		local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
		local origin_diff_norm = origin_diff:Normalized()
		if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
			EmitSoundOn("arcueid_hit", enemy)
		    DoDamage(caster, enemy, self.damage , DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
		end
	end
end

function modifier_arcueid_ready:CheckState()
	return {  [MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,}
end

--[[function modifier_arcueid_what:DeclareFunctions()
  return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  }
end
function modifier_arcueid_what:GetModifierMoveSpeedBonus_Percentage()
  return -1*self:GetAbility():GetSpecialValueFor("slow_percent")
end]]