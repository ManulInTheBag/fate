-----------------------------
--    Modifier: Avalon  - The Sword and the Scabbard  --
-----------------------------

modifier_artoria_ultimate_avalon = class({})

LinkLuaModifier( "modifier_artoria_avalon_cooldown", "abilities/artoria/modifiers/modifier_artoria_avalon_cooldown", LUA_MODIFIER_MOTION_NONE )

function modifier_artoria_ultimate_avalon:OnCreated()
		range = self:GetAbility():GetSpecialValueFor("range")
		damage = self:GetAbility():GetSpecialValueFor("damage")
		damage_threshold = self:GetAbility():GetSpecialValueFor("damage_threshold")
		stun_duration = self:GetAbility():GetSpecialValueFor("stun_duration")
		ability = self:GetAbility()
		
	if not IsServer() then return end
end

function modifier_artoria_ultimate_avalon:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_artoria_ultimate_avalon:OnTakeDamage(args)
	local caster = self:GetParent() 
	local attacker = args.attacker
	
	local caster_position = caster:GetAbsOrigin()
	local attacker_position = attacker:GetAbsOrigin()
	local damage_taken = args.damage
	
	local currentHealth = caster:GetHealth()
	
	caster:SetHealth(currentHealth + args.damage)
	
	if caster:IsAlive() and damage_taken > 299 and not caster:HasModifier("modifier_artoria_ultimate_excalibur") and not caster:HasModifier("modifier_artoria_final_slash_stun") and not caster:HasModifier("modifier_artoria_avalon_cooldown") and caster:GetTeam() ~= attacker:GetTeam() and (caster_position - attacker_position):Length2D() < range then
		local casterDash = Physics:Unit(caster)
		local distance = attacker_position - caster_position
		caster:SetPhysicsFriction(0)
		caster:SetPhysicsVelocity(distance:Normalized() * distance:Length2D() * 2.5)
		caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
		caster:FollowNavMesh(true)
		caster:SetAutoUnstuck(false)
		
		caster:SetHealth(currentHealth + args.damage)
		StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_2_ES_ROLL, rate=1.0})
		
		caster:AddNewModifier(caster, self, "modifier_artoria_avalon_cooldown", {Duration = 2.0})
		
	Timers:CreateTimer({
		endTime = 0.4,
		callback = function()
		
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:OnPhysicsFrame(nil)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_2_ES_ROLL_END, rate=1.0})
		
		local targets = FindUnitsInRadius(caster:GetTeam(), attacker_position, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, damage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 1.0})
	    end
		
		HardCleanse(caster)
		
		local explosionFxIndex = ParticleManager:CreateParticle( "particles/custom/saber_avalon_explosion.vpcf", PATTACH_ABSORIGIN, caster )
		ParticleManager:SetParticleControl( explosionFxIndex, 3, caster:GetAbsOrigin() )
		
		Timers:CreateTimer( 3.0, function()
			--ParticleManager:DestroyParticle( impactFxIndex, false )
			ParticleManager:DestroyParticle( explosionFxIndex, false )
		end)
		
	end
	})
	end
end

function modifier_artoria_ultimate_avalon:IsHidden()
	return false
end

function modifier_artoria_ultimate_avalon:RemoveOnDeath()
	return true
end

function modifier_artoria_ultimate_avalon:IsDebuff()
	return false 
end

function modifier_artoria_ultimate_avalon:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_artoria_ultimate_avalon:GetEffectName()
	return "particles/custom/artoria/ultimate_avalon_buff.vpcf"
end

function modifier_artoria_ultimate_avalon:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end