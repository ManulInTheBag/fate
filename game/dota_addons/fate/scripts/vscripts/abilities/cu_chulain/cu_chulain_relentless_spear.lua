cu_chulain_relentless_spear = class({})

LinkLuaModifier("modifier_relentless_spear", "abilities/cu_chulain/modifiers/modifier_relentless_spear", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wesen_window", "abilities/cu_chulain/modifiers/modifier_wesen_window", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_relentless_spear:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function cu_chulain_relentless_spear:OnChannelThink(flInterval)
	local caster = self:GetCaster()
	local distance = (caster:GetAbsOrigin() - self.target:GetAbsOrigin()):Length2D()
	
	if not self:GetCaster():IsAlive() or not self.target:IsAlive() or distance > 450 then
		local stopOrder = {
	 		UnitIndex = caster:entindex(), 
	 		OrderType = DOTA_UNIT_ORDER_STOP
	 	}

	 	ExecuteOrderFromTable(stopOrder) 
		self:EndChannel(true)
	end
end

 
function cu_chulain_relentless_spear:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("cu_chulain_gae_bolg_jump"):IsCooldownReady() 
		and caster:FindAbilityByName("cu_new_combo"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_wesen_window", { Duration = 4 })
		end
	end
end

function cu_chulain_relentless_spear:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_relentless_spear")
end

function cu_chulain_relentless_spear:EndChannel(bInterrupted)
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_relentless_spear")
end




LinkLuaModifier("modifier_cu_relentless_tracker", "abilities/cu_chulain/cu_chulain_relentless_spear", LUA_MODIFIER_MOTION_NONE)


function cu_chulain_relentless_spear:GetChannelTime()
	if self:CheckSequence() == 3 then
		return 1.05
	elseif self:CheckSequence() == 2 then
		return 0.0
	elseif self:CheckSequence() == 1 then
		return 0.0
	else
		return 1.05
	end
end
function cu_chulain_relentless_spear:GetCastPoint()
	if self:CheckSequence() == 3 then
		return 0.2
	elseif self:CheckSequence() == 2 then
		return 0.1
	else
		return 0.1
	end
end
function cu_chulain_relentless_spear:GetBehavior()
	if self:CheckSequence() == 3 then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_CHANNELLED
	elseif self:CheckSequence() == 2 then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
	else
		return DOTA_ABILITY_BEHAVIOR_POINT+ DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
	end
end



function cu_chulain_relentless_spear:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_cu_relentless_tracker") then
		local stack = caster:GetModifierStackCount("modifier_cu_relentless_tracker", caster)
		
		return stack
	else
		return 0
	end	
end

-- function lishuwen_tiger_strike:GetCastAnimation()
-- 	if self:CheckSequence() == 2 then
-- 		return ACT_DOTA_CAST_ABILITY_3
-- 	elseif self:CheckSequence() == 1 then
-- 		return ACT_DOTA_CAST_ABILITY_2
-- 	else
-- 		return ACT_DOTA_ATTACK
-- 	end
-- end

function cu_chulain_relentless_spear:GetCastRange(vLocation, hTarget)
	if self:CheckSequence() == 3 then
		return 300
	elseif self:CheckSequence() == 2 then
		return 375
	else
		return 375
	end
end

function cu_chulain_relentless_spear:GetAbilityTextureName()
	if self:CheckSequence() == 3 then
		return "custom/lancer_5th_relentless_spear"
	elseif self:CheckSequence() == 2 then
		return "custom/cu_chulain/cu_dash"
	else
		return "custom/cu_chulain/cu_dash"
	end
end

function cu_chulain_relentless_spear:SequenceSkill()
	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_cu_relentless_tracker")

	if not modifier then
		caster:AddNewModifier(caster, ability, "modifier_cu_relentless_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_cu_relentless_tracker", ability, 2)
	else
		caster:SetModifierStackCount("modifier_cu_relentless_tracker", ability, modifier:GetStackCount() + 1)
	end
end



function cu_chulain_relentless_spear:OnSpellStart()
	local caster = self:GetCaster()

	ProjectileManager:ProjectileDodge(caster)

	if self:CheckSequence() == 3 then
		self:TigerStrike3()
	elseif self:CheckSequence() == 2 then
		self:TigerStrike1()
	else
		self:TigerStrike1()
	end
end

function cu_chulain_relentless_spear:TigerStrike1()
	local caster = self:GetCaster()
	local target  = self:GetCursorPosition()
	if self:CheckSequence() == 2 then
		caster:EmitSound("cu_dash_w_2")
		self:CheckCombo()
	else
		caster:EmitSound("cu_dash_w_1")
		self.isRefreshed = 0
	end
	local dist = (caster:GetAbsOrigin() - target):Length2D()



	local dir = (caster:GetAbsOrigin() - target):Normalized()
	dir.z = 0
	caster:SetForwardVector(-dir)
	StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_SUN_STRIKE , rate=1.1})	
	local knockback1 = { should_stun = false,
		knockback_duration = 0.3,
		duration = 0.3,
		knockback_distance = -math.min(dist, 375),
		knockback_height = 0,
		center_x = target.x,
		center_y = target.y,
		center_z = target.z }

		caster:AddNewModifier(caster, self, "modifier_knockback", knockback1)
	Timers:CreateTimer(0.3, function()
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST , false)
		if #targets < 1 then 
			return
		 end
		 StartAnimation(caster, {duration=0.1, activity=ACT_DOTA_CAST_GHOST_SHIP , rate=6})	
		 local dir2 = (caster:GetAbsOrigin() - targets[1]:GetAbsOrigin()):Normalized()
		 dir2.z = 0
		 caster:SetForwardVector(-dir2)
		 caster:FaceTowards( targets[1]:GetAbsOrigin())
		 local particle = ParticleManager:CreateParticle("particles/cu_chulain/gae_bolg_pierce.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin() + Vector(0,0,130)+caster:GetRightVector() * - 20,caster:GetForwardVector())
		ParticleManager:SetParticleControlTransformForward(particle, 1, caster:GetAbsOrigin()+ Vector(0,0,130)+caster:GetRightVector() * - 20,caster:GetForwardVector())
		ParticleManager:SetParticleControlTransformForward(particle, 5, caster:GetAbsOrigin()+ Vector(0,0,130) + caster:GetForwardVector() *  50,caster:GetForwardVector())
		ParticleManager:ReleaseParticleIndex(particle)
		local blow_fx =     ParticleManager:CreateParticle("particles/econ/items/void_spirit/void_spirit_immortal_2021/void_spirit_immortal_2021_astral_step_dmg_blood.vpcf", PATTACH_CUSTOMORIGIN, self.target)
		ParticleManager:SetParticleControl(blow_fx, 0, targets[1]:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(blow_fx)
		Timers:CreateTimer(0.1, function()
			if targets[1]:IsAlive() then
				DoDamage(caster, targets[1], self:GetSpecialValueFor("damage_first"), DAMAGE_TYPE_PHYSICAL, 0, self, false)
				caster:PerformAttack(targets[1], true, true, true, true, false, false, true)
				if self:CheckSequence() == 2 then
					giveUnitDataDrivenModifier(caster, targets[1], "rooted", self:GetSpecialValueFor("root_dur"))
				else
					giveUnitDataDrivenModifier(caster, targets[1], "locked", self:GetSpecialValueFor("root_dur"))
				end
				targets[1]:EmitSound("cu_pierce_new")
				targets[1]:EmitSound("cu_pierce_new_2")
			end


		end)



	end)
	self:SequenceSkill()
	self:EndCooldown()
	self:StartCooldown(0.3)
end



function cu_chulain_relentless_spear:TigerStrike3()
	local caster = self:GetCaster()
	self.target = self:GetCursorTarget()
	self.stopOrder_self = {
		UnitIndex = caster:entindex(), 
		OrderType = DOTA_UNIT_ORDER_STOP
	}

	if IsSpellBlocked(self.target) then
		ExecuteOrderFromTable(self.stopOrder_self)  return
		 end
	caster:EmitSound("cu_skill_" .. math.random(1,4))

	self.target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.15})
	caster:AddNewModifier(caster, self, "modifier_relentless_spear", { Duration = self:GetSpecialValueFor("duration") + 0.1,
																	   DamagePct = self:GetSpecialValueFor("damage") })

	local modifier = caster:FindModifierByName("modifier_rune_of_ferocity")
	if modifier then
		modifier:OnIntervalThink()
	end

	


end


modifier_cu_relentless_tracker = class({})

function modifier_cu_relentless_tracker:OnDestroy()
	if IsServer() then
		local ability = self:GetAbility()
		if ability.isRefreshed == 0 then
			ability:StartCooldown(ability:GetCooldown(ability:GetLevel()) * self:GetCaster():GetCooldownReduction())
		else
			ability:EndCooldown()
		end
	end
end

function modifier_cu_relentless_tracker:IsPurgable()
	return false
end

function modifier_cu_relentless_tracker:IsHidden()
	return false
end

function modifier_cu_relentless_tracker:IsDebuff()
	return false
end

function modifier_cu_relentless_tracker:RemoveOnDeath()
	return true
end

function modifier_cu_relentless_tracker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_cu_relentless_tracker:GetTexture()
	return "custom/lancer_5th_relentless_spear"
end
