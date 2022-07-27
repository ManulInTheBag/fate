kuro_nine_lives = class({})

LinkLuaModifier("modifier_projection_attribute", "abilities/kuro/modifiers/modifier_projection_attribute", LUA_MODIFIER_MOTION_NONE)
function kuro_nine_lives:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_kuro_projection") then
		cooldown = cooldown - (cooldown * 35 / 100)
	end

	return cooldown
end
function kuro_nine_lives:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 		
		elseif not self:GetCaster():HasModifier("modifier_projection_active") and not self:GetCaster():HasModifier("modifier_kuro_projection_overpower") then
			return UF_FAIL_CUSTOM
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function kuro_nine_lives:GetCustomCastErrorTarget()
    return "#Invalid_Target"
end

function kuro_nine_lives:OnSpellStart()
	local close_ability = self:GetCaster():FindAbilityByName("kuro_spellbook_close")
	close_ability:OnSpellCalled(self)

	local caster = self:GetCaster()
	local hCaster = self:GetCaster()
	local target = self:GetCursorTarget()
	if IsSpellBlocked(target) then return end
	local enhanced = false
	local delay = 0.2
	local delay_per_slash = 0.1
	local split_damage = self:GetSpecialValueFor("damage")
	local final_damage = self:GetSpecialValueFor("damage_lasthit")

	if hCaster:HasModifier("modifier_projection_active") then
		if hCaster:HasModifier("modifier_kuro_projection") then
			split_damage = split_damage + caster:GetStrength()
			final_damage = final_damage + caster:GetStrength()
		end
		if hCaster:HasModifier("modifier_projection_active") and not hCaster:HasModifier("modifier_kuro_projection_overpower") then
			if hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()>1 then		
				hCaster:FindModifierByName("modifier_projection_active"):SetStackCount(hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()-1)
			elseif not hCaster:HasModifier("modifier_kuro_projection_overpower") then
				hCaster:RemoveModifierByName("modifier_projection_active")
			end
		end
	end

	--caster:SetMana(0)
	EmitGlobalSound("chloe_trace_on")
	StartAnimation(caster, {duration=delay + delay_per_slash * 2, activity= ACT_DOTA_CAST_ABILITY_4 , rate=2.5})

	caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 1.1})
	giveUnitDataDrivenModifier(caster, caster, "dragged", 1.1)
	giveUnitDataDrivenModifier(caster, caster, "revoked", 1.1)

	local particle = ParticleManager:CreateParticle("particles/custom/false_assassin/tsubame_gaeshi/slashes.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin()) 

	for i = 1,8 do
		Timers:CreateTimer(delay, function()  
			if caster:IsAlive() and target:IsAlive() then			
--				if caster.IsGanryuAcquired then
--					giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.5)	
--				end	

				--if enhanced then
				--	self:PerformSlash(caster, target, 1, 3)
				--else
					self:PerformSlash(caster, target, split_damage, 2)
				--end
			else
				ParticleManager:DestroyParticle(particle, true)
			end
		return end)

		delay = delay + delay_per_slash
	end

	Timers:CreateTimer(delay, function()  
		if caster:IsAlive() and target:IsAlive() then
			--if enhanced then				
			--	self:PerformSlashk(caster, target, combined_damage, 1)
			--	target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 1.5 })
			--else
				self:PerformSlash(caster, target, final_damage, 3)
			--end
		else
			ParticleManager:DestroyParticle(particle, true)
		end

		target:RemoveModifierByName("modifier_ganryu_armor_shred")
		return 
	end)
end

function kuro_nine_lives:PerformSlash(caster, target, damage, soundQueue)
	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
	local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	if distance > 400 then
		caster:RemoveModifierByName("dragged")
		caster:RemoveModifierByName("revoked")
		caster:RemoveModifierByName("modifier_phased")
		return
	end
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 

	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
	ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))

	local flag = DOTA_DAMAGE_FLAG_NONE

	if soundQueue == 1 then 
		target:EmitSound("Tsubame_Focus")
		target:RemoveModifierByName("modifier_master_intervention")
	elseif soundQueue == 2 then
		caster:EmitSound("Hero_EarthSpirit.StoneRemnant.Impact")
		--target:RemoveModifierByName("modifier_master_intervention")
		--target:EmitSound("Tsubame_Slash_" .. math.random(1,3))
	else
		--target:EmitSound("Hero_Juggernaut.PreAttack")
		caster:EmitSound("Hero_EarthSpirit.BoulderSmash.Target")
		if not IsKnockbackImmune(target) then
			local pushback = Physics:Unit(target)
			target:PreventDI()
			target:SetPhysicsFriction(0)
			target:SetPhysicsVelocity((target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized() * 300)
			target:SetNavCollisionType(PHYSICS_NAV_NOTHING)
			target:FollowNavMesh(false)
			Timers:CreateTimer(0.5, function()  
				target:PreventDI(false)
				target:SetPhysicsVelocity(Vector(0,0,0))
				target:OnPhysicsFrame(nil)
				FindClearSpaceForUnit(target, target:GetAbsOrigin(), true)
			end)
		end   
	end

	if   not flag == DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY then return end

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, flag, self, false)
	if not target:IsMagicImmune() then
		target:AddNewModifier(caster, target, "modifier_stunned", {Duration = 1.0})
	end
end