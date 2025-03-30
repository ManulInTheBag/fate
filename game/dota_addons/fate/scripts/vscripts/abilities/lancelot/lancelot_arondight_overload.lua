lancelot_arondight_overload = class({})

function lancelot_arondight_overload:CastFilterResultLocation(vLocation)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_lancelot_minigun") then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

function lancelot_arondight_overload:GetCustomCastErrorLocation(vLocation)
    return "#Minigun_Active"
end

function lancelot_arondight_overload:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.6, activity=ACT_DOTA_CAST_ABILITY_ROT, rate=2})
end

function lancelot_arondight_overload:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end


function lancelot_arondight_overload:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local vOrigin = hCaster:GetAbsOrigin()
	local aoe_damage = self:GetSpecialValueFor("damage")
	local aoe_radius = self:GetSpecialValueFor("radius")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	if hCaster:HasModifier("modifier_kotl_attribute") then
		aoe_damage = aoe_damage + hCaster:GetAverageTrueAttackDamage(hCaster) * 1.5
	end
	giveUnitDataDrivenModifier(hCaster, hCaster, "pause_sealenabled", 0.4)

	Timers:CreateTimer(0.2, function()
		hCaster:EmitSound("lancelot_arondight_overload_slash")
		local particle = ParticleManager:CreateParticle("particles/lancelot/lancelot_slash_overload.vpcf", PATTACH_ABSORIGIN, hCaster)
		ParticleManager:SetParticleControlTransformForward(particle, 0, hCaster:GetAbsOrigin(), hCaster:GetForwardVector())
		ParticleManager:ReleaseParticleIndex(particle)
		
	end)
	Timers:CreateTimer(0.35, function()
		if hCaster:IsAlive() then

			local blastFx = ParticleManager:CreateParticle("particles/custom/lancelot/arondight_overload_new_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl( blastFx, 0, hCaster:GetAbsOrigin() + hCaster:GetForwardVector() * 300)
			ParticleManager:SetParticleControl( blastFx, 1, Vector(aoe_radius, aoe_radius, aoe_radius))
			ParticleManager:ReleaseParticleIndex(blastFx)
			local targets = FindUnitsInRadius(hCaster:GetTeamNumber(), hCaster:GetAbsOrigin(), hCaster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
			for k,v in pairs(targets) do
				if v:GetName() ~= "npc_dota_ward_base" then
					local origin_diff = v:GetAbsOrigin() - hCaster:GetAbsOrigin()
					local origin_diff_norm = origin_diff:Normalized()
					if hCaster:GetForwardVector():Dot(origin_diff_norm) > 0 then
						DoDamage(hCaster, v, aoe_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
						hCaster:PerformAttack(v, true, true, true, true, false, false, true)
						giveUnitDataDrivenModifier(hCaster,v , "stunned", stun_duration)
					end
				end
			end

			EmitSoundOn("arondite_overload_impact", hCaster)
	
			self.flash = ParticleManager:CreateParticle("particles/custom/kinghassan/azraelflash.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(self.flash, 0, hCaster:GetAbsOrigin() + hCaster:GetForwardVector() * 300)
			ParticleManager:SetParticleControl(self.flash, 1, hCaster:GetAbsOrigin() + hCaster:GetForwardVector() * 300)	
			ParticleManager:ReleaseParticleIndex(self.flash)		
		end
	end)

	


end