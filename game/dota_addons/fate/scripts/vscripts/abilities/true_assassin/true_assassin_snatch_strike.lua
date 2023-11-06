true_assassin_snatch_strike = class({})

LinkLuaModifier("modifier_snatch_strike_bonus_hp", "abilities/true_assassin/modifiers/modifier_snatch_strike_bonus_hp", LUA_MODIFIER_MOTION_NONE)

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
			DoDamage(caster, target, casterStr * 3, DAMAGE_TYPE_PHYSICAL, 0, ability, false)
			totalDamage = totalDamage + casterStr * 3

			DoDamage(caster, target, casterAgi * 2, DAMAGE_TYPE_PURE, 0, ability, false)
			totalDamage = totalDamage + casterAgi * 2

			DoDamage(caster, target, casterInt * 5, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			totalDamage = totalDamage + casterInt * 5
		--end
	end
	
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)	

	--caster:AddNewModifier(caster, ability, "modifier_snatch_strike_bonus_hp", { Duration = self:GetSpecialValueFor("duration"),
																	--			BonusHealth = totalDamage / 2})
	--caster:Heal(totalDamage / 2, caster)
end
