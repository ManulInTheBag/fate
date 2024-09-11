LinkLuaModifier("modifier_nanaya_knife_recast", "abilities/nanaya/nanaya_new/nanaya_knife", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nanaya_combo", "abilities/nanaya/nanaya_new/nanaya_knife", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nanaya_combo_enemy", "abilities/nanaya/nanaya_new/nanaya_knife", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nanaya_combo_active", "abilities/nanaya/nanaya_new/nanaya_knife", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nanaya_combo_window", "abilities/nanaya/nanaya_new/nanaya_knife", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nanaya_kekshi_cd", "abilities/nanaya/nanaya_new/nanaya_knife", LUA_MODIFIER_MOTION_NONE)

nanaya_knife = class({})

function nanaya_knife:GetBehavior()
	if self:GetCaster():HasModifier("modifier_nanaya_combo_window") then
		return (DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING)
	end
	return (DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING)
end

function nanaya_knife:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_nanaya_combo_window") then
		return "custom/nanaya/nanaya_combo"
	end
	return "custom/nanaya/nanaya-e"
end

function nanaya_knife:GetManaCost()
	if self:GetCaster():HasModifier("modifier_nanaya_combo_window") then
		return 0
	end
	return 200
end

function nanaya_knife:OnUpgrade()
	local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("nanaya_knife_recast"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("nanaya_knife_recast"):SetLevel(self:GetLevel())
    end
end

function nanaya_knife:OnSpellStart()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_nanaya_combo_window") then
		caster:FindAbilityByName("nanaya_kekshi"):OnComboExecuted()
		return
	end

	local range = self:GetSpecialValueFor("range")
	local speed = self:GetSpecialValueFor("speed")

	local justpoint = self:GetCursorPosition()
	if justpoint == caster:GetAbsOrigin() then
		justpoint = caster:GetAbsOrigin() + caster:GetForwardVector()
	end
	local hTarget = (justpoint - caster:GetAbsOrigin()):Normalized()

	local nanaya_knife = ParticleManager:CreateParticle("particles/nanaya_knifethrow.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(nanaya_knife, 0, caster:GetAbsOrigin() + caster:GetForwardVector() * 75)
	ParticleManager:SetParticleControl(nanaya_knife, 1, caster:GetAbsOrigin() + (caster:GetForwardVector():Normalized()))
	caster:EmitSound("nanaya.knifethrow")

	local hKnifeProjectile =    {
		Source            = caster,
		Ability           = self,
		vSpawnOrigin      = caster:GetAbsOrigin() + caster:GetForwardVector()*90,
			
		iUnitTargetTeam   = self:GetAbilityTargetTeam(),
		iUnitTargetType   = self:GetAbilityTargetType(),
		iUnitTargetFlags  = self:GetAbilityTargetFlags(),
			
		EffectName        = "particles/heroes/anime_hero_sniper/sniper_knife_projectile.vpcf",
		fDistance         = range,
		fStartRadius      = 150,
		fEndRadius        = 150,
		vVelocity         = Vector(hTarget.x,hTarget.y,0) * speed,
			
		bHasFrontalCone   = false,
			
		bProvidesVision   = true,
		iVisionRadius     = 150,
		iVisionTeamNumber = caster:GetTeamNumber()
	}
	local iKnifeProjectile = ProjectileManager:CreateLinearProjectile(hKnifeProjectile)

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    if caster:FindAbilityByName("nanaya_kekshi"):IsCooldownReady() and caster:IsAlive() then	    		
	    	caster:AddNewModifier(caster, self, "modifier_nanaya_combo_window", {duration = 3})
		end
	end
end

function nanaya_knife:OnProjectileHitHandle(hTarget, vLocation, iProjectileHandle)
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_nanaya_combo_window")

	if hTarget == nil then
		caster:RemoveModifierByName("modifier_nanaya_combo_active")
		return true
	end

	if caster:HasModifier("modifier_nanaya_combo_active") then
		caster:FindAbilityByName("nanaya_kekshi"):ExecuteCombo(caster, hTarget)
		caster:RemoveModifierByName("modifier_nanaya_combo_active")
		return true
	end

	caster:RemoveModifierByName("modifier_nanaya_combo_active")

	local damage = self:GetSpecialValueFor("dmg_knife") + ((caster.ScaleAcquired and caster:HasModifier("modifier_nanaya_instinct")) and caster:GetAgility()*self:GetSpecialValueFor("attribute_knife_agility_multiplier") or 0)

	ProjectileManager:ProjectileDodge(caster)

	local prev_pos = caster:GetAbsOrigin()
	local position = hTarget:GetAbsOrigin()

	local dir = (prev_pos - position):Normalized()

	FindClearSpaceForUnit(caster, position + dir*100, false)

	caster:SetForwardVector(Vector(-dir.x, -dir.y, 0))

	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_3, 5)

	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

	local culling_kill_particle = ParticleManager:CreateParticle("particles/nanaya_work_2_great.vpcf", PATTACH_ABSORIGIN, hTarget)
	local jump2 = ParticleManager:CreateParticle("particles/shiki_blink_after.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(jump2, 0, caster:GetAbsOrigin()+ caster:GetForwardVector()*-90)
	ParticleManager:SetParticleControl(jump2, 4, hTarget:GetAbsOrigin())
	local part = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(part, 0, caster:GetAbsOrigin()+ caster:GetForwardVector()*-400)

	hTarget:EmitSound("nanaya.knifehit")

	local modifier = caster:AddNewModifier(caster, self, "modifier_nanaya_knife_recast", {duration = self:GetSpecialValueFor("window_duration")})
	modifier.target = hTarget

	return true
end

modifier_nanaya_combo_window = class({})

function modifier_nanaya_combo_window:IsHidden() return true end
function modifier_nanaya_combo_window:IsDebuff() return false end
function modifier_nanaya_combo_window:OnCreated()
	if IsServer() then
		local caster = self:GetParent()

		local ability = self:GetAbility()
		ability:EndCooldown()
		--[[if caster:GetAbilityByIndex(1):GetName() == "nanaya_knife" then	    		
			caster:SwapAbilities("nanaya_kekshi", "nanaya_knife", true, false)	
		end]]
	end
end
function modifier_nanaya_combo_window:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()

		local ability = self:GetAbility()
		ability:StartCooldown(ability:GetCooldown(-1))
		--[[if caster:GetAbilityByIndex(1):GetName() == "nanaya_kekshi" then
			caster:SwapAbilities("nanaya_kekshi", "nanaya_knife", false, true)
		end]]
	end
end

modifier_nanaya_combo_active = class({})

function modifier_nanaya_combo_active:IsHidden() return true end
function modifier_nanaya_combo_active:IsDebuff() return false end

nanaya_kekshi = class({})

function nanaya_kekshi:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_nanaya_combo_active", {duration = 5})
end

function nanaya_kekshi:OnComboExecuted()
	local caster = self:GetCaster()

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(-1))
    self:EndCooldown()
    self:StartCooldown(self:GetCooldown(-1))

    caster:RemoveModifierByName("modifier_nanaya_combo_window")

    caster:AddNewModifier(caster, self, "modifier_nanaya_kekshi_cd", {duration = self:GetCooldown(1)})

	caster:AddNewModifier(caster, self, "modifier_nanaya_combo_active", {duration = 5})
end

function nanaya_kekshi:ExecuteCombo(caster, target)
	local damage = self:GetSpecialValueFor("damage")
	PlayerResource:SetCameraTarget(target:GetPlayerID(), caster)
	PlayerResource:SetCameraTarget(caster:GetPlayerID(), caster)
	local combo_part = ParticleManager:CreateParticle(nil, PATTACH_ABSORIGIN_FOLLOW, target)
	EmitGlobalSound("nanaya.combo_execute")

	caster:Stop()
	target:AddNewModifier(caster, caster, "modifier_nanaya_combo_enemy", {Duration = 2})
	caster:AddNewModifier(caster, caster, "modifier_nanaya_combo", {Duration = 2})
	target:Stop()

	local sec1 = caster:GetOrigin()

	local targetabs = target:GetAbsOrigin()
	caster:SetAbsAngles(0, 0, 0)
	target:SetAbsAngles(0, 0, 0)
	caster:SetForwardVector(Vector(-1, 0, 0))
	target:SetForwardVector(Vector(1, 0, 0))
	local targetforwardvector = target:GetForwardVector()
	local player = target:GetPlayerOwner()
	local player2 = caster:GetPlayerOwner()
	local ff2 = math.floor(target:GetLocalAngles().y)

	local nanaya_knife2 = nil
				
	caster:StartGestureWithPlaybackRate(ACT_SCRIPT_CUSTOM_16, 1.4)
	caster:SetOrigin(targetabs + targetforwardvector*90)


	Timers:CreateTimer(0.15, function()
		caster:EmitSound("nanaya.kekshi1")
		local nanaya_knife = ParticleManager:CreateParticle("particles/nanaya_last_arc.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(nanaya_knife, 0, caster, PATTACH_POINT, "attach_knife", caster:GetAbsOrigin(), true)

		local nanaya_knife1 = ParticleManager:CreateParticle("particles/nanaya_last_arc2.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(nanaya_knife1, 0, caster, PATTACH_POINT_FOLLOW, "attach_knife", caster:GetAbsOrigin(), true)

		Timers:CreateTimer(0.30, function()
			local knife = ParticleManager:CreateParticle("particles/maybedashvpcffinalfinal.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControlEnt(knife, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand", caster:GetAbsOrigin(), true)
			ParticleManager:SetParticleControl(knife, 4, target:GetAbsOrigin())
		end)

		Timers:CreateTimer(0.350, function()
			ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark.vpcf", PATTACH_EYES_FOLLOW, caster, player)
			ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark.vpcf", PATTACH_EYES_FOLLOW, caster, player2)

			local nanaya_hit = target:GetAbsOrigin() + Vector(0, 0, (target:GetAttachmentOrigin(0).z - target:GetOrigin().z)) + caster:GetForwardVector()*-45
			caster:SetOrigin(nanaya_hit)
			nanaya_knife2 = ParticleManager:CreateParticle("particles/test_part2.vpcf", PATTACH_CUSTOMORIGIN, caster)

			ParticleManager:SetParticleControl(nanaya_knife2, 0, targetabs + Vector (0, 0, 100))
		end)
	end)

	Timers:CreateTimer(1.20, function()

		ScreenShake(targetabs, 14, 20, 1, 2000, 0, true)

		local nanaya_knife1 = ParticleManager:CreateParticle("particles/pa_arcana_phantom_strike_end2.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(nanaya_knife1, 0, caster, PATTACH_POINT, "attach_hand", caster:GetAbsOrigin(), true)

		Timers:CreateTimer(0.5, function()
			local nanaya_knife10 = ParticleManager:CreateParticle("particles/maybedashvpcffinalfinal.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControlEnt(nanaya_knife10, 0, caster, PATTACH_POINT_FOLLOW, "attach_hand", caster:GetAbsOrigin(), true)
			ParticleManager:SetParticleControl(nanaya_knife10, 4, targetabs + targetforwardvector*300)
			ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark.vpcf", PATTACH_EYES_FOLLOW, caster, player)
			ParticleManager:CreateParticleForPlayer("particles/screen_spla22_ark.vpcf", PATTACH_EYES_FOLLOW, caster, player2)
			ParticleManager:DestroyParticle(combo_part, true)

			caster:SetForwardVector(Vector(-1, 0, 0))

			FindClearSpaceForUnit(caster, target:GetAbsOrigin() + caster:GetForwardVector()*-300, false)

			caster:RemoveModifierByName("modifier_nanaya_combo")
			target:RemoveModifierByName("modifier_nanaya_combo")

			local instinct_modifier = caster:FindModifierByName("modifier_nanaya_instinct_passive")

			if instinct_modifier:GetStackCount() < 9 then
				instinct_modifier:SetStackCount(9)
			end
			DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)

			local check1 = ParticleManager:CreateParticle("particles/ls_ti10_immortal_infest_groundfollow_trace.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(check1, 0, target:GetAbsOrigin())

			Timers:CreateTimer(0.135, function()
				local effect_cast = ParticleManager:CreateParticle( "particles/justcheck.vpcf", PATTACH_CUSTOMORIGIN, target)
				ParticleManager:SetParticleControl(effect_cast, 0, target:GetAbsOrigin() + Vector(0, 0, 150))
				ParticleManager:SetParticleControlForward(effect_cast, 1, (target:GetOrigin()-caster:GetOrigin()):Normalized() )

				PlayerResource:SetCameraTarget(caster:GetPlayerID(), nil)
				PlayerResource:SetCameraTarget(target:GetPlayerID(), nil)
			end)
		end)
	end)
end

modifier_nanaya_combo = class({})

function modifier_nanaya_combo:IsHidden() return true end

function modifier_nanaya_combo:CheckState()
	local funcs = {
		--[MODIFIER_STATE_COMMAND_RESTRICTED] = true, 
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
	}
	return funcs
end

modifier_nanaya_combo_enemy = class({})

function modifier_nanaya_combo_enemy:IsHidden() return true end

function modifier_nanaya_combo_enemy:CheckState()
	local funcs = {
		--[MODIFIER_STATE_COMMAND_RESTRICTED] = true, 
		--[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_STUNNED] = true,
		--[MODIFIER_STATE_INVULNERABLE] = true,
	}
	return funcs
end

modifier_nanaya_knife_recast = class({})

function modifier_nanaya_knife_recast:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()

	if self.caster:GetAbilityByIndex(1):GetName() == "nanaya_knife" then	    		
		self.caster:SwapAbilities("nanaya_knife_recast", "nanaya_knife", true, false)	
	end
end

function modifier_nanaya_knife_recast:OnDestroy()
	if not IsServer() then return end

	if self.caster:GetAbilityByIndex(1):GetName() == "nanaya_knife_recast" then	    		
		self.caster:SwapAbilities("nanaya_knife_recast", "nanaya_knife", false, true)	
	end
end

function modifier_nanaya_knife_recast:IsHidden() return true end

nanaya_knife_recast = class({})

function nanaya_knife_recast:CastFilterResult()
	local caster = self:GetCaster()
	if IsServer() then
		local target = caster:FindModifierByName("modifier_nanaya_knife_recast").target
		if not target then return UF_FAIL_CUSTOM end
		local dist = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()

		if dist > self:GetSpecialValueFor("recast_range") then 
			return UF_FAIL_CUSTOM 
		end
	end
	return UF_SUCCESS
end

function nanaya_knife_recast:GetCustomCastError()
    return "#Target_out_of_range"
end

function nanaya_knife_recast:OnSpellStart()
	local caster = self:GetCaster()
	local target = caster:FindModifierByName("modifier_nanaya_knife_recast").target
	local damage = self:GetSpecialValueFor("damage") + ((caster.ScaleAcquired and caster:HasModifier("modifier_nanaya_instinct")) and caster:GetAgility()*self:GetSpecialValueFor("attribute_agility_multiplier") or 0)

	local dist = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()

	if (dist - 150) > (self:GetSpecialValueFor("recast_range")) then
		self:EndCooldown()
		return 
	end

	caster:RemoveModifierByName("modifier_nanaya_knife_recast")

	local position = target:GetAbsOrigin()
	local dir = (caster:GetAbsOrigin() - position):Normalized()

	FindClearSpaceForUnit(caster, position + dir*100, false)

	local jump = ParticleManager:CreateParticle("particles/blink.vpcf", PATTACH_CUSTOMORIGIN, caster)
			
	ParticleManager:SetParticleControl(jump, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*-90)
			
	local jump2 = ParticleManager:CreateParticle("particles/shiki_blink_after.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(jump2, 0, caster:GetAbsOrigin()+ caster:GetForwardVector()*-250)
	ParticleManager:SetParticleControl(jump2, 4, target:GetAbsOrigin())
			
			
	local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(dagon_particle, 1,  target:GetAbsOrigin()+Vector(0, 0, 150))
	local particle_effect_intensity = 500
	ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
			
	local knockback1 = { should_stun = true,
		knockback_duration = 0.3,
		duration = 0.3,
		knockback_distance = 400,
		knockback_height = 0,
		center_x = target:GetAbsOrigin().x,
		center_y = target:GetAbsOrigin().y,
		center_z = target:GetAbsOrigin().z }

	caster:EmitSound("nanaya.slash")
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)	
			
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
		ParticleManager:ReleaseParticleIndex(culling_kill_particle)		
	end)
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_2, 1.4)
	caster:RemoveModifierByName("modifier_knockback")
	caster:AddNewModifier(caster, self, "modifier_knockback", knockback1)
end

--

modifier_nanaya_kekshi_cd = class({})

function modifier_nanaya_kekshi_cd:GetTexture()
	return "custom/nanaya/nanaya_combo"
end

function modifier_nanaya_kekshi_cd:IsHidden()
	return false 
end

function modifier_nanaya_kekshi_cd:RemoveOnDeath()
	return false
end

function modifier_nanaya_kekshi_cd:IsDebuff()
	return true 
end

function modifier_nanaya_kekshi_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end