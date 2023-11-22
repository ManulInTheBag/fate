lu_bu_god_force = class({})

LinkLuaModifier("modifier_lu_bu_god_force", "abilities/lu_bu/modifiers/modifier_lu_bu_god_force", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lu_bu_god_force_mute", "abilities/lu_bu/modifiers/modifier_lu_bu_god_force_mute", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_assault_skillswap_4", "abilities/lu_bu/modifiers/modifier_assault_skillswap_4", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_relentless_assault_blocker", "abilities/lu_bu/modifiers/modifier_relentless_assault_blocker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_relentless_assault_blocker_combo", "abilities/lu_bu/modifiers/modifier_relentless_assault_blocker_combo", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_relentless_assault", "abilities/lu_bu/modifiers/modifier_lu_bu_relentless_assault", LUA_MODIFIER_MOTION_NONE )

function lu_bu_god_force:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function lu_bu_god_force:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	caster:EmitSound("lu_bu_relentless_assault_three")

	return true
end

function lu_bu_god_force:OnSpellStart()
	local caster = self:GetCaster()
	local casterName = caster:GetName()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local berserker = Physics:Unit(caster)
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized() * distance

	giveUnitDataDrivenModifier(caster, caster, "silenced", 2)
	caster:AddNewModifier(caster, self, "modifier_lu_bu_god_force_mute", { Duration = 2.0 })
	caster:EmitSound("Hero_OgreMagi.Ignite.Cast")

	self:StartGodForce()
	
	local origin = caster:GetForwardVector()
	
	Timers:CreateTimer(0.05, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			caster:EmitSound("lu_bu_god_force_small_hit")
		end
	end)
	
	Timers:CreateTimer(0.45, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			caster:EmitSound("lu_bu_god_force_small_hit")
		end
	end)
	
	Timers:CreateTimer(0.85, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			caster:EmitSound("lu_bu_god_force_small_hit")
		end
	end)
	
	
	Timers:CreateTimer(1.25, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			caster:EmitSound("lu_bu_god_force_small_hit")
		end
	end)
	
	Timers:CreateTimer(1.65, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			caster:EmitSound("lu_bu_god_force_small_hit")
		end
	end)
	
	Timers:CreateTimer(2.00, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
		end
	end)
	
	Timers:CreateTimer(0.01, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 0.8, activity=ACT_DOTA_CAST_ABILITY_5, rate = 1.5})
		end
	end)
	
	
	Timers:CreateTimer(0.8, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 0.8, activity=ACT_DOTA_CAST_ABILITY_5, rate = 1.5})
		end
	end)
	
	
	Timers:CreateTimer(1.6, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 0.6, activity=ACT_DOTA_CAST_ABILITY_4, rate = 1.3})
		end
	end)
	
	Timers:CreateTimer(2.0, function()
		if caster:IsAlive() then
			ScreenShake(caster:GetOrigin(), 5, 0.5, 2, 20000, 0, true)
				-- Create Particle
			local blastFx = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_armistice_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl( blastFx, 0, caster:GetAbsOrigin())
			
			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( blastFx, false )
				ParticleManager:ReleaseParticleIndex( blastFx )
			end)
			
			caster:EmitSound("lu_bu_armistice_impact")
			caster:EmitSound("lu_bu_god_force_big_hit")
		end
	end)
	
	local relentless_assault = caster:FindModifierByNameAndCaster( "modifier_lu_bu_relentless_assault", caster )
	local assault_stack = caster:GetModifierStackCount("modifier_lu_bu_relentless_assault", caster)
	
	if caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack < 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
		relentless_assault:SetStackCount(assault_stack + 1)
	elseif caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack >= 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
		caster:AddNewModifier(caster, self, "modifier_assault_skillswap_4",{})
		caster:AddNewModifier(caster, self, "modifier_relentless_assault_blocker", {})
		caster:AddNewModifier(caster, self, "modifier_relentless_assault_blocker_combo", {})
	end
end

function lu_bu_god_force:StartGodForce()
	local caster = self:GetCaster()

	if caster:IsAlive() then
		self:GodForceHits()
		return 
	end

	return
end

function lu_bu_god_force:GodForceHits()
	local bonus_damage = 0
	local caster = self:GetCaster()

	local casterInitOrigin = caster:GetAbsOrigin() 
	
	local SmallDamage = self:GetSpecialValueFor("damage")
	local LargeDamage = self:GetSpecialValueFor("damage_lasthit")
	
	if caster:HasModifier("modifier_lu_bu_fangtian_huaji_attribute") then
		SmallDamage = SmallDamage + 25
		LargeDamage = LargeDamage + 100 + (caster:GetStrength()*2)
	end

	caster:AddNewModifier(caster, self, "modifier_lu_bu_god_force", { Duration = 2.5,
																 SmallDamage =SmallDamage,
																 LargeDamage = LargeDamage,
																 SmallRadius = self:GetSpecialValueFor("radius"),
																 LargeRadius = self:GetSpecialValueFor("radius_lasthit")})
end

function lu_bu_god_force:PlayEffects2( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/lu_bu/assault_two_ult.vpcf"
	local sound_cast = "Hero_Mars.Shield.Cast"
	if not caught then
		local sound_cast = "Hero_Mars.Shield.Cast.Small"
	end

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function lu_bu_god_force:OnUpgrade()
    local relentless_assault = self:GetCaster():FindAbilityByName("lu_bu_relentless_assault_four")
    relentless_assault:SetLevel(self:GetLevel())
end