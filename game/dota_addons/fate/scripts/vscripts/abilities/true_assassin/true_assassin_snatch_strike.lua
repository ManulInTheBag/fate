true_assassin_snatch_strike = class({})

LinkLuaModifier("modifier_snatch_strike_str_hassan", "abilities/true_assassin/true_assassin_snatch_strike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_snatch_strike_str_enemy", "abilities/true_assassin/true_assassin_snatch_strike", LUA_MODIFIER_MOTION_NONE)

function true_assassin_snatch_strike:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("range")
end

function true_assassin_snatch_strike:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	if IsSpellBlocked(target, caster) then return end

	
	local ability = self
	local damage = self:GetSpecialValueFor("damage")
	local totalDamage = damage
	local strength = self:GetSpecialValueFor("bonus_strength")

	target:EmitSound("TA.SnatchStrike")
	caster:EmitSound("Hassan_Skill1")
	
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_void.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())

	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
		return nil
	end)

	if caster.ShaytanArmAcquired then
		local casterAgi = math.floor(caster:GetAgility() + 0.5)
		local shaytanArm = IsNotNull(caster.MasterUnit2) and caster.MasterUnit2:FindAbilityByName("true_assassin_attribute_shaytan_arm")
		local agiRatio = shaytanArm and shaytanArm:GetSpecialValueFor("snatch_agi_dmg") or 1.5

		caster:AddNewModifier(caster, ability, "modifier_snatch_strike_str_hassan", { Duration = self:GetSpecialValueFor("duration"),
																				BonusStrength = strength})

		target:AddNewModifier(caster, ability, "modifier_snatch_strike_str_enemy", { Duration = self:GetSpecialValueFor("duration"),
																				BonusStrength = strength})
		DoDamage(caster, target, casterAgi * agiRatio, DAMAGE_TYPE_PURE, 0, ability, false)
	end

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)

	caster:Heal(totalDamage / 2, caster)
end

modifier_snatch_strike_str_hassan = class({})

function modifier_snatch_strike_str_hassan:DeclareFunctions()
	return { MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS }
end

function modifier_snatch_strike_str_hassan:OnCreated(args)
	if IsServer() then
		self.BonusStrength = args.BonusStrength
		CustomNetTables:SetTableValue("sync","snatch_strike_buff", { str_bonus = args.BonusStrength })
	end
end

function modifier_snatch_strike_str_hassan:GetModifierExtraStrengthBonus()
	if IsServer() then       
        return self.BonusStrength
    elseif IsClient() then
        local str_bonus = CustomNetTables:GetTableValue("sync","snatch_strike_buff").str_bonus
        return str_bonus 
    end
end

function modifier_snatch_strike_str_hassan:GetAttributes() 
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_snatch_strike_str_hassan:IsPurgable()
    return false
end

function modifier_snatch_strike_str_hassan:IsDebuff()
    return false
end

function modifier_snatch_strike_str_hassan:RemoveOnDeath()
    return true
end

function modifier_snatch_strike_str_hassan:GetTexture()
    return "custom/true_assassin_snatch_strike"
end
--------
modifier_snatch_strike_str_enemy = class({})

function modifier_snatch_strike_str_enemy:DeclareFunctions()
	return { MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS }
end

function modifier_snatch_strike_str_enemy:OnCreated(args)
	if IsServer() then
		self.BonusStrength = args.BonusStrength
		CustomNetTables:SetTableValue("sync","snatch_strike_buff", { str_bonus = args.BonusStrength })
	end
end

function modifier_snatch_strike_str_enemy:GetModifierExtraStrengthBonus()
	if IsServer() then       
        return -1*self.BonusStrength
    elseif IsClient() then
        local str_bonus = CustomNetTables:GetTableValue("sync","snatch_strike_buff").str_bonus
        return -1*str_bonus 
    end
end

function modifier_snatch_strike_str_enemy:GetAttributes() 
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_snatch_strike_str_enemy:IsPurgable()
    return false
end

function modifier_snatch_strike_str_enemy:IsDebuff()
    return false
end

function modifier_snatch_strike_str_enemy:RemoveOnDeath()
    return true
end

function modifier_snatch_strike_str_enemy:GetTexture()
    return "custom/true_assassin_snatch_strike"
end