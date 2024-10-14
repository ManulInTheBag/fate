jeanne_crimson_saint = class({})

LinkLuaModifier("modifier_jeanne_crimson_saint", "abilities/jeanne/modifiers/modifier_jeanne_crimson_saint", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_crimson_saint_cooldown", "abilities/jeanne/modifiers/modifier_jeanne_crimson_saint_cooldown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_crimson_saint_delay", "abilities/jeanne/modifiers/modifier_jeanne_crimson_saint_delay", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_crimson_saint_stun", "abilities/jeanne/modifiers/modifier_jeanne_crimson_saint_stun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function jeanne_crimson_saint:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local delay_duration = self:GetSpecialValueFor("delay_duration")
	local buff_duration = self:GetSpecialValueFor("buff_duration")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local damage = self:GetSpecialValueFor("damage")
	local casterLocation = caster:GetAbsOrigin()
	local targets = DOTA_UNIT_TARGET_HERO
	
	local masterCombo = caster.MasterUnit2:FindAbilityByName("jeanne_crimson_saint")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(masterCombo:GetCooldown(1))
	
	EmitGlobalSound("jeanne_combo_1")
	caster:AddNewModifier( self:GetCaster(), self, "modifier_jeanne_crimson_saint_cooldown", {duration = self:GetCooldown(1)})

	local enemyuser= PickRandomEnemy(caster)
	if enemyuser then
    	caster:AddNewModifier(enemyuser, nil, "modifier_vision_provider", { Duration = 3 })
    end

	local particle = ParticleManager:CreateParticle("particles/custom/ruler/la_pucelle/ruler_la_pucelle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt( particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_origin", caster:GetAbsOrigin(), true )
	ParticleManager:SetParticleControl( particle, 1, caster:GetAbsOrigin() )

	local pucelle_ring = ParticleManager:CreateParticle("particles/custom/ruler/la_pucelle/la_pucelle_ring.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(pucelle_ring, 0, Vector(0,0,0))
	ParticleManager:SetParticleControl(pucelle_ring, 1, Vector(0,0,0))

	Timers:CreateTimer(3, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		ParticleManager:DestroyParticle(pucelle_ring, false)
		ParticleManager:ReleaseParticleIndex(pucelle_ring)
	end)
	
	Timers:CreateTimer(0, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration=3.01, activity=ACT_DOTA_CAST_ABILITY_5, rate=2})
			caster:AddNewModifier( self:GetCaster(), self, "modifier_jeanne_crimson_saint_delay", { duration = 3 } )
			caster:RemoveModifierByName("modifier_jeanne_combo_window")
		end
		return
	end)
	
	Timers:CreateTimer(3, function()
		if caster:IsAlive() then
			EmitGlobalSound("jeanne_combo_2")
			EmitGlobalSound("jeanne_la_pucelle_explosion")
		end
		return
	end)
	
	Timers:CreateTimer(3, function()
		if caster:IsAlive() and not caster:HasModifier("round_pause") then
			caster:AddNewModifier( self:GetCaster(), self, "modifier_jeanne_crimson_saint", {duration = 30} )
			
			local blastFx = ParticleManager:CreateParticle("particles/custom/jeanne/jeanne_crimson_saint_burst.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl( blastFx, 0, caster:GetAbsOrigin())
			
			--[[local LaPucelleAura = ParticleManager:CreateParticle("particles/custom/jeanne/la_pucelle_aura.vpcf", PATTACH_CUSTOMORIGIN, self.Dummy)
			ParticleManager:SetParticleControlEnt(LaPucelleAura, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true)
			ParticleManager:SetParticleControl(LaPucelleAura, 1, caster:GetOrigin())]]
			
			ScreenShake(caster:GetOrigin(), 5, 1.0, 3, 30000, 0, true)
			
			-- Find Units in Radius
			local enemies = FindUnitsInRadius(
				self:GetCaster():GetTeamNumber(),	-- int, your team number
				caster:GetAbsOrigin() ,	-- point, center point
				nil,	-- handle, cacheUnit. (not known)
				radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
				DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
				targets,	-- int, type filter
				0,	-- int, flag filter
				0,	-- int, order filter
				false	-- bool, can grow cache
			)
	
			for _,enemy in pairs(enemies) do
				DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				--enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = stun_duration })
			end
		end
		return
	end)
end

--------------------------------------------------------------------------------