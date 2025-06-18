cu_chulain_gae_bolg = class({})

function cu_chulain_gae_bolg:CastFilterResultTarget(hTarget)
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

function cu_chulain_gae_bolg:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "#Invalid_Target"
	elseif self:GetCaster():IsDisarmed() then
		return "#Disarmed"
	else
		return "#Cannot_Cast"
	end
end

function cu_chulain_gae_bolg:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local GBCastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(GBCastFx, 1, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(GBCastFx, 2, caster:GetAbsOrigin())

	Timers:CreateTimer(1.5, function()
		ParticleManager:DestroyParticle( GBCastFx, false )
	end)

	--caster:EmitSound("Lancer.GaeBolg")
	caster:EmitSound("cu_chulain_gae_bolg_voice")
	return true
end

function cu_chulain_gae_bolg:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	caster:StopSound("cu_chulain_gae_bolg_voice")
end

function cu_chulain_gae_bolg:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	local damage = self:GetSpecialValueFor("damage")
	local hbThreshold = self:GetSpecialValueFor("heart_break")
	if IsSpellBlocked(target) then 
		return 
	end
	if caster.HeartSeekerImproved then 
		damage = damage + caster:GetLevel() * self:GetSpecialValueFor("sa_damage_per_level")
		local percentbreak = (target:GetMaxHealth() * self:GetSpecialValueFor("atr_hb_pct") / 100)
		if(percentbreak	> hbThreshold ) then
			hbThreshold = percentbreak
		end
	end
 
	local original_pos = caster:GetAbsOrigin()

	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	if (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > 250 then 
		caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 250)
		FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )
	end

	local flashIndex = ParticleManager:CreateParticle( "particles/custom/diarmuid/gae_dearg_slash.vpcf", PATTACH_CUSTOMORIGIN, caster )
    ParticleManager:SetParticleControl( flashIndex, 2, original_pos )
    ParticleManager:SetParticleControl( flashIndex, 3, caster:GetAbsOrigin() )

	local particle = ParticleManager:CreateParticle("particles/cu_chulain/gae_bolg_pierce.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin() + Vector(0,0,130)+caster:GetRightVector() * - 20,caster:GetForwardVector())
    ParticleManager:SetParticleControlTransformForward(particle, 1, caster:GetAbsOrigin()+ Vector(0,0,130)+caster:GetRightVector() * - 20,caster:GetForwardVector())
	ParticleManager:SetParticleControlTransformForward(particle, 5, target:GetAbsOrigin()+ Vector(0,0,130) + caster:GetForwardVector() * - 50,caster:GetForwardVector())



	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)

	giveUnitDataDrivenModifier(caster, target, "can_be_executed", 0.033)
	DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, 0, ability, false)
	target:AddNewModifier(caster, target, "modifier_stunned", {Duration =0.5})

	if target:GetHealth() < hbThreshold and not (target:IsMagicImmune() or target:HasModifier("modifier_avalon")) then
		local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControl( hb, 0, target:GetAbsOrigin())
		target:Execute(ability, caster, { bExecution = true })
		
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( hb, false )
			ParticleManager:ReleaseParticleIndex(hb)
		end)
	end
	
	--StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK, rate=3})
	
	-- Add dagon particle
	-- local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN_FOLLOW, caster)
	-- ParticleManager:SetParticleControlEnt(dagon_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
	-- local particle_effect_intensity = 600
	-- ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
	target:EmitSound("cu_pierce_new")
	target:EmitSound("cu_pierce_new_2")

	-- Blood splat
	local splat = ParticleManager:CreateParticle("particles/generic_gameplay/screen_blood_splatter.vpcf", PATTACH_EYES_FOLLOW, target)

	Timers:CreateTimer( 3.0, function()
		--ParticleManager:DestroyParticle( dagon_particle, false )

		ParticleManager:DestroyParticle( splat, false )
		ParticleManager:ReleaseParticleIndex(splat)
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
function cu_chulain_gae_bolg:GetIntrinsicModifierName()
    return "modifier_cu_idle_animation"
end
LinkLuaModifier("modifier_cu_idle_animation", "abilities/cu_chulain/cu_chulain_gae_bolg", LUA_MODIFIER_MOTION_NONE)
modifier_cu_idle_animation = class({})
function modifier_cu_idle_animation:OnCreated(args)
    self.activity = "not_in_fight"
	self:StartIntervalThink(0.5)
end
function modifier_cu_idle_animation:OnIntervalThink()
	if self:GetRemainingTime() < 0.5 then
		self.activity = "not_in_fight"
	end
end
function modifier_cu_idle_animation:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end
 	self.activity = "in_fight"
	self:SetDuration(4, true)
end
function modifier_cu_idle_animation:OnAttackLanded(args)
    if args.attacker ~= self:GetParent() then return end
    self.activity = "in_fight"
	self:SetDuration(4, true)
end

function modifier_cu_idle_animation:IsHidden() return true end
function modifier_cu_idle_animation:IsDebuff() return false end
function modifier_cu_idle_animation:IsPurgable() return false end
function modifier_cu_idle_animation:IsPurgeException() return false end
function modifier_cu_idle_animation:DestroyOnExpire() return false end
function modifier_cu_idle_animation:RemoveOnDeath() return false end

function modifier_cu_idle_animation:DeclareFunctions()
    local func = {    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS}
    return func
end

function modifier_cu_idle_animation:GetActivityTranslationModifiers()
	return self.activity
end

