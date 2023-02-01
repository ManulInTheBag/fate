nero_rosa_buffed = class({})

LinkLuaModifier("modifier_rosa_slow", "abilities/nero/modifiers/modifier_rosa_slow", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_nero_rosa_window", "abilities/nero/nero_rosa_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_rosa_new", "abilities/nero/nero_rosa_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_rosa_motion_enemy", "abilities/nero/nero_rosa_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nero_rosa_motion", "abilities/nero/nero_rosa_new", LUA_MODIFIER_MOTION_HORIZONTAL)

function nero_rosa_buffed:GetCastRange(vLocation, hTarget)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_nero_rosa_new") then
		return 300
	else
		return self:GetSpecialValueFor("range")
	end
end

function nero_rosa_buffed:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or (IsServer() and IsLocked(caster)) then 
			return UF_FAIL_CUSTOM 
		--elseif self:GetCaster():HasModifier("modifier_aestus_domus_aurea_nero") and not hTarget:HasModifier("modifier_aestus_domus_aurea_enemy") then
		--	return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function nero_rosa_buffed:GetCustomCastErrorTarget(hTarget)
	--if self:GetCaster():HasModifier("modifier_aestus_domus_aurea_nero") and not hTarget:HasModifier("modifier_aestus_domus_aurea_enemy") then
	--	return "Outside Theatre"
	--else
	return "#Invalid_Target_or_Locked"
	--end    
end

--[[function nero_rosa_ichthys:GetCooldown(iLevel)
	local caster = self:GetCaster()
	--if caster:HasModifier("modifier_aestus_domus_aurea_nero") and caster:HasModifier("modifier_sovereign_attribute") then
	--	return self:GetSpecialValueFor("aestus_cooldown")
	--else
		return self:GetSpecialValueFor("cooldown")
	--end
end]]

function nero_rosa_buffed:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if caster:GetAbilityByIndex(0):GetName() ~= "nero_tres_new" then
		caster:SwapAbilities("nero_tres_buffed", "nero_tres_new", false, true)
	end
	if caster:GetAbilityByIndex(1):GetName() ~= "nero_gladiusanus_new" then
		caster:SwapAbilities("nero_gladiusanus_buffed", "nero_gladiusanus_new", false, true)
	end
	if caster:GetAbilityByIndex(2):GetName() ~= "nero_rosa_new" then
		caster:SwapAbilities("nero_rosa_buffed", "nero_rosa_new", false, true)
	end
	if caster:GetAbilityByIndex(5):GetName() ~= "nero_spectaculi_initium" then
		caster:SwapAbilities("nero_spectaculi_buffed", "nero_spectaculi_initium", false, true)
	end

	if IsSpellBlocked(target) then return end

	caster:EmitSound("nero_lsk")
	target:EmitSound("nero_lsk")
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", self:GetSpecialValueFor("stun_duration"))
	CreateSlashFx(caster, target:GetAbsOrigin() + Vector(900, 900, 300),target:GetAbsOrigin() + Vector(-900, -900, 300))
	Timers:CreateTimer(0.5, function()
		CreateSlashFx(caster, target:GetAbsOrigin() + Vector(900, -900, 300),target:GetAbsOrigin() + Vector(-900, 900, 300))
	end)
	Timers:CreateTimer(1, function()
		if caster.IsISAcquired then
			HardCleanse(caster)
		end
		local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()
		CreateSlashFx(caster, target:GetAbsOrigin() + Vector(900, 900, 300),target:GetAbsOrigin() + Vector(-900, -900, 300))
		caster:SetAbsOrigin(target:GetAbsOrigin() + diff:Normalized() * 150)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		--caster:FaceTowards(target:GetAbsOrigin())
		StartAnimation(caster, {duration = 1, activity = ACT_DOTA_CAST_ABILITY_3_END, rate = 1.5})	
		caster:MoveToTargetToAttack(target)

		local heat_abil = caster:FindAbilityByName("nero_heat")
	    heat_abil:IncreaseHeat(caster)

	    local damage = self:GetSpecialValueFor("damage") + (caster:HasModifier("modifier_sovereign_attribute") and caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("damage_scale")/100 or 0)

		--caster:AddNewModifier(caster,self,"modifier_rosa_buffer", {})

		 if not target:IsMagicImmune() then
			DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end

		target:AddNewModifier(caster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration") })

		caster:RemoveModifierByName("modifier_rosa_buffer")
				
		target:EmitSound("Hero_Lion.FingerOfDeath")
		--target:EmitSound("nero_w")

		local slashFx = ParticleManager:CreateParticle("particles/kinghassan/nero_scorched_earth_child_embers_rosa.vpcf", PATTACH_ABSORIGIN, target )
		ParticleManager:SetParticleControl( slashFx, 0, target:GetAbsOrigin() + Vector(0,0,300))

		Timers:CreateTimer( 2.0, function()
			ParticleManager:DestroyParticle( slashFx, false )
			ParticleManager:ReleaseParticleIndex( slashFx )
		end)

		--[[if caster:HasModifier("modifier_sovereign_attribute") and caster:HasModifier("modifier_aestus_domus_aurea_nero") then               
		    if not target:HasModifier("modifier_rosa_buffer") then
				target:AddNewModifier(caster, self, "modifier_rosa_buffer", { Duration = 3 })
		    end
		end]]

		-- Too dumb to make particles, just call cleave function 4head
		DoCleaveAttack(caster, target, self, 0, 200, 400, 500, "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength.vpcf")

		local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + Vector(0, 0, 80))
		ParticleManager:SetParticleControl(slash_fx, 5, Vector(300, 1, 1))
		ParticleManager:SetParticleControl(slash_fx, 10, Vector(RandomInt(-10, 10), 0, 0))

		Timers:CreateTimer(0.4, function()
			ParticleManager:DestroyParticle(slash_fx, false)
			ParticleManager:ReleaseParticleIndex(slash_fx)
		end)

		self.Target = target

		local slash = 
		{
			Ability = self,
		    EffectName = "",
		    iMoveSpeed = 99999,
		    vSpawnOrigin = caster:GetAbsOrigin(),
		    fDistance = 500,
		    fStartRadius = 200,
		    fEndRadius = 400,
		    Source = caster,
		    bHasFrontalCone = true,
		    bReplaceExisting = true,
		    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		    iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		    fExpireTime = GameRules:GetGameTime() + 2.0,
			bDeleteOnHit = false,
			vVelocity = caster:GetForwardVector() * 500
		}

		local projectile = ProjectileManager:CreateLinearProjectile(slash)

		if target:HasModifier("modifier_airborne_marker") and (target:GetPhysicsVelocity()[3] > 0 or target:GetPhysicsAcceleration()[3] > 0) then
			local duration = 1.5 - target:FindModifierByName("modifier_airborne_marker").elapsed
			local knockupSpeed = target:GetPhysicsVelocity()[3]
			local knockupAcc = target:GetPhysicsAcceleration()[3]
			caster:AddNewModifier(caster, self, "modifier_nero_rosa_new", {duration = duration})
			caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x, caster:GetAbsOrigin().y, target:GetAbsOrigin().z))
			Physics:Unit(caster)
			caster:PreventDI()
		   	caster:SetPhysicsVelocity(Vector(0,0,knockupSpeed))
		   	caster:SetPhysicsAcceleration(Vector(0,0,knockupAcc))
		   	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
		   	caster:FollowNavMesh(false)
		   	caster:Hibernate(false)

		    Timers:CreateTimer(duration, function()
		        caster:PreventDI(false)
		        caster:SetPhysicsVelocity(Vector(0,0,0))
		        caster:SetPhysicsAcceleration(Vector(0,0,0))
		        caster:OnPhysicsFrame(nil)
		        caster:Hibernate(true)
		    end)
		end
	end)
end

function nero_rosa_buffed:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil or hTarget == self.Target then return end

	local damage = self:GetSpecialValueFor("damage")
	local hCaster = self:GetCaster()

	if not hCaster.IsPTBAcquired then
		damage = damage / 2
	end

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	--[[if hCaster:HasModifier("modifier_sovereign_attribute") and hCaster:HasModifier("modifier_aestus_domus_aurea_nero") then               
        if not target:HasModifier("modifier_rosa_buffer") then
        	hTarget:AddNewModifier(hCaster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration") })
        	hTarget:AddNewModifier(hCaster, self, "modifier_rosa_buffer", { Duration = 3 })
        end
    end]]
	
	--hTarget:AddNewModifier(caster, self, "modifier_rosa_buffer", { Duration = 5 })
end