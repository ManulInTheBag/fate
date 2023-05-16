jeanne_luminosite_eternelle = class({})

LinkLuaModifier("modifier_jeanne_luminosite_eternelle", "abilities/jeanne/modifiers/modifier_jeanne_luminosite_eternelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_luminosite_eternelle_slow", "abilities/jeanne/modifiers/modifier_jeanne_luminosite_eternelle_slow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_revelation_eternelle_buff", "abilities/jeanne/modifiers/modifier_revelation_eternelle_buff", LUA_MODIFIER_MOTION_NONE)

-- Spell Start + Addition of Modifier

function jeanne_luminosite_eternelle:OnChannelThink(fInterval)
    self.ChannelTime = (self.ChannelTime or 0) + fInterval
end

function jeanne_luminosite_eternelle:OnSpellStart()
	local caster = self:GetCaster()
	
	EmitGlobalSound("jeanne_luminosite")
	
	self.ChannelTime = 0
	
	Timers:CreateTimer(0, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration=5.0, activity=ACT_DOTA_CAST_ABILITY_4, rate=1})
		end
		return
	end)

	caster:AddNewModifier( self:GetCaster(), self, "modifier_jeanne_luminosite_eternelle", { duration = self:GetChannelTime() } )
	
end

-- Spell Finish + Removal of Modifier

function jeanne_luminosite_eternelle:OnChannelFinish( bInterrupted )
	local caster = self:GetCaster()

	StopGlobalSound("jeanne_luminosite")
	
	if self.ChannelTime < 4.9 then
		caster:RemoveModifierByName( "modifier_jeanne_luminosite_eternelle" )
		StartAnimation(caster, {duration=0.01, activity=ACT_DOTA_CAST_ABILITY_4, rate=1})
	else
		caster:RemoveModifierByName( "modifier_jeanne_luminosite_eternelle" )

		local radius = self:GetSpecialValueFor("radius")
	
		local final_burst_heal = self:GetSpecialValueFor("final_burst_heal")
		
		if caster.IsDivineSymbolAcquired then
			final_burst_heal = final_burst_heal + 200
		end
		
		caster:EmitSound("jeanne_heal_beep")
	
		local targets = DOTA_UNIT_TARGET_HERO
		
		local healFx = ParticleManager:CreateParticle("particles/custom/jeanne/jeanne_luminosite_eternelle_final_burst.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl( healFx, 0, caster:GetAbsOrigin())
		
		Timers:CreateTimer( 6.0, function()
			ParticleManager:DestroyParticle( healFx, false )
			ParticleManager:ReleaseParticleIndex( healFx )
		end)

		-- Find Units in Radius
		local allies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),	-- int, your team number
			caster:GetAbsOrigin() ,	-- point, center point
			nil,	-- handle, cacheUnit. (not known)
			radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,	-- int, team filter
			targets,	-- int, type filter
			0,	-- int, flag filter
			0,	-- int, order filter
			false	-- bool, can grow cache
		)
	
		for _,ally in pairs(allies) do
			-- Add modifier
			ally:Heal(final_burst_heal, caster)
			if caster.IsDivineSymbolAcquired then
				HardCleanse(ally)
			end
			
			--[[if caster.IsRevelationAcquired then
				ally:AddNewModifier(caster, self, "modifier_revelation_eternelle_buff", { duration = 10 })
			end]]
		end
		
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
			-- Add modifier
			if caster.IsDivineSymbolAcquired then
				ApplyStrongDispel(enemy)
			end
			
			DoDamage(caster, enemy, 1, DAMAGE_TYPE_MAGICAL, 0, self, false)			
			enemy:AddNewModifier(caster, self, "modifier_jeanne_luminosite_eternelle_slow", { Duration = 1 })
		end
	end
end

--------------------------------------------------------------------------------