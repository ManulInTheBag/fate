karna_brahmastra_kundala_new = karna_brahmastra_kundala_new or class({})
LinkLuaModifier("modifier_karna_no_spear","abilities/karna/karna_new_abilities/karna_brahmastra_kundala_new", LUA_MODIFIER_MOTION_NONE)

modifier_karna_no_spear = class({})

function karna_brahmastra_kundala_new:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("karna_buff_melee"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_buff_melee"):SetLevel(self:GetLevel())
    end


end

function modifier_karna_no_spear:CheckState()
    local state =   { 
		[MODIFIER_STATE_DISARMED] = true,
                    }
    return state
end

function modifier_karna_no_spear:OnCreated() 
	if IsServer() then
		local modifier = self:GetCaster():FindModifierByName("modifier_karna_armor") 
		local caster = self:GetCaster()
		if modifier.ArmorActive == true then
			caster:SetBodygroup(0,2)
		else
			caster:SetBodygroup(0,3)
		end
	end
end

function modifier_karna_no_spear:OnDestroy()
	if IsServer() then
		local modifier = self:GetCaster():FindModifierByName("modifier_karna_armor") 
		local caster = self:GetCaster()
		if modifier.ArmorActive == true then
			caster:SetBodygroup(0,0)
		else
			caster:SetBodygroup(0,1)
		end
	end
end
 
 
function modifier_karna_no_spear:IsHidden() return false end
function modifier_karna_no_spear:RemoveOnDeath() return true end


function karna_brahmastra_kundala_new:CastFilterResultLocation(location)
    local caster = self:GetCaster()
    if IsServer() and  (caster:FindModifierByName("modifier_karna_no_spear")) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function karna_brahmastra_kundala_new:GetCustomCastErrorLocation()
	return "No spear"
end


function karna_brahmastra_kundala_new:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	caster:EmitSound("karna_new_karna_kundala")

	return true 
end
function karna_brahmastra_kundala_new:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()

	caster:StopSound("karna_new_karna_kundala")

	return true 
end

function karna_brahmastra_kundala_new:OnSpellStart()
	local caster = self:GetCaster()

	
    local casterFX = ParticleManager:CreateParticle("particles/karna/karna_spear_init.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControlEnt(casterFX, 1, caster, PATTACH_ABSORIGIN, nil, caster:GetOrigin(), false)
    ParticleManager:ReleaseParticleIndex(casterFX)
	local target = caster:GetForwardVector()
	local range = self:GetSpecialValueFor("range")
	local aoe_damage = self:GetSpecialValueFor("damage")
	if caster.IndraAttribute then
		aoe_damage = aoe_damage + (caster.IndraAttribute and 1 * caster:GetIntellect() or 0)
	end
	caster:AddNewModifier(caster, self, "modifier_karna_no_spear", {duration = self:GetSpecialValueFor("spear_loss_duration")})
	local tProjectile = {
		EffectName = "particles/karna/spear_throw.vpcf",
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = target * 3000,
		fDistance = range,
		fStartRadius = 150,
		fEndRadius = 150,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = 0,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		--bProvidesVision = true,
		bDeleteOnHit = false,
		--iVisionRadius = 500,
		--bFlyingVision = true,
		--iVisionTeamNumber = caster:GetTeamNumber(),
		ExtraData = {fDamage = aoe_damage, fRadius = self:GetSpecialValueFor("radius")}
	}  
	self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
	--self:StartCooldown(self:GetLevel())	  	
	local endpos = caster:GetAbsOrigin() + target * range
	self.spear_position = GetGroundPosition(endpos, caster)
	Timers:CreateTimer((range/2500), function()
		self.endFX = ParticleManager:CreateParticle("particles/karna/karna_spear_in_ground_.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControlTransformForward(self.endFX, 0, self.spear_position, self.spear_position)

		if caster:GetAbilityByIndex(2):GetName() == "karna_brahmastra_kundala_new"   and not  caster:FindModifierByName("modifier_karna_armor").ArmorActive  then
			caster:SwapAbilities("karna_brahmastra_kundala_new", "karna_brahmastra_kundala_retrieve", false, true)
		end
	
	
	

    --ParticleManager:ReleaseParticleIndex(casterFX)
	
	end)

	Timers:CreateTimer("karna_spear_retrieve", {
		endTime =  self:GetSpecialValueFor("spear_loss_duration"),
		callback = function()
			caster:RemoveModifierByName("modifier_karna_no_spear")
			ParticleManager:DestroyParticle(self.endFX, true)
			ParticleManager:ReleaseParticleIndex(self.endFX)
			if caster:GetAbilityByIndex(2):GetName() == "karna_brahmastra_kundala_retrieve" and not not caster:FindModifierByName("modifier_karna_armor").ArmorActive then
				caster:SwapAbilities("karna_brahmastra_kundala_retrieve", "karna_brahmastra_kundala_new", false, true)
			end
		
	return end
	})
	
end

 
 
 
 
 
function karna_brahmastra_kundala_new:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
  	local hCaster = self:GetCaster()
	if(hTarget ~= nil) then


			DoDamage(hCaster, hTarget, tData.fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)

		   hTarget:EmitSound("karna_new_shockwae")

		
	end
	--[[
   	Timers:CreateTimer(0.033,function()
   		ProjectileManager:DestroyLinearProjectile(self.iProjectile)
  	end)
	]]
	--return true
end

function karna_brahmastra_kundala_new:OnProjectileThink(location)
    local caster = self:GetCaster()
    local radius = 100
    local duration = 0.5

	AddFOWViewer(2, location, 40, 0.4, false)
    AddFOWViewer(3, location, 40, 0.4, false)
end
 