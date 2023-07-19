nero_spectaculi_buffed = class({})

function nero_spectaculi_buffed:OnSpellStart()
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin()
	local damage = self:GetSpecialValueFor("damage") + (caster:HasModifier("modifier_sovereign_attribute") and caster:GetAverageTrueAttackDamage(caster)*self:GetSpecialValueFor("damage_scale")/100 or 0)

	if caster:GetAbilityByIndex(0):GetName() ~= "nero_tres_new" then
		caster:SwapAbilities("nero_tres_buffed", "nero_tres_new", false, true)
	end
	if caster:GetAbilityByIndex(1):GetName() ~= "nero_gladiusanus_new" then
		caster:SwapAbilities("nero_gladiusanus_buffed", "nero_gladiusanus_new", false, true)
	end
	if caster:GetAbilityByIndex(2):GetName() ~= "nero_rosa_new" then
		caster:SwapAbilities("nero_rosa_buffed", "nero_rosa_new", false, true)
	end
  if caster:GetAbilityByIndex(3):GetName() == "nero_laus_saint_claudius_new" then
    caster:SwapAbilities("nero_laus_saint_claudius_new", "nero_heat", false, true)
  end
	if caster:GetAbilityByIndex(5):GetName() ~= "nero_spectaculi_initium" then
		caster:SwapAbilities("nero_spectaculi_buffed", "nero_spectaculi_initium", false, true)
	end

	HardCleanse(caster)
	caster:EmitSound("nero_pup")

	StartAnimation(caster, {duration = 1.0, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1})

   	local slash_fx = ParticleManager:CreateParticle("particles/nero/nero_spectaculi_warp.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(slash_fx, 0, point)
       ParticleManager:SetParticleControl(slash_fx, 2, Vector(80, 0, 0))

    Timers:CreateTimer(0.4, function()
    	ParticleManager:DestroyParticle(slash_fx, false)
    	ParticleManager:ReleaseParticleIndex(slash_fx)
    end)

    local slash_fx_1 = ParticleManager:CreateParticle("particles/nero/nero_spectaculi_test.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(slash_fx_1, 0, GetGroundPosition(point, caster))
    ParticleManager:SetParticleControl(slash_fx_1, 1, Vector(self:GetSpecialValueFor("radius"), 0, 0))
    
    Timers:CreateTimer(1.0, function()
    	ParticleManager:DestroyParticle(slash_fx, false)
    	ParticleManager:ReleaseParticleIndex(slash_fx)
    	ParticleManager:DestroyParticle(slash_fx_1, false)
    	ParticleManager:ReleaseParticleIndex(slash_fx_1)
    end)

	local FirstEnemy = false

    local enemies = FindUnitsInRadius(caster:GetTeam(), point, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for _,enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
            if not enemy:IsMagicImmune() then
            	if not FirstEnemy then
              		FirstEnemy = true
               		local heat_abil = caster:FindAbilityByName("nero_heat")
   					heat_abil:IncreaseHeat(caster)
   					if not caster:HasModifier("modifier_nero_spectaculi_initium_window") then
				        caster:AddNewModifier(caster, self, "modifier_nero_spectaculi_initium_window", {duration = self:GetSpecialValueFor("window_duration")})
				    else
				        caster:RemoveModifierByName("modifier_nero_spectaculi_initium_window")
				    end
               	end
                DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                local knockback = { should_stun = false,
                                    knockback_duration = 0.25,
	                                duration = 0.25,
	                                knockback_distance = 500,
	                                knockback_height = 150,
	                                center_x = point.x,
	                                center_y = point.y,
	                                center_z = point.z }

	    		enemy:AddNewModifier(caster, self, "modifier_knockback", knockback)
            end
        end
    end
end