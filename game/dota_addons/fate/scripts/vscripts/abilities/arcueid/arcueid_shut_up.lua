LinkLuaModifier("modifier_arcueid_what", "abilities/arcueid/arcueid_shut_up", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcueid_what_buff", "abilities/arcueid/arcueid_shut_up", LUA_MODIFIER_MOTION_NONE)

arcueid_shut_up = class({})

function arcueid_shut_up:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local damage = self:GetSpecialValueFor("damage")
	local damage_secondary = self:GetSpecialValueFor("damage")/2
	local collide_damage = self:GetSpecialValueFor("collide_damage")
	local pushback_range = self:GetSpecialValueFor("range")
	local target = self:GetCursorTarget()
	if IsSpellBlocked(target) then return end
	--[[if caster.MonstrousStrengthAcquired then
		collide_damage = collide_damage + caster:GetStrength()*self:GetSpecialValueFor("collide_mult")
		--pushback_range = pushback_range + caster:GetStrength()*self:GetSpecialValueFor("range_mult")
	end]]

	caster:EmitSound("arcueid_swing")
	caster:EmitSound("arcueid_shut_"..math.random(1,4))

	--[[local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        caster:GetAbsOrigin(),
								        caster:GetAbsOrigin() + caster:GetForwardVector()*200,
								        nil,
								        100,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_NONE
    								)]]

	--for _, target in pairs(enemies) do
		target:AddNewModifier(caster, self, "modifier_arcueid_what", {duration = self:GetSpecialValueFor("duration")})
		
		for i = 0,3 do
			Timers:CreateTimer(FrameTime()*2*i, function()
				EmitSoundOn("arcueid_hit", target)

				if caster.RecklesnessAcquired then
					target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})
				end

				local smokeFx3 = ParticleManager:CreateParticle("particles/custom_game/heroes/kenshiro/kenshiro_pressure_points_explosion/kenshiro_pressure_points_explosion_blood.vpcf", PATTACH_CUSTOMORIGIN, target)
				ParticleManager:SetParticleControl(smokeFx3, 0, target:GetAbsOrigin())
				ParticleManager:DestroyParticle(smokeFx3, false)
				ParticleManager:ReleaseParticleIndex(smokeFx3)
				local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
				ParticleManager:SetParticleControlEnt(
					effect_cast,
					0,
					target,
					PATTACH_POINT_FOLLOW,
					"attach_hitloc",
					target:GetOrigin(), -- unknown
					true -- unknown, true
				)
				ParticleManager:SetParticleControlTransformForward(effect_cast, 1, Vector(0,0,0), (caster:GetOrigin()-target:GetOrigin()):Normalized())
				--ParticleManager:SetParticleControlForward( effect_cast, 1, (caster:GetOrigin()-self.source_enemy:GetOrigin()):Normalized() )
				ParticleManager:ReleaseParticleIndex( effect_cast )
				--DoDamage(caster, target, damage_secondary/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
			end)
		end
		DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)

		if caster.RecklesnessAcquired then
			target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})
		end

		if not IsKnockbackImmune(target) then
			local casterfacing = caster:GetForwardVector()
			local pushTarget = Physics:Unit(target)
			local casterOrigin = caster:GetAbsOrigin()
			local initialUnitOrigin = target:GetAbsOrigin()
			target:PreventDI()
			target:SetPhysicsFriction(0)
			target:SetPhysicsVelocity(casterfacing:Normalized() * self:GetSpecialValueFor("speed"))
			target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		    target:OnPhysicsFrame(function(unit) 
				local unitOrigin = unit:GetAbsOrigin()
				local diff = unitOrigin - initialUnitOrigin
				local n_diff = diff:Normalized()
				unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
				if diff:Length() > pushback_range then
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
				giveUnitDataDrivenModifier(caster, target, "stunned", self:GetSpecialValueFor("stun_duration"))
				target:EmitSound("Hero_EarthShaker.Fissure")
				DoDamage(caster, target, collide_damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			end)
		end

		target:EmitSound("arcueid_hit")

		--target:EmitSound("Hero_EarthShaker.Fissure")
		--[[local groundFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, target )
		ParticleManager:SetParticleControl( groundFx, 1, target:GetAbsOrigin())]]
		local groundFx = ParticleManager:CreateParticle( "particles/arcueid/arcueid_blast.vpcf", PATTACH_ABSORIGIN, caster )
		ParticleManager:SetParticleControl( groundFx, 0, Vector(0, -180, 0))
		ParticleManager:SetParticleControl( groundFx, 5, target:GetAbsOrigin() + Vector(0, 0, 60))
	--end
end

modifier_arcueid_what = class({})

function modifier_arcueid_what:IsHidden() return false end
function modifier_arcueid_what:IsDebuff() return false end
function modifier_arcueid_what:RemoveOnDeath() return true end

function modifier_arcueid_what:OnCreated()
	if IsServer() then
		self.caster = self:GetCaster()
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
	end
end

--[[function modifier_arcueid_what:OnAttackStart(args)
	if IsServer() then
		if args.target ~= self:GetParent() then return end

		if not self:GetCaster().MonstrousStrengthAcquired then return end

		args.attacker:AddNewModifier(self.caster, self.ability, "modifier_arcueid_what_buff", {duration = 1.5})
	end
end

function modifier_arcueid_what:OnAttackLanded(args)
	if IsServer() then
		if args.target ~= self:GetParent() then return end

		if not self:GetCaster().MonstrousStrengthAcquired then return end

		self:IncrementStackCount()
		DoDamage(args.attacker, self.parent, self:GetStackCount()*self:GetAbility():GetSpecialValueFor("attribute_damage"), DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	end
end]]

function modifier_arcueid_what:OnTakeDamage(args)
	if IsServer() then
		if args.unit ~= self:GetParent() then return end

		args.attacker:Heal(args.damage*self.ability:GetSpecialValueFor("lifesteal")/100, self.ability)
		self:PlayEffects(args.attacker)
	end
end

function modifier_arcueid_what:DeclareFunctions()
  return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  }
end
function modifier_arcueid_what:GetModifierMoveSpeedBonus_Percentage()
  return -1*self:GetAbility():GetSpecialValueFor("slow_percent")
end

function modifier_arcueid_what:GetEffectName()
	return "particles/units/heroes/hero_life_stealer/life_stealer_open_wounds.vpcf"
end

function modifier_arcueid_what:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_arcueid_what:PlayEffects( target )
	-- Get Resources
	local particle_cast = "particles/generic_gameplay/generic_lifesteal.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	-- ParticleManager:SetParticleControl( effect_cast, iControlPoint, vControlVector )
	-- ParticleManager:SetParticleControlEnt(
	-- 	effect_cast,
	-- 	iControlPoint,
	-- 	hTarget,
	-- 	PATTACH_NAME,
	-- 	"attach_name",
	-- 	vOrigin, -- unknown
	-- 	bool -- unknown, true
	-- )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end



modifier_arcueid_what_buff = class({})

function modifier_arcueid_what_buff:IsHidden() return true end
function modifier_arcueid_what_buff:IsDebuff() return false end
function modifier_arcueid_what_buff:RemoveOnDeath() return true end
function modifier_arcueid_what_buff:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_arcueid_what_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_arcueid_what_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attribute_attack_speed")
end