hijikata_ult = class({})

LinkLuaModifier("modifier_hijikata_ult_slow_powerful", "abilities/hijikata/hijikata_ult", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_ult_slow", "abilities/hijikata/hijikata_ult", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_ult_stacks", "abilities/hijikata/hijikata_ult", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_hijikata_dovodka", "abilities/hijikata/hijikata_ult", LUA_MODIFIER_MOTION_NONE)
function hijikata_ult:GetIntrinsicModifierName()
	return "modifier_hijikata_ult_stacks"
end

function hijikata_ult:GetCastRange()
	local range = self:GetSpecialValueFor("distance") * (self:GetCaster().bSoundReady and 1.5 or 1)
	return range
end
function hijikata_ult:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local range = self:GetSpecialValueFor("distance")
	local target = -(caster:GetAbsOrigin() - (self:GetCursorPosition()+ RandomVector(1))):Normalized() 
	target.z = 0
	local bSoundReady = false
	local bUpgradedUlt = false
	caster:SetForwardVector(target)
	local anim_rate = 0.8/self:GetSpecialValueFor("delay")
	local duration = self:GetSpecialValueFor("delay") + 0.3 / anim_rate
	StartAnimation(caster, {duration=self:GetSpecialValueFor("delay") + 0.3 , activity=ACT_DOTA_CAST_ABILITY_6, rate=anim_rate})
	caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = self:GetSpecialValueFor("delay")}) 
	AddFOWViewer(2, caster:GetAbsOrigin(), 40, 0.9, false)
	AddFOWViewer(3, caster:GetAbsOrigin(), 40, 0.9, false)
	local origin = caster:GetAbsOrigin() +caster:GetForwardVector()*60 + Vector(0,0,200) + caster:GetRightVector() * -30
	local radius = self:GetSpecialValueFor("width")
	local rangeJopa = range
	if caster:FindModifierByName("modifier_hijikata_ult_stacks"):GetStackCount() >= 99 then
		radius = self:GetSpecialValueFor("max_stacks_width")
	end
	if caster:HasModifier("modifier_hijikata_combo_ticker") and caster.bSoundReady then
		radius = 300
		rangeJopa = range * 1.5
	end
	

	self.particle =    ParticleManager:CreateParticle("particles/hijikata/hijikata_ult_ground_marker.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleShouldCheckFoW(self.particle, false)
	ParticleManager:SetParticleControl(self.particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.particle, 1, origin)
	ParticleManager:SetParticleControl(self.particle, 2, origin + target * (rangeJopa+ 300) )
	ParticleManager:SetParticleControl(self.particle, 3, Vector(radius, 0, 0))

	if caster:HasModifier("modifier_hijikata_combo_ticker") and caster.bSoundReady then
		Timers:CreateTimer(0.2, function() 
			caster:EmitSound("hijikata_np_4")
			caster.bSoundReady = false
			bSoundReady = true
			bUpgradedUlt = true
		end)

	else
		EmitSoundOn("hijikata_shinei", caster)
	end
	
    Timers:CreateTimer(0.8/anim_rate, function() 
		if not caster:IsAlive() then return end
		if caster:HasModifier("modifier_hijikata_combo_ticker")  and bSoundReady then
			caster:EmitSound("hijikata_cannon")
			caster:EmitSound("hijikata_shot")
			bSoundReady = false
		else
			caster:EmitSound("hijikata_shot")
		end
		origin = caster:GetAbsOrigin() +caster:GetForwardVector()*60 + Vector(0,0,200) + caster:GetRightVector() * -30--caster:GetAttachmentOrigin(4)
		ParticleManager:SetParticleControl(self.particle, 1, origin)
		ParticleManager:SetParticleControl(self.particle, 2, origin + target * rangeJopa)
		ParticleManager:ReleaseParticleIndex(self.particle)
		local tProjectile = {}
		if bUpgradedUlt then 

			 tProjectile = {
				EffectName = "particles/hijikata/hijikata_bullet_combo.vpcf",
				Ability = self,
				vSpawnOrigin = origin,
				vVelocity = target * 4000,
				fDistance = range*1.5,
				fStartRadius = 300,
				fEndRadius = 300,
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
				ExtraData = {fDamage = self:GetSpecialValueFor("damage_combo"), velocityX = target.x, velocityY = target.y}
			 	}
				local particle = ParticleManager:CreateParticle("particles/units/hijikata/ult/hijikata_ult_combo.vpcf", PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControlTransformForward(particle, 0, origin, target)
				ParticleManager:SetParticleControlTransformForward(particle, 1, origin, target)
				ParticleManager:SetParticleControl(particle, 3, origin)
				ParticleManager:SetParticleControlTransformForward( particle, 9, origin, target  )
				ParticleManager:SetParticleControl(particle, 10, origin + target * range*1.5)
				ParticleManager:SetParticleShouldCheckFoW(particle, false)
			 
		else
			local radius = self:GetSpecialValueFor("width")
			effectname = "particles/hijikata/hijikata_bullet.vpcf"
			if caster:FindModifierByName("modifier_hijikata_ult_stacks"):GetStackCount() >= 99 then
				radius = self:GetSpecialValueFor("max_stacks_width")
				effectname = "particles/hijikata/hijikata_bullet_combo.vpcf"
				caster:EmitSound("hijikata_cannon")
			end
			 tProjectile = {
				EffectName = effectname,
				Ability = self,
				vSpawnOrigin = origin,
				vVelocity = target * 4000,
				fDistance = range,
				fStartRadius = radius,
				fEndRadius = radius,
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
				ExtraData = {fDamage = self:GetSpecialValueFor("damage") + caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("attack_damage_mod")/100 + 
				caster:FindModifierByName("modifier_hijikata_ult_stacks").DamageTaken * (self:GetSpecialValueFor("stacks_damage_pct")/100 + (caster.IsHijikataBcAcquired and 
				self:GetSpecialValueFor("stacks_damage_pct_bonus")/100 or 0)), velocityX = target.x, velocityY = target.y, should_silence = (caster:FindModifierByName("modifier_hijikata_ult_stacks"):GetStackCount() >= 99) }
			}  

			local particle = ParticleManager:CreateParticle("particles/units/hijikata/ult/hijikata_ult.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControlTransformForward(particle, 0, origin, target)
			ParticleManager:SetParticleControlTransformForward(particle, 1, origin, target)
			ParticleManager:SetParticleControl(particle, 3, origin)
			ParticleManager:SetParticleControlTransformForward( particle, 9, origin, target  )
			ParticleManager:SetParticleControl(particle, 10, origin + target * range)
			ParticleManager:SetParticleShouldCheckFoW(particle, false)
			caster:FindModifierByName("modifier_hijikata_ult_stacks"):ResetCounter()
		end
		self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
		local endpoint = caster:GetAbsOrigin() + target*500
		self.knockback = { should_stun = true,
				knockback_duration = 0.3,
				duration = 0.3,
				knockback_distance = self:GetSpecialValueFor("knockback_distance"),
				knockback_height =  0,	
				center_x = endpoint.x,
				center_y = endpoint.y,
				center_z = endpoint.z }
		caster:AddNewModifier(caster,self,"modifier_knockback", self.knockback)		
	end)
end


function hijikata_ult:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	local hCaster = self:GetCaster()
 	 if(hTarget ~= nil) then
		if hTarget:HasModifier("modifier_protection_from_arrows_active") then return end
		local dmg_mod = 1
		local hp_pct = hTarget:GetHealthPercent()
		--local self_hp_pct = hCaster:GetHealthPercent()
		if hCaster.IsHijikataTacticsAcquired then
			dmg_mod = (self:GetSpecialValueFor("max_damage_pct")/100 - 1)* (1 - hp_pct/100) + 1
		end
		--dmg_mod = dmg_mod +  (self:GetSpecialValueFor("max_damage_pct_self")/100 - 1)* (1 - self_hp_pct/100)
	 	DoDamage(hCaster, hTarget, tData.fDamage*dmg_mod, self:GetAbilityDamageType(), 0, self, false)
		hTarget:AddNewModifier(hCaster,self,"modifier_hijikata_ult_slow", {duration = self:GetSpecialValueFor("duration")})
		hTarget:AddNewModifier(hCaster, self, "modifier_vision_provider", { duration = self:GetSpecialValueFor("duration") })
		--print(tData.should_silence)
		if tData.should_silence == 1 then
			giveUnitDataDrivenModifier(hCaster, hTarget, "silenced", self:GetSpecialValueFor("silence_duration"))
			hTarget:AddNewModifier(hCaster,self,"modifier_hijikata_ult_slow_powerful", {duration = self:GetSpecialValueFor("silence_duration")})
		end
		local blood_fx =  ParticleManager:CreateParticle("particles/econ/items/centaur/centaur_ti9/centaur_double_edge_ti9_bloodspray_src.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleShouldCheckFoW(blood_fx, false)
		ParticleManager:SetParticleAlwaysSimulate( blood_fx)
		local dest_vector = Vector(tData.velocityX, tData.velocityY,0)
		ParticleManager:SetParticleControl( blood_fx, 4, vLocation + Vector(0,0,50)+  dest_vector* 150)
		ParticleManager:SetParticleControl( blood_fx, 5, vLocation + Vector(0,0,50) +  dest_vector* 400)

		if hCaster.IsShinsengumiAcquired then
			hCaster:FindAbilityByName("hijikata_dash"):EndCooldown()
		end
  end
	--  Timers:CreateTimer(0.033,function()
	-- 	 ProjectileManager:DestroyLinearProjectile(self.iProjectile)
	-- end)
  --return true
end


 
modifier_hijikata_ult_slow = class({})

function modifier_hijikata_ult_slow:IsDebuff() return true end
function modifier_hijikata_ult_slow:IsHidden() return false end
function modifier_hijikata_ult_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_hijikata_ult_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("ms_slow")
end

modifier_hijikata_ult_slow_powerful = class({})

function modifier_hijikata_ult_slow_powerful:IsDebuff() return true end
function modifier_hijikata_ult_slow_powerful:IsHidden() return false end
function modifier_hijikata_ult_slow_powerful:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end
function modifier_hijikata_ult_slow_powerful:GetModifierMoveSpeedBonus_Percentage()
	return -99
end
 
modifier_hijikata_ult_stacks = class({})

function modifier_hijikata_ult_stacks:IsDebuff() return false end
function modifier_hijikata_ult_stacks:IsHidden() return false end

function modifier_hijikata_ult_stacks:RemoveOnDeath() return false end

function modifier_hijikata_ult_stacks:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_hijikata_ult_stacks:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.DamageTaken = 0

	self.particle_unbreak = ParticleManager:CreateParticle("particles/hijikata/ult_charge_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
							ParticleManager:SetParticleControl(self.particle_unbreak, 0, self:GetParent():GetAbsOrigin())
							ParticleManager:SetParticleControl(self.particle_unbreak, 1, Vector(self:GetStackCount(),0,0))

	self:AddParticle(self.particle_unbreak, false, true, -1, true, false)

end

if IsServer() then 
	function modifier_hijikata_ult_stacks:OnTakeDamage(args)
		if args.unit ~= self:GetParent() then return end
		if bit.band(args.damage_flags or DOTA_DAMAGE_FLAG_NONE, DOTA_DAMAGE_FLAG_NO_DIRECTOR_EVENT) ~= 0 then return end
		if args.attacker == self:GetParent() then return end

		local reset_delay = self:GetAbility():GetSpecialValueFor("stack_reset_delay")
		self:SetDuration(reset_delay, true)
		local caster = self:GetParent()
		local attacker = args.attacker
		local maxHealth = 1000 + (caster:GetLevel()-1) *25

		self.DamageTaken = (self.DamageTaken or 0) + args.damage
		if self.DamageTaken > (maxHealth * (self:GetAbility():GetSpecialValueFor("health_pct_to_max_damage")*0.01 + (caster.IsHijikataBcAcquired and 0.25 or 0) )) then
			self.DamageTaken = (maxHealth * (self:GetAbility():GetSpecialValueFor("health_pct_to_max_damage")*0.01 + (caster.IsHijikataBcAcquired and 0.25 or 0)))
			
		end
		ParticleManager:SetParticleControl(self.particle_unbreak, 1, Vector(self:GetStackCount() * 10,0,0))
		self:SetStackCount(self.DamageTaken / (maxHealth * self:GetAbility():GetSpecialValueFor("health_pct_to_max_damage")*0.0001))
		self:StartIntervalThink(reset_delay)

	end

	function modifier_hijikata_ult_stacks:OnIntervalThink()
		self:ResetCounter()
	end

	function modifier_hijikata_ult_stacks:ResetCounter()
		self.DamageTaken = 0
		self:SetStackCount(0)
		self:StartIntervalThink(-1)
		self:SetDuration(-1, true)
		ParticleManager:SetParticleControl(self.particle_unbreak, 1, Vector(0,0,0))
	end

	function modifier_hijikata_ult_stacks:GetDamageTaken()
		return self.DamageTaken
	end
end


function modifier_hijikata_ult_stacks:DestroyOnExpire()
	return false
end
modifier_hijikata_dovodka = modifier_hijikata_dovodka or class({})

function modifier_hijikata_dovodka:IsHidden() return false end
function modifier_hijikata_dovodka:IsDebuff() return false end
function modifier_hijikata_dovodka:IsPurgable() return false end
function modifier_hijikata_dovodka:RemoveOnDeath() return true end
function modifier_hijikata_dovodka:CheckState()
    local state = { [MODIFIER_STATE_ROOTED] = true,
					[MODIFIER_STATE_SILENCED] = true,
					[MODIFIER_STATE_DISARMED] = true,
					[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true, }
    return state
end

 