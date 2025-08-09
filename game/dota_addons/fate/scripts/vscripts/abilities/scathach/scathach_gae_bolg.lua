
LinkLuaModifier("modifier_heal_reduction_tier_2", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stachach_gae_bolg_curse", "abilities/scathach/scathach_gae_bolg.lua", LUA_MODIFIER_MOTION_NONE)
scathach_gae_bolg = class({})

function scathach_gae_bolg:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or caster:IsDisarmed() then 
			return UF_FAIL_CUSTOM 		
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function scathach_gae_bolg:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "#Invalid_Target"
	elseif self:GetCaster():IsDisarmed() then
		return "#Disarmed"
	else
		return "#Cannot_Cast"
	end
end

function scathach_gae_bolg:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local GBCastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(GBCastFx, 1, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(GBCastFx, 2, caster:GetAbsOrigin())

	Timers:CreateTimer(1.5, function()
		ParticleManager:DestroyParticle( GBCastFx, false )
	end)

	caster:EmitSound("Scathach.Gae_Bolg")

	return true
end

function scathach_gae_bolg:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	local damage = self:GetSpecialValueFor("damage")
	local totalDamage = damage
	local damage_per_stack = self:GetSpecialValueFor("damage_per_stack")
	if IsSpellBlocked(target) then 
		return 
	end
	local target_stacks = target:GetModifierStackCount("modifier_stachach_gae_bolg_curse", caster)
	if type(target_stacks) == "number" then
		totalDamage = damage + target_stacks * damage_per_stack
		target:RemoveModifierByName("modifier_stachach_gae_bolg_curse")
	end

	local original_pos = caster:GetAbsOrigin()

	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 200)
	FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )



	--giveUnitDataDrivenModifier(caster, target, "can_be_executed", 0.033)
	if caster:HasModifier("modifier_scathach_branches_of_tonelico_attribute") then
		DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		if (totalDamage - damage) > 0 then
			DoDamage(caster, target, totalDamage - damage, DAMAGE_TYPE_PURE, 0, ability, false)
		end
	else
		DoDamage(caster, target, totalDamage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	end

	target:AddNewModifier(caster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})
	if caster:HasModifier("modifier_scathach_branches_of_tonelico_attribute") then
 		target:AddNewModifier(caster, self, "modifier_heal_reduction_tier_2", {duration = self:GetSpecialValueFor("healres_duration")})
	end
	-- if target:GetHealth() < hbThreshold and not (target:IsMagicImmune()) then
	-- 	local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, target)
	-- 	ParticleManager:SetParticleControl( hb, 0, target:GetAbsOrigin())
	-- 	target:Execute(ability, caster, { bExecution = true })
		
	-- 	Timers:CreateTimer( 3.0, function()
	-- 		ParticleManager:DestroyParticle( hb, false )
	-- 		ParticleManager:ReleaseParticleIndex(hb)
	-- 	end)
	-- end
	
	-- Add dagon particle
	local flashIndex = ParticleManager:CreateParticle( "particles/custom/diarmuid/gae_dearg_slash.vpcf", PATTACH_CUSTOMORIGIN, caster )
    ParticleManager:SetParticleControl( flashIndex, 2, original_pos )
    ParticleManager:SetParticleControl( flashIndex, 3, caster:GetAbsOrigin() )

	local particle = ParticleManager:CreateParticle("particles/scathach/gae_bolg_pierce_alt.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin() + Vector(0,0,130)+caster:GetRightVector() * - 20,caster:GetForwardVector())
    ParticleManager:SetParticleControlTransformForward(particle, 1, caster:GetAbsOrigin()+ Vector(0,0,130)+caster:GetRightVector() * - 20,caster:GetForwardVector())
	ParticleManager:SetParticleControlTransformForward(particle, 5, target:GetAbsOrigin()+ Vector(0,0,130) + caster:GetForwardVector() * - 50,caster:GetForwardVector())



	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
				ParticleManager:DestroyParticle( flashIndex, false )
		ParticleManager:ReleaseParticleIndex( flashIndex )
	end)
	target:EmitSound("Hero_Lion.Impale")
	
	-- Blood splat
	local splat = ParticleManager:CreateParticle("particles/generic_gameplay/screen_blood_splatter.vpcf", PATTACH_EYES_FOLLOW, target)

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( splat, false )

		ParticleManager:ReleaseParticleIndex( splat )
	end)

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
	--target:Execute(ability, killer, { bExecution = true })
end



modifier_stachach_gae_bolg_curse = class({})
function modifier_stachach_gae_bolg_curse:IsHidden() return false end
function modifier_stachach_gae_bolg_curse:IsDebuff() return true end
function modifier_stachach_gae_bolg_curse:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,}
end
function modifier_stachach_gae_bolg_curse:GetModifierTotalDamageOutgoing_Percentage(keys)
    if IsNotNull(self.hCaster)
        and IsNotNull(self.hParent) then
        if IsClient() or bit.band(keys.damage_type or DAMAGE_TYPE_NONE, DAMAGE_TYPE_MAGICAL) ~= 0 then
            return -self.reduction
        end
    end
end
if IsServer() then
	function modifier_stachach_gae_bolg_curse:OnCreated(tTable)
		self:SetStackCount(1)
	end
	function modifier_stachach_gae_bolg_curse:OnRefresh(tTable)
		if self:GetStackCount() == 1 then
			self:SetStackCount(2)
		else
			self:IncrementStackCount()
			if self:GetStackCount() > 10 then
				self:SetStackCount(10)
			end
		end

	end
end

function modifier_stachach_gae_bolg_curse:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount() * -3
end

function modifier_stachach_gae_bolg_curse:GetEffectName()
    return "particles/custom/scathach/bramble_scathach.vpcf"
end
function modifier_stachach_gae_bolg_curse:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end