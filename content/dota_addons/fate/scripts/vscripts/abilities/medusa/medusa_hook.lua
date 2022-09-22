LinkLuaModifier("modifier_imba_pudge_meat_hook_caster_root","abilities/medusa/medusa_hook", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_hook_target_enemy","abilities/medusa/medusa_hook", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_hook_target_ally","abilities/medusa/medusa_hook", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)
require('rider_ability')

imba_pudge_meat_hook = class({})

function imba_pudge_meat_hook:OnAbilityPhaseStart()
	if self.launched then
		return false
	end
	return true
end

function imba_pudge_meat_hook:GetCastRange()
	return self:GetSpecialValueFor("base_range")
end

function imba_pudge_meat_hook:OnAbilityPhaseInterrupted()
	self.launched = false
end

function imba_pudge_meat_hook:OnSpellStart()
	self.launched = true

	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_imba_pudge_meat_hook_caster_root", {})
	
	local vHookOffset = Vector( 0, 0, 96 )
	local target_position = GetGroundPosition(self:GetCursorPosition() + vHookOffset, self:GetCaster())

	RiderCheckCombo(self:GetCaster(), self)

	-- Preventing projectiles getting stuck in one spot due to potential 0 length vector
	if target_position == self:GetCaster():GetAbsOrigin() then
		target_position = target_position + self:GetCaster():GetForwardVector()
	end

	local hook_width = self:GetSpecialValueFor("hook_width")
	local hook_speed = self:GetSpecialValueFor("base_speed")
	-- local hook_range = self:GetSpecialValueFor("base_range") + self:GetCaster():FindTalentValue("special_bonus_imba_pudge_5")
	local hook_dmg = self:GetSpecialValueFor("base_damage")

	self.chTarget = CreateUnitByName("hrunt_illusion", self:GetCaster():GetAbsOrigin(), true, self:GetCaster(), nil, self:GetCaster():GetTeamNumber())
	self.chTarget2 = CreateUnitByName("hrunt_illusion", self:GetCaster():GetAbsOrigin(), true, self:GetCaster(), nil, self:GetCaster():GetOpposingTeamNumber())

	self.chTarget:SetModel("models/development/invisiblebox.vmdl")
    self.chTarget:SetOriginalModel("models/development/invisiblebox.vmdl")
    self.chTarget:SetModelScale(1)
    local unseen = self.chTarget:FindAbilityByName("dummy_unit_passive")
    unseen:SetLevel(1)

    local unseen2 = self.chTarget2:FindAbilityByName("dummy_unit_passive")
    unseen2:SetLevel(1)

    self.chTarget2:SetModel("models/development/invisiblebox.vmdl")
    self.chTarget2:SetOriginalModel("models/development/invisiblebox.vmdl")
    self.chTarget2:SetModelScale(1)

	Timers:CreateTimer(30, function()
		if IsValidEntity(self.chTarget2) and not self.chTarget2:IsNull() then 
            self.chTarget2:ForceKill(false)
            self.chTarget2:AddEffects(EF_NODRAW)
            --illusion:SetAbsOrigin(Vector(10000,10000,0))
    	end
    end)

	--[[
	pfx shit:
	cp 0: pudge's hand
	cp 1: target position
	cp 2: speed, distance, width
	cp 3: max duration, 0, 0
	cp 4: 1,0,0
	cp 5: 0,0,0
	]]
	--[[finall date:
	hook_speed
	hook_range
	hook_dmg
	hook_width
	]]

--	if not self:GetCaster().hook_pfx then
		--self:GetCaster().hook_pfx = "particles/units/heroes/hero_pudge/pudge_meathook.vpcf"
--		self:GetCaster().hook_pfx = "particles/econ/items/pudge/pudge_dragonclaw/pudge_meathook_dragonclaw_imba.vpcf"
--	end

	local vKillswitch = Vector(((self:GetCastRange() / hook_speed) * 2) + 10, 0, 0)
	local hook_particle = ParticleManager:CreateParticle("particles/medusa/medusa_hook.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
	ParticleManager:SetParticleAlwaysSimulate(hook_particle)
	ParticleManager:SetParticleControl(hook_particle, 1, GetGroundPosition(self:GetCaster():GetAbsOrigin() + self:GetCastRange()*self:GetCaster():GetForwardVector(), self:GetCaster()))
	ParticleManager:SetParticleControlEnt(hook_particle, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hand1", self:GetCaster():GetAbsOrigin() + vHookOffset, true)
	ParticleManager:SetParticleControl(hook_particle, 2, Vector(hook_speed, self:GetCastRange(), hook_width))
	ParticleManager:SetParticleControl(hook_particle, 3, vKillswitch)
	ParticleManager:SetParticleControl(hook_particle, 4, Vector( 1, 0, 0 ) )
	ParticleManager:SetParticleControl(hook_particle, 5, Vector( 0, 0, 0 ) )
	ParticleManager:SetParticleControl(hook_particle, 7, Vector(1, 0, 0))
	
--	if self:GetCaster().hook_pfx == "particles/units/heroes/hero_pudge/pudge_meathook.vpcf" then
--		ParticleManager:SetParticleControlEnt(hook_particle, 7, self:GetCaster(), PATTACH_CUSTOMORIGIN, nil, self:GetCaster():GetOrigin(), true)
--	end

	local projectile_info = {
		Ability = self,
		EffectName = nil,
		vSpawnOrigin = self:GetCaster():GetAbsOrigin(),
		fDistance = self:GetCastRange(),
		fStartRadius = hook_width,
		fEndRadius = hook_width,
		Source = self:GetCaster(),
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
		iUnitTargetFlags = nil,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime = GameRules:GetGameTime() + (self:GetCastRange() / hook_speed),
		vVelocity = (target_position - self:GetCaster():GetAbsOrigin()):Normalized() * hook_speed * Vector(1, 1, 0),
		bProvidesVision = false,
		bDeleteOnHit = true,
		ExtraData = {
			hook_width = hook_width,
			hook_dmg = hook_dmg,
			hook_spd = hook_speed,
			pfx_index = hook_particle,
			goorback = "go",
			rune = -1,
		}
	}
	self.hook_go = ProjectileManager:CreateLinearProjectile(projectile_info)

	--EmitSoundOnLocationWithCaster(self:GetCaster():GetAbsOrigin(), "Hero_Pudge.AttackHookExtend", self:GetCaster())
	self:GetCaster():EmitSound("Rider.NailSwing")
end

local hooked_loc
function imba_pudge_meat_hook:OnProjectileThink_ExtraData(vLocation, ExtraData)
	self.chTarget:SetAbsOrigin(vLocation)
	if self.chTarget2:CanEntityBeSeenByMyTeam(self.chTarget) then
		self:GetCaster():AddNewModifier(nil, nil, "modifier_vision_provider", { Duration = 0.1 })
	end
	if ExtraData.goorback ~= "back" then
		hooked_loc = vLocation
	elseif ExtraData.goorback == "back" then
			local target = EntIndexToHScript(ExtraData.hooked_target)
			local caster = EntIndexToHScript(ExtraData.hooked_caster)
			if (self.prev_origin - target:GetAbsOrigin()):Length2D() > 400 then
				local buff1 = target:FindModifierByName("modifier_imba_hook_target_enemy")
				local buff2 = target:FindModifierByName("modifier_imba_hook_target_ally")
				if buff1 then buff1:Destroy() end
				if buff2 then buff2:Destroy() end
				ProjectileManager:DestroyTrackingProjectile(self.pepe_pro)
				self.launched = false
				return
			end
			self.prev_origin = target:GetAbsOrigin()

			if (target:GetAbsOrigin() - self.chTarget2:GetAbsOrigin()):Length2D() > (self:GetCastRange() + 100) then
				local buff1 = target:FindModifierByName("modifier_imba_hook_target_enemy")
				local buff2 = target:FindModifierByName("modifier_imba_hook_target_ally")
				if buff1 then buff1:Destroy() end
				if buff2 then buff2:Destroy() end
				ProjectileManager:DestroyTrackingProjectile(self.pepe_pro)
				self.launched = false
				return
			end
			
			if not target or not target.IsNull or target:IsNull() then return end
			
			local location = vLocation + (self.chTarget2:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * (ExtraData.hook_spd / (1 / FrameTime()))
			target:SetAbsOrigin(GetGroundPosition(vLocation, target))
	end
end

function imba_pudge_meat_hook:OnProjectileHit_ExtraData(hTarget, vLocation, ExtraData)
	if IsValidEntity(self.chTarget) and not self.chTarget:IsNull() then 
            self.chTarget:ForceKill(false)
            self.chTarget:AddEffects(EF_NODRAW)
            --illusion:SetAbsOrigin(Vector(10000,10000,0))
    end
	if hTarget then
		local buff1 = hTarget:FindModifierByName("modifier_imba_hook_target_enemy")
		local buff2 = hTarget:FindModifierByName("modifier_imba_hook_target_ally")
	end

	if ExtraData.goorback == "go" then
		if self:GetCaster() == hTarget or buff1 or buff2 then
			return
		end
		local root_buff = self:GetCaster():FindModifierByName("modifier_imba_pudge_meat_hook_caster_root")
		if root_buff then
			root_buff:Destroy()
		end
		ParticleManager:SetParticleControl(ExtraData.pfx_index, 4, Vector( 0, 0, 0 ) )
		ParticleManager:SetParticleControl(ExtraData.pfx_index, 5, Vector( 1, 0, 0 ) )
		local target = hTarget
		local caster = self:GetCaster()
		local bVision = false

		if not target then
			target = CreateUnitByName("npc_dummy_unit", vLocation, false, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
			local unseen = target:FindAbilityByName("lancer_trap_passive")
    		unseen:SetLevel(1)
    		caster = target
    		target = self:GetCaster()
		end

		ParticleManager:SetParticleControlEnt(ExtraData.pfx_index, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin() + Vector(0,0,96), true)

		if hTarget then
			--EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Pudge.AttackHookImpact", hTarget, self:GetCaster())
			--EmitSoundOnLocationWithCaster(hTarget:GetAbsOrigin(), "Hero_Pudge.AttackHookRetract", hTarget)
			self:GetCaster():EmitSound("Rider.NailSwing")
			bVision = true
			if hTarget:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
				--[[local dmg = ExtraData.hook_dmg
				local damageTable = {
					victim = hTarget,
					attacker = self:GetCaster(),
					damage = dmg,
					damage_type = DAMAGE_TYPE_PURE,
					damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
					ability = self, --Optional.
				}
				local actually_dmg = ApplyDamage(damageTable)]]
				--hTarget:AddNewModifier(self:GetCaster(), self, "modifier_imba_hook_target_enemy", {})
			--elseif hTarget:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
				--hTarget:AddNewModifier(self:GetCaster(), self, "modifier_imba_hook_target_ally", {})
			end
		end


		local projectile_info = {
			Target = target,
			Source = caster,
			Ability = self,
			EffectName = nil,
			iMoveSpeed = ExtraData.hook_spd,
			vSourceLoc = caster:GetAbsOrigin(),
			bDrawsOnMinimap = false,
			bDodgeable = false,
			bIsAttack = false,
			bVisibleToEnemies = true,
			bReplaceExisting = false,
			bProvidesVision = bVision,
			iVisionRadius = 400,
			iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
			ExtraData = {
				hooked_target = caster:entindex(),
				hooked_caster = target:entindex(),
				hook_spd = ExtraData.hook_spd,
				pfx_index = ExtraData.pfx_index,
				goorback = "back",
				rune = ExtraData.rune,
			}
		}
		self.prev_origin = caster:GetAbsOrigin()
		self.pepe_pro = ProjectileManager:CreateTrackingProjectile(projectile_info)
		if self.hook_go then
			ProjectileManager:DestroyLinearProjectile(self.hook_go)
		end
		return true
	end

	if ExtraData.goorback == "back" then
		ParticleManager:DestroyParticle(ExtraData.pfx_index, true)
		ParticleManager:ReleaseParticleIndex(ExtraData.pfx_index)

		local target = EntIndexToHScript(ExtraData.hooked_target)
		
		if not target or not target.IsNull or target:IsNull() then
			self.launched = false
			return
		end
		local caster = EntIndexToHScript(ExtraData.hooked_caster)

		if target:GetTeam()~=caster:GetTeam() and ((target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() < 300) then
			DoDamage(target, caster, self:GetSpecialValueFor("base_damage"), self:GetAbilityDamageType(), 0, self, false)
		end
		
		target:SetUnitOnClearGround()
		if target:GetUnitName() == "npc_dummy_unit" then
			target:ForceKill(false)
		end

		if IsValidEntity(self.chTarget2) and not self.chTarget2:IsNull() then 
            self.chTarget2:ForceKill(false)
            self.chTarget2:AddEffects(EF_NODRAW)
            --illusion:SetAbsOrigin(Vector(10000,10000,0))
    	end

		local buff1 = target:FindModifierByName("modifier_imba_hook_target_enemy")
		local buff2 = target:FindModifierByName("modifier_imba_hook_target_ally")
		if buff1 then buff1:Destroy() end
		if buff2 then buff2:Destroy() end

		self.launched = false
		return true
	end
end

modifier_imba_pudge_meat_hook_caster_root = modifier_imba_pudge_meat_hook_caster_root or class({})

function modifier_imba_pudge_meat_hook_caster_root:IsDebuff() return true end
function modifier_imba_pudge_meat_hook_caster_root:IsHidden() return true end
function modifier_imba_pudge_meat_hook_caster_root:IsPurgable() return false end
function modifier_imba_pudge_meat_hook_caster_root:IsStunDebuff() return false end
function modifier_imba_pudge_meat_hook_caster_root:RemoveOnDeath() return true end

function modifier_imba_pudge_meat_hook_caster_root:CheckState()
	local state =
		{
			--[MODIFIER_STATE_ROOTED] = true,
		}
	return state
end

modifier_imba_hook_target_enemy = modifier_imba_hook_target_enemy or class({})

function modifier_imba_hook_target_enemy:IsDebuff()
	if self:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then
		return false
	else
		return true
	end
end

function modifier_imba_hook_target_enemy:IsHidden() return false end
function modifier_imba_hook_target_enemy:IsPurgable() return false end
function modifier_imba_hook_target_enemy:IsStunDebuff() return false end
function modifier_imba_hook_target_enemy:RemoveOnDeath() return false end
function modifier_imba_hook_target_enemy:IsMotionController()  return true end
function modifier_imba_hook_target_enemy:GetMotionControllerPriority()  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST end

-- Adding this to prevent bricking from Rubick
function modifier_imba_hook_target_enemy:OnCreated()
	self:StartIntervalThink(1)
end

function modifier_imba_hook_target_enemy:OnIntervalThink()
	if not self:GetAbility() then
		self:Destroy()
	end
end

function modifier_imba_hook_target_enemy:CheckState()
	local state_ally =
		{
			[MODIFIER_STATE_ROOTED] = true,
		}
	local state_enemy =
		{
			--[MODIFIER_STATE_STUNNED] = true,
		}
	if self:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then
		return state_ally
	else
		return state_enemy
	end
end

modifier_imba_hook_target_ally = modifier_imba_hook_target_ally or class({})

function modifier_imba_hook_target_ally:IsDebuff()
	if self:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then
		return false
	else
		return true
	end
end

function modifier_imba_hook_target_ally:IsHidden() return false end
function modifier_imba_hook_target_ally:IsPurgable() return false end
function modifier_imba_hook_target_ally:IsStunDebuff() return false end
function modifier_imba_hook_target_ally:RemoveOnDeath() return false end
function modifier_imba_hook_target_ally:IsMotionController()  return true end
function modifier_imba_hook_target_ally:GetMotionControllerPriority()  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST end

function modifier_imba_hook_target_ally:CheckState()
	local state_ally =
		{
			[MODIFIER_STATE_ROOTED] = true,
		}
	local state_enemy =
		{
			--[MODIFIER_STATE_STUNNED] = true,
		}
	if self:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then
		return state_ally
	else
		return state_enemy
	end
end