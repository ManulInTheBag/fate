
okada_chest = class({})

function okada_chest:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=0.4, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.0})
    return true
end

function okada_chest:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end


function okada_chest:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = ability:GetCursorPosition()
	local width = ability:GetSpecialValueFor("width")
	local range = ability:GetSpecialValueFor("range")

	
	local ori = caster:GetAbsOrigin()
	local vec = (targetPoint - ori):Normalized()
	local enemies = FindUnitsInLine(
                                                                caster:GetTeamNumber(),
                                                                caster:GetAbsOrigin(),
                                                                caster:GetAbsOrigin() + vec * range,
                                                                nil,
                                                                100,
                                                                DOTA_UNIT_TARGET_TEAM_ENEMY,
                                                                DOTA_UNIT_TARGET_ALL,
                                                                0
                                                            )

	for _, enemy in pairs(enemies) do
		DoDamage(caster, enemy, self:GetSpecialValueFor("damage"), self:GetAbilityDamageType(), 0, self, false)
		--EmitSoundOn("hijikata_demon_sfx", enemy)
	end
	caster:EmitSound("mang2")


	

end

