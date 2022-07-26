LinkLuaModifier("modifier_atalanta_pull_slow", "abilities/alter_atalanta/atalanta_pull", LUA_MODIFIER_MOTION_NONE)

atalanta_pull = class({})

function atalanta_pull:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("atalanta_ora")
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then		
		if caster:FindAbilityByName("atalanta_jump"):IsCooldownReady() 
			and caster:FindAbilityByName("atalanta_skia"):IsCooldownReady()  
		   	and caster:GetAbilityByIndex(2):GetName() == "atalanta_jump" then
			caster:SwapAbilities("atalanta_jump", "atalanta_skia", false, true)
			Timers:CreateTimer(4, function()
				caster:SwapAbilities("atalanta_jump", "atalanta_skia", true, false)
			end)
		end
	end
	local enemies2 = FindUnitsInRadius(  caster:GetTeamNumber(),
                                            caster:GetAbsOrigin(), 
                                            nil, 
                                            self:GetSpecialValueFor("radius"), 
                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
                                            0, 
                                            FIND_ANY_ORDER, 
                                            false)
	for _,enemy in ipairs(enemies2) do
	            local knockback = { should_stun = false,
	                                knockback_duration = 0.5,
	                                duration = 0.5,
	                                knockback_distance = caster.TornadoAcquired and -300 or 0,
	                                knockback_height = 0,
	                                center_x = caster:GetAbsOrigin().x,
	                                center_y = caster:GetAbsOrigin().y,
	                                center_z = caster:GetAbsOrigin().z }

	    enemy:AddNewModifier(caster, self, "modifier_knockback", knockback)
	    enemy:AddNewModifier(caster, self, "modifier_atalanta_pull_slow", {duration = self:GetSpecialValueFor("slow_dur")})
	    DoDamage(caster, enemy, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
        for i = 1,(self:GetSpecialValueFor("curse_stacks") + (caster.TornadoAcquired and 5 or 0)) do
          	caster:FindAbilityByName("atalanta_curse"):Curse(enemy)
        end
    end
    StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_OVERRIDE_ABILITY_2, rate=1.0})
    local hit_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_vacuum.vpcf", PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( hit_fx, 0, GetGroundPosition(caster:GetAbsOrigin(), caster))
	ParticleManager:SetParticleControl( hit_fx, 1, Vector(self:GetSpecialValueFor("radius"), 0, 0))
end

modifier_atalanta_pull_slow = class({})

function modifier_atalanta_pull_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			--MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
			}
end
function modifier_atalanta_pull_slow:GetModifierMoveSpeedBonus_Percentage()
	return -(self:GetAbility():GetSpecialValueFor("ms_slow") + (self:GetCaster().CursedMoonAcquired and (self:GetParent():HasModifier("modifier_atalanta_curse") and self:GetParent():FindModifierByName("modifier_atalanta_curse"):GetStackCount() or 0) or 0))
end
--[[function modifier_atalanta_pull_slow:GetModifierAttackSpeedBonus_Constant()
	return -(self:GetAbility():GetSpecialValueFor("as_slow") + (self:GetCaster().CursedMoonAcquired and (self:GetParent():HasModifier("modifier_atalanta_curse") and self:GetParent():FindModifierByName("modifier_atalanta_curse"):GetStackCount() or 0) or 0))
end]]