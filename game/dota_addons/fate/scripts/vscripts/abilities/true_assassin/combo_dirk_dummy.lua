combo_dirk_dummy = class({})

function combo_dirk_dummy:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	
	caster:EmitSound("Hero_PhantomAssassin.Dagger.Cast")
	
	local info = {
		Target = target,
		Source = caster, 
		Ability = ability,
		EffectName = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 1800
	}

	ProjectileManager:CreateTrackingProjectile(info)
end

function true_assassin_dirk:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end
    local ability = self
    local hCaster = self:GetCaster()
    local fDamage = self:GetSpecialValueFor("damage") 
    local fPoisonDamage = self:GetSpecialValueFor("poison_dot")
    
    if IsSpellBlocked(hTarget) or hTarget:IsMagicImmune() then return end

    if not hCaster.IsWeakeningVenomAcquired then
    	fDamage = fDamage + hCaster:GetAverageTrueAttackDamage(hCaster)
    else
    	fPoisonDamage = fPoisonDamage + (math.ceil(hCaster:GetAgility()) * 0.5)
    end

    hTarget:AddNewModifier(hCaster, ability, "modifier_dirk_poison", {	Duration = self:GetSpecialValueFor("duration"),
																		PoisonDamage = fPoisonDamage,
																		PoisonSlow = self:GetSpecialValueFor("poison_slow") })
    hTarget:EmitSound("Hero_PhantomAssassin.Dagger.Target")

	DoDamage(hCaster, hTarget, fDamage, DAMAGE_TYPE_PHYSICAL, 0, ability, false)

	local stacks = 0
	if hTarget:HasModifier("modifier_weakening_venom") then 
		stacks = hTarget:GetModifierStackCount("modifier_weakening_venom", ability)
	end		

	hTarget:RemoveModifierByName("modifier_weakening_venom") 
	hTarget:AddNewModifier(hCaster, ability, "modifier_weakening_venom", { duration = 12 })	

	if hCaster.IsWeakeningVenomAcquired then
		hTarget:SetModifierStackCount("modifier_weakening_venom", ability, stacks + self:GetSpecialValueFor("venom_stacks"))
	else
		hTarget:SetModifierStackCount("modifier_weakening_venom", ability, stacks + 1)
	end
end