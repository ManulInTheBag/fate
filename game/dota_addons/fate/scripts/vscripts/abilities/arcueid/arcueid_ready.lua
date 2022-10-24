LinkLuaModifier("modifier_arcueid_ready", "abilities/arcueid/arcueid_ready", LUA_MODIFIER_MOTION_NONE)

arcueid_ready = class({})

function arcueid_ready:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	
	caster:AddNewModifier(caster, self, "modifier_arcueid_ready", {duration = 0.76})
	StartAnimation(caster, {duration=0.76, activity=ACT_DOTA_CAST_ABILITY_5, rate=1.0})
end

modifier_arcueid_ready = class({})

function modifier_arcueid_ready:IsHidden() return true end
function modifier_arcueid_ready:IsDebuff() return false end
function modifier_arcueid_ready:RemoveOnDeath() return true end

function modifier_arcueid_ready:OnCreated()
	if IsServer() then
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.enemy = self.ability:GetCursorTarget()
		self.damage = self.ability:GetSpecialValueFor("damage")
		self.collide_damage = self.ability:GetSpecialValueFor("collide_damage")
		if self.caster.MonstrousStrengthAcquired then
			self.collide_damage = self.collide_damage + self.caster:GetStrength()*self.ability:GetSpecialValueFor("collide_mult")
		end

		self.rand = math.random(1,3)
		if self.rand == 3 then
			self.caster:EmitSound("arcueid_pepeg")
		end


		self:StartIntervalThink(FrameTime())
		self.tick = 0
	end
end

function modifier_arcueid_ready:OnIntervalThink()
	if IsServer() then
		local caster = self.caster
		caster:SetAbsOrigin(self.enemy:GetAbsOrigin() - caster:GetForwardVector()*50)
		self.tick = self.tick + 1
		local target = self.enemy
		local ability = self.ability
		if (self.tick == 3) or (self.tick == 11) or (self.tick == 18) then
			if self.tick == 3 then
				if self.rand == 1 then
					caster:EmitSound("arcueid_ready_1")
				elseif self.rand == 2 then
					caster:EmitSound("arcueid_ready_4")
				end
			end
			if self.tick == 11 then
				if self.rand == 1 then
					caster:EmitSound("arcueid_ready_2")
				elseif self.rand == 2 then
					caster:EmitSound("arcueid_ready_5")
				end
			end
			if self.tick == 18 then
				if self.rand == 1 then
					caster:EmitSound("arcueid_ready_3")
				elseif self.rand == 2 then
					caster:EmitSound("arcueid_ready_6")
				end
			end
			DoDamage(caster, self.enemy, self.damage , DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
			caster:FindAbilityByName("arcueid_impulses"):Pepeg()

			if caster.RecklesnessAcquired then
				target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})
			end

			target:EmitSound("Hero_EarthShaker.Fissure")

			local groundFx = ParticleManager:CreateParticle( "particles/arcueid/arcueid_blast.vpcf", PATTACH_ABSORIGIN, caster )
			ParticleManager:SetParticleControl( groundFx, 0, Vector(0, -180, 0))
			ParticleManager:SetParticleControl( groundFx, 5, target:GetAbsOrigin() + Vector(0, 0, 60))

			if not IsKnockbackImmune(target) then
				local casterfacing = caster:GetForwardVector()
				local pushTarget = Physics:Unit(target)
				local casterOrigin = caster:GetAbsOrigin()
				local initialUnitOrigin = target:GetAbsOrigin()
				target:PreventDI()
				target:SetPhysicsFriction(0)
				target:SetPhysicsVelocity(casterfacing:Normalized() * 2500)
				target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
			    target:OnPhysicsFrame(function(unit) 
					local unitOrigin = unit:GetAbsOrigin()
					local diff = unitOrigin - initialUnitOrigin
					local n_diff = diff:Normalized()
					unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
					if diff:Length() > (ability:GetSpecialValueFor("range")) then
						unit:PreventDI(false)
						unit:SetPhysicsVelocity(Vector(0,0,0))
						unit:OnPhysicsFrame(nil)
						FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
					end
				end)

				target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
					unit:SetBounceMultiplier(0)
					unit:PreventDI(false)
					unit:SetPhysicsVelocity(Vector(0,0,0))
					giveUnitDataDrivenModifier(caster, target, "stunned", ability:GetSpecialValueFor("stun_duration"))
					target:EmitSound("Hero_EarthShaker.Fissure")
					DoDamage(caster, target, self.collide_damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
				end)
			end
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