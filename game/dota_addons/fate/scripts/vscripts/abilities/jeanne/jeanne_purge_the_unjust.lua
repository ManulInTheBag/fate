LinkLuaModifier("modifier_jeanne_vision", "abilities/jeanne/modifiers/modifier_jeanne_vision", LUA_MODIFIER_MOTION_NONE)

jeanne_purge_the_unjust = class({})

function jeanne_purge_the_unjust:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function jeanne_purge_the_unjust:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local delay = self:GetSpecialValueFor("delay")
	local baseDamage = self:GetSpecialValueFor("damage")
	local silenceDuration = self:GetSpecialValueFor("silence_duration")
	
	if caster:HasModifier("modifier_jeanne_crimson_saint") then
		delay = delay/2
		silenceDuration = silenceDuration * 1.3
	end
	--[[if caster.IsPunishmentAcquired then
		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if not IsImmuneToSlow(v) then 
				ability:ApplyDataDrivenModifier(caster, v, "modifier_purge_the_unjust_slow", {})
			end
		end
	end]]

	local markFx = ParticleManager:CreateParticle("particles/custom/ruler/purge_the_unjust/ruler_purge_the_unjust_marker.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( markFx, 0, targetPoint)
	EmitSoundOnLocationWithCaster(targetPoint, "Hero_Chen.PenitenceImpact", caster)	

	local soundQueue = math.random(1,6)

	caster:EmitSound("Jeanne_Skill_" .. soundQueue)

	local damage_type = DAMAGE_TYPE_MAGICAL

	Timers:CreateTimer(delay, function()
		--[[if caster.IsPunishmentAcquired then
			damage_type = DAMAGE_TYPE_PURE
		end]]

		local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if not v:IsMagicImmune() then				
		        DoDamage(caster, v, baseDamage, damage_type, 0, self, false)
		        giveUnitDataDrivenModifier(caster, v, "silenced", silenceDuration)
		        giveUnitDataDrivenModifier(caster, v, "disarmed", silenceDuration)
			end

	        if caster.IsRevelationAcquired then
	        	v:AddNewModifier(caster, self, "modifier_jeanne_vision", { Duration = self:GetSpecialValueFor("reveal_duration") })
	        end
	    end

	    EmitSoundOnLocationWithCaster(targetPoint, "Hero_Chen.TestOfFaith.Target", caster)		
		--[[local purgeFx = ParticleManager:CreateParticle("particles/custom/ruler/purge_the_unjust/ruler_purge_the_unjust_a.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl( purgeFx, 0, targetPoint)
		ParticleManager:SetParticleControl( purgeFx, 1, targetPoint)
		ParticleManager:SetParticleControl( purgeFx, 2, targetPoint)]]
		local fireFx = ParticleManager:CreateParticle("particles/custom/jeanne/jeanne_purge_reborn.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl( fireFx, 0, targetPoint)
	end)
end