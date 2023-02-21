jtr_dagger_throw = class({})

LinkLuaModifier("modifier_jtr_dagger_mark", "abilities/jtr/modifiers/modifier_jtr_dagger_mark", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jtr_dagger_slow", "abilities/jtr/modifiers/modifier_jtr_dagger_slow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dagger_throw_crit", "abilities/jtr/modifiers/modifier_dagger_throw_crit", LUA_MODIFIER_MOTION_NONE)

function jtr_dagger_throw:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if not (IsServer() and IsLocked(hCaster)) and not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function jtr_dagger_throw:GetCustomCastErrorLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if IsServer() and IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) then
            return "#Is_Locked"
        end
    end
    return "#Wrong_Target_Location"
end

function jtr_dagger_throw:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local origin = caster:GetAbsOrigin()
    local crit = self:GetSpecialValueFor("dagger_ratio_1")/100
    local damage = self:GetSpecialValueFor("base_damage") + caster:GetAverageTrueAttackDamage(caster)*crit
    local damage_type = DAMAGE_TYPE_MAGICAL

    local max_dist = self:GetSpecialValueFor("cast_range")
    --[[if caster:HasModifier("modifier_whitechapel_murderer") then
        max_dist = max_dist/2
    end]]
    local width = self:GetSpecialValueFor("width")
    local hit_count = 3

    local direction = (point-origin)
    local dist = math.min( max_dist, direction:Length2D() )
    direction.z = 0
    direction = direction:Normalized()

    local target = GetGroundPosition( origin + direction*dist, nil )

    FindClearSpaceForUnit( caster, target, true )

    local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        origin,
								        target,
								        nil,
								        width,
										self:GetAbilityTargetTeam(),
										self:GetAbilityTargetType(),
										self:GetAbilityTargetFlags()
    								)

    local hits_done = 1

    EmitSoundOn("jtr_slash", caster)

    Timers:CreateTimer(0, function()
    	if caster and IsValidEntity(caster) and enemies and #enemies>0 then
		    for _, enemy in pairs(enemies) do
		    	if caster:HasModifier("modifier_murderer_mist_in") and IsFemaleServant(enemy) then
    				damage_type = DAMAGE_TYPE_PURE
  				end
		        DoDamage(caster, enemy, damage, damage_type, 0, self, false)

		        --self:PlayEffects2(enemy)

		      	enemy:EmitSound("jtr_slash")
		    end
		end

		hits_done = hits_done + 1

		if hits_done >= hit_count then
			return nil
		end

		return 0.05
	end)

    self:PlayEffects1(origin, target)

    --caster:StartGesture(ACT_DOTA_CAST_ABILITY_6)
end
---------------------------------------------------------------------------------------------------------------------
function jtr_dagger_throw:PlayEffects1( origin, target )
    if self:GetCaster():HasModifier("modifier_jtr_bloody_thirst_active") then
        local effect_cast = ParticleManager:CreateParticle( "particles/jtr/void_spirit_immortal_2021_astral_step.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
    					    ParticleManager:SetParticleControl( effect_cast, 0, origin )
    					    ParticleManager:SetParticleControl( effect_cast, 1, target)
    					    ParticleManager:SetParticleControl( effect_cast, 2, target )
                            Timers:CreateTimer(1.0, function()
                                ParticleManager:DestroyParticle(effect_cast, true)
                                ParticleManager:ReleaseParticleIndex( effect_cast )
                            end)
    					
    else
        local effect_cast = ParticleManager:CreateParticle( "particles/jtr/jtr_slash.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
                        ParticleManager:SetParticleControl( effect_cast, 0, origin )
                        ParticleManager:SetParticleControl( effect_cast, 1, origin)
                        ParticleManager:SetParticleControl( effect_cast, 2, target )
                        ParticleManager:ReleaseParticleIndex( effect_cast )
                        Timers:CreateTimer(1.0, function()
                            ParticleManager:DestroyParticle(effect_cast, true)
                            ParticleManager:ReleaseParticleIndex( effect_cast )
                        end)
    end

    --EmitSoundOnLocationWithCaster( origin, sound_start, self:GetCaster() )
    --EmitSoundOnLocationWithCaster( target, sound_end, self:GetCaster() )
end
---------------------------------------------------------------------------------------------------------------------
function jtr_dagger_throw:PlayEffects2( target )
    local effect_cast = ParticleManager:CreateParticle( "particles/heroes/anime_hero_okita/okita_slash_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
    					ParticleManager:ReleaseParticleIndex( effect_cast )
end