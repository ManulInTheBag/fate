modifier_unlimited_bladeworks_autoblade = class({})

function modifier_unlimited_bladeworks_autoblade:OnCreated(args)
	if IsServer() then
		self:StartIntervalThink(0.2)
	end
end

function modifier_unlimited_bladeworks_autoblade:OnIntervalThink()
	local caster = self:GetParent()
	local weaponTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    
    if #weaponTargets == 0 then 
    	return
    end

    local targetIndex = RandomInt(1, #weaponTargets)
    local swordTarget = weaponTargets[targetIndex]

    if IsValidEntity(weaponTargets[targetIndex]) then
        local swordOrigin = caster:GetAbsOrigin() + Vector(0,0,500) + RandomVector(1000)
        local swordVector = (weaponTargets[targetIndex]:GetAbsOrigin() - swordOrigin):Normalized()

        local swordFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_sword_barrage_model.vpcf", PATTACH_CUSTOMORIGIN, caster )
        ParticleManager:SetParticleControl( swordFxIndex, 0, swordOrigin )
        ParticleManager:SetParticleControl( swordFxIndex, 1, swordVector * 5000 )
        
        Timers:CreateTimer(0.1, function()
            if swordTarget:IsAlive() and not swordTarget:HasModifier("modifier_lancer_protection_from_arrows_active") then
                DoDamage(caster, swordTarget, 75, DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false)
            end
            ParticleManager:DestroyParticle(swordFxIndex, false )
            ParticleManager:ReleaseParticleIndex( swordFxIndex )
        end)
    end
end

function modifier_unlimited_bladeworks_autoblade:IsHidden()
	return true 
end

function modifier_unlimited_bladeworks_autoblade:RemoveOnDeath()
	return true
end