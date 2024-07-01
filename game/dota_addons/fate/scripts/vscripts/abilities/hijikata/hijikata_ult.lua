hijikata_ult = class({})

LinkLuaModifier("modifier_hijikata_ult_slow", "abilities/hijikata/hijikata_ult", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)

function hijikata_ult:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local range = self:GetSpecialValueFor("distance")
	local target = -(caster:GetAbsOrigin() - self:GetCursorPosition()):Normalized()
	target.z = 0
	caster:SetForwardVector(target)
	StartAnimation(caster, {duration=0.9, activity=ACT_DOTA_CAST_ABILITY_6, rate=1})
	caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = 0.8}) 


    Timers:CreateTimer(0.8, function() 
		if not caster:IsAlive() then return end
		caster:EmitSound("nobu_shoot_1")
		local origin = caster:GetAbsOrigin() +caster:GetForwardVector()*60 + Vector(0,0,200) + caster:GetRightVector() * -30--caster:GetAttachmentOrigin(4)
		local tProjectile = {
			EffectName = "particles/hijikata/hijikata_bullet.vpcf",
			Ability = self,
			vSpawnOrigin = origin,
			vVelocity = target * 4000,
			fDistance = range,
			fStartRadius = 100,
			fEndRadius = 100,
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
			ExtraData = {fDamage = self:GetSpecialValueFor("damage"), velocityX = target.x, velocityY = target.y}
		}  
		self.iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
		local endpoint = caster:GetAbsOrigin() + target*500
		self.knockback = { should_stun = true,
				knockback_duration = 0.3,
				duration = 0.3,
				knockback_distance = 300,
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

		local hp_pct = hTarget:GetHealthPercent()
		local dmg_mod = (self:GetSpecialValueFor("max_damage_pct")/100 - 1)* (1 - hp_pct/100) + 1
	 	DoDamage(hCaster, hTarget, tData.fDamage*dmg_mod, DAMAGE_TYPE_MAGICAL, 0, self, false)
		hTarget:AddNewModifier(hCaster,self,"modifier_hijikata_ult_slow", {duration = self:GetSpecialValueFor("duration")})
		hTarget:AddNewModifier(hCaster, self, "modifier_vision_provider", { duration = self:GetSpecialValueFor("duration") })

		local blood_fx =  ParticleManager:CreateParticle("particles/econ/items/centaur/centaur_ti9/centaur_double_edge_ti9_bloodspray_src.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleShouldCheckFoW(blood_fx, false)
		ParticleManager:SetParticleAlwaysSimulate( blood_fx)
		local dest_vector = Vector(tData.velocityX, tData.velocityY,0)
		ParticleManager:SetParticleControl( blood_fx, 4, vLocation + Vector(0,0,50)+  dest_vector* 150)
		ParticleManager:SetParticleControl( blood_fx, 5, vLocation + Vector(0,0,50) +  dest_vector* 400)
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
