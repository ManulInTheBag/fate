ryougi_knife_recast = class({})

function ryougi_knife_recast:OnUpgrade()
	local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_knife_throw"):GetLevel() ~= self:GetLevel() then
    	hCaster:FindAbilityByName("ryougi_knife_throw"):SetLevel(self:GetLevel())
    end
end

function ryougi_knife_recast:CastFilterResult()
	local caster = self:GetCaster()
	if IsServer() then
		local target = caster.CurrentKnifeTarget
		local dist = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()

		if dist > self:GetSpecialValueFor("range") then 
			return UF_FAIL_CUSTOM 
		end
	end
	return UF_SUCCESS
end

function ryougi_knife_recast:GetCustomCastError()
    return "#Target_out_of_range"
end

function ryougi_knife_recast:OnSpellStart()
	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local damage_first = self:GetSpecialValueFor("damage_first")
	local damage_second = self:GetSpecialValueFor("damage_second")
	local damage_per_line = self:GetSpecialValueFor("damage_per_line")
	local eyes = caster:FindAbilityByName("ryougi_mystic_eyes")
	local target = Vector(0, 0, 0)

	EmitGlobalSound("ryougi_nibio")

	local combo_enemy = caster.CurrentKnifeTarget
	local origin = caster:GetAbsOrigin()
	local point = combo_enemy:GetAbsOrigin()
	local direction = (point-origin)
	direction.z = 0
	direction = direction:Normalized()
	target = point + direction*150

	local stacks = combo_enemy:FindModifierByName("modifier_ryougi_lines") and combo_enemy:FindModifierByName("modifier_ryougi_lines"):GetStackCount() or 0
	local execute = damage_per_line*stacks

	combo_enemy:RemoveModifierByName("modifier_ryougi_knife_target")
	combo_enemy:RemoveModifierByName("modifier_ryougi_lines")

	FindClearSpaceForUnit( caster, target, true)
	caster:SetForwardVector(direction)
	local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_red.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
  	ParticleManager:SetParticleControl( effect_cast, 0, origin )
    ParticleManager:SetParticleControl( effect_cast, 1, target)
    ParticleManager:SetParticleControl( effect_cast, 2, target )
    Timers:CreateTimer(1.0, function()
        ParticleManager:DestroyParticle(effect_cast, true)
        ParticleManager:ReleaseParticleIndex( effect_cast )
    end)

    giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.5)
	StartAnimation(caster, {duration=0.69, activity=ACT_DOTA_RAZE_1, rate=1})

	eyes:CutLine(combo_enemy, "knife_recast_1")
    DoDamage(caster, combo_enemy, damage_first, DAMAGE_TYPE_PURE, 0, self, false)
	local fxIndex = ParticleManager:CreateParticle( "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_omni_slash_tgt_serrakura.vpcf", PATTACH_ABSORIGIN, caster)
	local random_vector = RandomVector(200)
	random_vector.z = 0
	ParticleManager:SetParticleControl( fxIndex, 0, combo_enemy:GetAbsOrigin()+random_vector + Vector(0, 0, 300))
	ParticleManager:SetParticleControl( fxIndex, 1, combo_enemy:GetAbsOrigin()-random_vector)
	EmitSoundOn("ryougi_hit", combo_enemy)

	local particle0 = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_red_big.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle0, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle0, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
	ParticleManager:SetParticleControl(particle0, 10, Vector(0, 0, -120))

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle0, false)
		ParticleManager:ReleaseParticleIndex(particle0)
	end)

	Timers:CreateTimer(0.4, function()
		StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_RAZE_2, rate=2})

		Timers:CreateTimer(0.1, function()
			local origin2 = caster:GetAbsOrigin()
			local point2 = combo_enemy:GetAbsOrigin()
			local direction2 = (point2-origin2)
		    direction2.z = 0
		    direction2 = direction2:Normalized()
		    target = point2 + direction2*150

		    FindClearSpaceForUnit( caster, target, true)
		    caster:SetForwardVector(direction2)

		    eyes:CutLine(combo_enemy, "knife_recast_2")

		    DoDamage(caster, combo_enemy, damage_second, DAMAGE_TYPE_PURE, 0, self, false)
			local fxIndex = ParticleManager:CreateParticle( "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_omni_slash_tgt_serrakura.vpcf", PATTACH_ABSORIGIN, caster)
			local random_vector = RandomVector(200)
			random_vector.z = 0
			ParticleManager:SetParticleControl( fxIndex, 0, combo_enemy:GetAbsOrigin()+random_vector + Vector(0, 0, 300))
			ParticleManager:SetParticleControl( fxIndex, 1, combo_enemy:GetAbsOrigin()-random_vector)
			EmitSoundOn("jtr_slash", caster)
			combo_enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = 0.2 })
			EmitSoundOn("ryougi_hit", combo_enemy)

			if combo_enemy:GetHealthPercent() < execute and not (combo_enemy:IsMagicImmune() or combo_enemy:HasModifier("modifier_avalon")) then
				combo_enemy:Execute(self, caster, { bExecution = true })
			end

		    effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_step_red.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		  	ParticleManager:SetParticleControl( effect_cast, 0, origin2 )
		    ParticleManager:SetParticleControl( effect_cast, 1, target)
		    ParticleManager:SetParticleControl( effect_cast, 2, target )
		    Timers:CreateTimer(1.0, function()
		        ParticleManager:DestroyParticle(effect_cast, true)
		        ParticleManager:ReleaseParticleIndex( effect_cast )
		    end)

			local particle2 = ParticleManager:CreateParticle("particles/ryougi/ryougi_slash_red_big.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle2, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 70))
			ParticleManager:SetParticleControl(particle2, 10, Vector(0, 0, -120))

			Timers:CreateTimer(1, function()
				ParticleManager:DestroyParticle(particle2, false)
				ParticleManager:ReleaseParticleIndex(particle2)
			end)
		end)
	end)
end