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
	local jiaQiuSkin = false
	if caster:HasModifier("modifier_hero_selection_skin") then
		if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 1 then
			jiaQiuSkin = true
		end
	end
	if not jiaQiuSkin then
		caster:EmitSound("lu_bu_relentless_assault_three")
	end

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

	--giveUnitDataDrivenModifier(caster, caster, "silenced", 2)
	caster:AddNewModifier(caster, self, "modifier_lu_bu_god_force_mute", { Duration = 2.0 })
	caster:EmitSound("Hero_OgreMagi.Ignite.Cast")

	local jiaQiuSkin = false
	if caster:HasModifier("modifier_hero_selection_skin") then
		if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 1 then
			jiaQiuSkin = true
		end
	end
	if jiaQiuSkin then
		caster:EmitSound("jia_qiu_god_force_voice")
	end

	self:StartGodForce()
	
	local origin = caster:GetForwardVector()
	StartAnimation(caster, {duration = 0.35, activity=ACT_DOTA_CAST_ABILITY_5, rate = 2.5})
	Timers:CreateTimer(0.05, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			if not jiaQiuSkin then
				caster:EmitSound("lu_bu_god_force_small_hit")
			end
		end
	end)
	Timers:CreateTimer(0.35, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 0.4, activity=ACT_DOTA_RAZE_2, rate = 2.5})
		end
	end)
	Timers:CreateTimer(0.45, function()
		if caster:IsAlive() then
			self:PlayEffects3( caught, origin:Normalized() )
			if not jiaQiuSkin then
				caster:EmitSound("lu_bu_god_force_small_hit")
			end
		end
	end)
	Timers:CreateTimer(0.75, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 0.4, activity=ACT_DOTA_CAST_ABILITY_5, rate = 2.5})
		end
	end)
	Timers:CreateTimer(0.85, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			if not jiaQiuSkin then
				caster:EmitSound("lu_bu_god_force_small_hit")
			end
		end
	end)
	
	Timers:CreateTimer(1.15, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 0.4, activity=ACT_DOTA_RAZE_2, rate = 2.5})
		end
	end)
	Timers:CreateTimer(1.25, function()
		if caster:IsAlive() then
			self:PlayEffects3( caught, origin:Normalized() )
			if not jiaQiuSkin then
				caster:EmitSound("lu_bu_god_force_small_hit")
			end
		end
	end)
	Timers:CreateTimer(1.55, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 0.25, activity=ACT_DOTA_CAST_ABILITY_5, rate = 3.5})
		end
	end)
	Timers:CreateTimer(1.65, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			if not jiaQiuSkin then
				caster:EmitSound("lu_bu_god_force_small_hit")
			end
		end
	end)
	Timers:CreateTimer(1.8, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration = 0.5, activity=ACT_DOTA_CAST_ABILITY_4, rate = 2.5})
		end
	end)
	Timers:CreateTimer(2.00, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized(), true )
		end
	end)
	
 
 
	
	Timers:CreateTimer(2.0, function()
		if caster:IsAlive() then
			ScreenShake(caster:GetOrigin(), 5, 0.5, 2, 20000, 0, true)
				-- Create Particle
			local blastFxName = "particles/custom/lu_bu/lu_bu_armistice_impact.vpcf"
			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 1 then
					blastFxName = "particles/custom/jia_qiu/jia_qiu_armistice_impact.vpcf"
				end
			end
			local blastFx = ParticleManager:CreateParticle(blastFxName, PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl( blastFx, 0, caster:GetAbsOrigin())
			
			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( blastFx, false )
				ParticleManager:ReleaseParticleIndex( blastFx )
			end)
			
			if blastFxName == "particles/custom/jia_qiu/jia_qiu_armistice_impact.vpcf" then
				caster:EmitSound("jia_qiu_armistice")
			else
				caster:EmitSound("lu_bu_armistice_impact")
			end
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

function lu_bu_god_force:PlayEffects2( caught, direction, lastHit )
	-- Get Resources
	local particle_cast = "particles/custom/lu_bu/assault_two_ult.vpcf"
	local sound_cast = "Hero_Mars.Shield.Cast"
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_hero_selection_skin") then
		if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 1 then
			particle_cast = "particles/custom/jia_qiu/assault_two_ult.vpcf"
			if lastHit then
				caster:EmitSound("jia_qiu_assault_sfx")
			else
				sound_cast = "jia_qiu_strike"
			end
		end
	end
	if not caught then
		local sound_cast = "Hero_Mars.Shield.Cast.Small"
	end
	direction.z = 0
	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControlTransformForward( effect_cast, 0, self:GetCaster():GetOrigin(), direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function lu_bu_god_force:PlayEffects3( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/lu_bu/assault_two_ult_reverse.vpcf"
	local sound_cast = "Hero_Mars.Shield.Cast"
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_hero_selection_skin") then
		if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 1 then
			particle_cast = "particles/custom/jia_qiu/assault_two_ult_reverse.vpcf"
			sound_cast = "jia_qiu_strike"
		end
	end
	if not caught then
		local sound_cast = "Hero_Mars.Shield.Cast.Small"
	end
	direction.z = 0
	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControlTransformForward( effect_cast, 0, self:GetCaster():GetOrigin(), direction )
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