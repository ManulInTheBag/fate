-----------------------------
--    Modifier: Avalon    --
-----------------------------

modifier_artoria_avalon = class({})

LinkLuaModifier( "modifier_artoria_avalon_cooldown", "abilities/artoria/modifiers/modifier_artoria_avalon_cooldown", LUA_MODIFIER_MOTION_NONE )

function modifier_artoria_avalon:OnCreated()
	if IsServer() then
		self.range = self:GetAbility():GetSpecialValueFor("range")
		self.damage = self:GetAbility():GetSpecialValueFor("damage")
		self.damage_threshold = self:GetAbility():GetSpecialValueFor("damage_threshold")
		self.stun_duration = self:GetAbility():GetSpecialValueFor("stun_duration")
		self.ability = self:GetAbility()
		
		self.attacker_position = nil
		
		self:StartIntervalThink(0.06)
	end
end

function modifier_artoria_avalon:OnRefresh()
	self:StartIntervalThink(0.06)
end

if IsServer() then
	function modifier_artoria_avalon:OnIntervalThink()
		local caster = self:GetParent()
		caster:RemoveModifierByName("modifier_share_damage")
	end
end


function modifier_artoria_avalon:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end
	local caster = self:GetParent() 
	local attacker = args.attacker
	
	local caster_position = caster:GetAbsOrigin()
	local attacker_position = attacker:GetAbsOrigin()
	local damage_taken = args.damage
	
	local currentHealth = caster:GetHealth()
	
	caster:RemoveModifierByName("modifier_share_damage")
	
	if args.inflictor and (args.inflictor:GetAbilityName() == "sasaki_tsubame_gaeshi") and bit.band(args.damage_flags, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY) then return end
	caster:SetHealth(currentHealth + args.damage)
	
	if caster:IsAlive() and damage_taken >= self.damage_threshold and not caster:HasModifier("modifier_artoria_ultimate_excalibur") and not caster:HasModifier("pause_sealdisabled") and not caster:HasModifier("modifier_artoria_avalon_cooldown") and caster:GetTeam() ~= attacker:GetTeam() and (caster_position - attacker_position):Length2D() < self.range then
		local casterDash = Physics:Unit(caster)
		local distance = attacker_position - caster_position
		caster:SetPhysicsFriction(0)
		caster:SetPhysicsVelocity(distance:Normalized() * distance:Length2D() * 2.5)
		caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
		caster:FollowNavMesh(true)
		caster:SetAutoUnstuck(false)
		
		caster:SetHealth(currentHealth + args.damage)
		
		caster:AddNewModifier(caster, self, "modifier_artoria_avalon_cooldown", {Duration = 2.0})
		StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_2_ES_ROLL, rate=1.0})
		caster:FaceTowards(attacker:GetAbsOrigin())
		
	Timers:CreateTimer({
		endTime = 0.4,
		callback = function()
		
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:OnPhysicsFrame(nil)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_2_ES_ROLL_END, rate=1.0})
		
		local targets = FindUnitsInRadius(caster:GetTeam(), attacker_position, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	        v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 1.0})
	    end
		
		HardCleanse(caster)
		
		local attacker_position = nil
		
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

function modifier_artoria_avalon:IsHidden()
	return false
end

function modifier_artoria_avalon:RemoveOnDeath()
	return true
end

function modifier_artoria_avalon:IsDebuff()
	return false 
end

function modifier_artoria_avalon:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_artoria_avalon:GetEffectName()
	return "particles/custom/saber_avalon_floor.vpcf"
end

function modifier_artoria_avalon:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end