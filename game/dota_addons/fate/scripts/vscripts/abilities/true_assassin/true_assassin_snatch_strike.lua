true_assassin_snatch_strike = class({})

LinkLuaModifier("modifier_snatch_strike_bonus_hp", "abilities/true_assassin/modifiers/modifier_snatch_strike_bonus_hp", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_snatch_strike_str_hassan", "abilities/true_assassin/true_assassin_snatch_strike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_snatch_strike_str_enemy", "abilities/true_assassin/true_assassin_snatch_strike", LUA_MODIFIER_MOTION_NONE)

function true_assassin_snatch_strike:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("range")
end

function true_assassin_snatch_strike:OnSpellStart()
	local target = self:GetCursorTarget()

	if IsSpellBlocked(target) then return end

	local caster = self:GetCaster()
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
		local casterStr = math.floor(caster:GetStrength() + 0.5) 
		local casterAgi = math.floor(caster:GetAgility() + 0.5)
		local casterInt = math.floor(caster:GetIntellect() + 0.5)

		--if (casterStr >= casterAgi and casterStr > casterInt)   then
			--print("Strength")
		--	DoDamage(caster, target, casterStr * 3, DAMAGE_TYPE_PHYSICAL, 0, ability, false)
		--	totalDamage = totalDamage + casterStr * 3
		--elseif casterAgi > casterStr and casterAgi >= casterInt then
			--print("Agility")
		--	DoDamage(caster, target, casterAgi * 2, DAMAGE_TYPE_PURE, 0, ability, false)
		--	totalDamage = totalDamage + casterAgi * 2
		--elseif casterInt > casterStr and casterInt > casterAgi then
			--print("Intelligence")
		--	DoDamage(caster, target, casterInt * 5, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		--	totalDamage = totalDamage + casterInt * 5
		--else
			--[[DoDamage(caster, target, casterStr * 3, DAMAGE_TYPE_PHYSICAL, 0, ability, false)
			totalDamage = totalDamage + casterStr * 3]]


			caster:AddNewModifier(caster, ability, "modifier_snatch_strike_str_hassan", { Duration = self:GetSpecialValueFor("duration"),
																					BonusStrength = strength})

			target:AddNewModifier(caster, ability, "modifier_snatch_strike_str_enemy", { Duration = self:GetSpecialValueFor("duration"),
																					BonusStrength = strength})
			DoDamage(caster, target, casterAgi * 1.5, DAMAGE_TYPE_PURE, 0, ability, false)
		--	totalDamage = totalDamage + casterAgi * 2

			--[[DoDamage(caster, target, casterInt * 5, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			totalDamage = totalDamage + casterInt * 5]]
		--end
	end
	
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)	

	--caster:AddNewModifier(caster, ability, "modifier_snatch_strike_bonus_hp", { Duration = self:GetSpecialValueFor("duration"),
																	--			BonusHealth = totalDamage / 2})
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