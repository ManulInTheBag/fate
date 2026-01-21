LinkLuaModifier("modifier_ryougi_knife_target", "abilities/ryougi/ryougi_knife_throw", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_knife_swap", "abilities/ryougi/ryougi_knife_throw", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_knife_throw_slow", "abilities/ryougi/ryougi_knife_throw", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_2", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)

ryougi_knife_throw = class({})

function ryougi_knife_throw:OnUpgrade()
	local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_knife_recast"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("ryougi_knife_recast"):SetLevel(self:GetLevel())
    end
end

function ryougi_knife_throw:OnSpellStart()
	local caster = self:GetCaster()
	local tpoint = self:GetCursorPosition()
	local dir = tpoint - caster:GetAbsOrigin()
	dir.z = 0
	if not(tpoint == caster:GetAbsOrigin()) then
		caster:SetForwardVector(dir:Normalized())
	end
 	 local target = caster:GetForwardVector()
  	local range = self:GetSpecialValueFor("range")

	--EmitSoundOn("ryougi_knife_"..math.random(1,2), caster)
	EmitGlobalSound("ryougi_mieta")

	local tProjectile = {
		caster = caster,
		source = caster,
	    EffectName = "particles/ryougi/ryougi_dagger_2.vpcf",
	    ability = self,
	    sourceLoc = caster:GetAbsOrigin(),
	    direction = target,
	    speed = self:GetSpecialValueFor("speed"),
	    distance = range,
	    startRadius = 175,
	    endRadius = 175,
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	    iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	    DeleteOnHit = true,
  	}
 	self.iProjectile = FATE_ProjectileManager:CreateLinearProjectile(tProjectile)
    self.hitenemy = false
end

function ryougi_knife_throw:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if hTarget == nil then
   	return
  	end
  	if (hTarget:GetName() == "npc_dota_ward_base") then
  		return
  	end
	if hTarget:HasModifier("modifier_protection_from_arrows_active") then return end
    if IsSpellBlocked(hTarget) then return end
  	local hCaster = self:GetCaster()
  	local eyes = hCaster:FindAbilityByName("ryougi_mystic_eyes")

  	print("ryougi knife hit target "..hTarget:GetName())
  	
  	if (hCaster:GetAbsOrigin() - hTarget:GetAbsOrigin()):Length2D() <= self:GetSpecialValueFor("bfm_range") then
  		hCaster:FindAbilityByName("ryougi_knife_recast"):StartCombo(hTarget)
  	else
  		hCaster:AddNewModifier(hCaster, self, "modifier_ryougi_knife_swap", {duration = self:GetSpecialValueFor("swap_duration")})
	end
  	hTarget:AddNewModifier(hCaster, self, "modifier_ryougi_knife_target", {duration = self:GetSpecialValueFor("mark_duration")})
  	print("ryougi knife after modifier applied target "..hTarget:GetName())
  	if hCaster.BlackMoonAcquired then
      hTarget:AddNewModifier(hCaster, self, "modifier_ryougi_knife_throw_slow", {duration = self:GetSpecialValueFor("attribute_slow_duration")})
	  hTarget:AddNewModifier(hCaster, self, "modifier_heal_reduction_tier_2", {duration = self:GetSpecialValueFor("attribute_slow_duration")})
    end
    eyes:CutLine(hTarget, "knife_throw")
    DoDamage(hCaster, hTarget, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
  	EmitSoundOn("ryougi_hit", hTarget)
  	--hTarget:EmitSound("Atalanta.RImpact")
   	--EmitGlobalSound("Atalanta.RImpact2")
    self.hitenemy = true
   	--Timers:CreateTimer(0.033,function()
   	--ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	--end)
end

function ryougi_knife_throw:OnProjectileThink_ExtraData(location)
    local caster = self:GetCaster()
    local radius = 100
    local duration = 0.5

    AddFOWViewer(caster:GetTeamNumber(), location, radius, duration, false)
    AddFOWViewer(caster:GetOpposingTeamNumber(), location, 40, 0.4, false)
end

modifier_ryougi_knife_target = class({})

function modifier_ryougi_knife_target:DeclareFunctions()
	return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION}
end

function modifier_ryougi_knife_target:GetModifierProvidesFOWVision()
	if self:GetParent():HasModifier("modifier_murderer_mist_in") then
        return 0
    end
	return 1
end


--[[function modifier_ryougi_knife_target:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()

	if self.caster:GetAbilityByIndex(5):GetName() == "ryougi_knife_throw" then	    		
		self.caster:SwapAbilities("ryougi_knife_recast", "ryougi_knife_throw", true, false)	
	end
end

function modifier_ryougi_knife_target:OnRemoved()
	if not IsServer() then return end
end

function modifier_ryougi_knife_target:OnDestroy()
	if not IsServer() then return end

	if self.caster:GetAbilityByIndex(5):GetName() == "ryougi_knife_recast" then	    		
		self.caster:SwapAbilities("ryougi_knife_recast", "ryougi_knife_throw", false, true)	
	end
end]]

modifier_ryougi_knife_swap = class({})

function modifier_ryougi_knife_swap:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()

	if self.caster:GetAbilityByIndex(5):GetName() == "ryougi_knife_throw" then	    		
		self.caster:SwapAbilities("ryougi_knife_recast", "ryougi_knife_throw", true, false)	
	end
end

function modifier_ryougi_knife_swap:OnRemoved()
	if not IsServer() then return end
end

function modifier_ryougi_knife_swap:OnDestroy()
	if not IsServer() then return end

	if self.caster:GetAbilityByIndex(5):GetName() == "ryougi_knife_recast" then	    		
		self.caster:SwapAbilities("ryougi_knife_recast", "ryougi_knife_throw", false, true)	
	end
end

modifier_ryougi_knife_throw_slow = class({})

function modifier_ryougi_knife_throw_slow:IsHidden() return false end
function modifier_ryougi_knife_throw_slow:IsDebuff() return true end
function modifier_ryougi_knife_throw_slow:RemoveOnDeath() return true end
function modifier_ryougi_knife_throw_slow:DeclareFunctions()
  return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  }
end
function modifier_ryougi_knife_throw_slow:GetModifierMoveSpeedBonus_Percentage()
  return -1*self:GetAbility():GetSpecialValueFor("attribute_slow_percent")
end