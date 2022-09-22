kuro_rosa_ichthys = class({})

LinkLuaModifier("modifier_rosa_slow", "abilities/nero/modifiers/modifier_rosa_slow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rosa_buffer", "abilities/nero/modifiers/modifier_rosa_buffer", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_gladiusanus", "abilities/nero/modifiers/modifier_gladiusanus", LUA_MODIFIER_MOTION_NONE)

function nero_rosa_ichthys:GetCastRange(vLocation, hTarget)
	local hCaster = self:GetCaster()

	if hCaster:HasModifier("modifier_projection_active") then
        if hCaster:HasModifier("modifier_kuro_projection") then
            return self:GetSpecialValueFor("aestus_range")
        else
        	return self:GetSpecialValueFor("range")
        end
    else
    	return self:GetSpecialValueFor("range")
    end
end

function kuro_rosa_ichthys:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		--elseif self:GetCaster():HasModifier("modifier_aestus_domus_aurea_nero") and not hTarget:HasModifier("modifier_aestus_domus_aurea_enemy") then
		--	return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function kuro_rosa_ichthys:GetCustomCastErrorTarget(hTarget)
	--if self:GetCaster():HasModifier("modifier_aestus_domus_aurea_nero") and not hTarget:HasModifier("modifier_aestus_domus_aurea_enemy") then
	--	return "Outside Theatre"
	--else
	return "#Invalid_Target"
	--end    
end

--function nero_rosa_ichthys:GetCooldown(iLevel)
--	local caster = self:GetCaster()
--	if caster:HasModifier("modifier_aestus_domus_aurea_nero") and caster:HasModifier("modifier_sovereign_attribute") then
--		return self:GetSpecialValueFor("aestus_cooldown")
--	else
--		return self:GetSpecialValueFor("cooldown")
--	end
--end

--function nero_rosa_ichthys:GetManaCost(iLevel)
--	local caster = self:GetCaster()

--	if caster:HasModifier("modifier_aestus_domus_aurea_nero") then
--		return 100
--	else
--		return 200
--	end
--end

function kuro_rosa_ichthys:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	--caster:EmitSound("Nero.Skill1")

	return true
end

function kuro_rosa_ichthys:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local damage = self:GetSpecialValueFor("damage")
	local hCaster = self:GetCaster()

	local close_ability = self:GetCaster():FindAbilityByName("kuro_spellbook_close")
	close_ability:OnSpellCalled(self)

	if hCaster:HasModifier("modifier_projection_active") then
        if hCaster:HasModifier("modifier_kuro_projection") then
            damage = damage + hCaster:FindAbilityByName("kuro_projection"):GetSpecialValueFor("rosa_damage")
        end
        if hCaster:HasModifier("modifier_projection_active") and not hCaster:HasModifier("modifier_kuro_projection_overpower") then
            if hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()>1 then      
                hCaster:FindModifierByName("modifier_projection_active"):SetStackCount(hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()-1)
            elseif not hCaster:HasModifier("modifier_kuro_projection_overpower") then
                hCaster:RemoveModifierByName("modifier_projection_active")
            end
        end
    end

	local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()
	CreateSlashFx(caster, caster:GetAbsOrigin(), caster:GetAbsOrigin() + diff:Normalized() * diff:Length2D())
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff:Normalized() * 100)
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	StartAnimation(caster, {duration = 1, activity = ACT_DOTA_ATTACK_EVENT, rate = 1.5})	
	caster:MoveToTargetToAttack(target)

	if IsSpellBlocked(target) then return end

	caster:AddNewModifier(caster,self,"modifier_rosa_buffer", {})

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	caster:PerformAttack(target, true, true, true, true, false, false, false)
	--[[if not target:HasModifier("modifier_rosa_buffer") then
		target:AddNewModifier(caster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration") })
	end]]

	caster:RemoveModifierByName("modifier_rosa_buffer")
		
	target:EmitSound("Hero_Lion.FingerOfDeath")

	--if caster:HasModifier("modifier_ptb_attribute") then
		target:AddNewModifier(caster, target, "modifier_rosa_slow", {Duration = 3})
	--end

	local slashFx = ParticleManager:CreateParticle("particles/custom/nero/nero_scorched_earth_child_embers_rosa.vpcf", PATTACH_ABSORIGIN, target )
	ParticleManager:SetParticleControl( slashFx, 0, target:GetAbsOrigin() + Vector(0,0,300))

	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( slashFx, false )
		ParticleManager:ReleaseParticleIndex( slashFx )
	end)

	--if caster:HasModifier("modifier_sovereign_attribute") and caster:HasModifier("modifier_aestus_domus_aurea_nero") then               
      --  if not target:HasModifier("modifier_rosa_buffer") then
       -- 	target:AddNewModifier(caster, self, "modifier_rosa_buffer", { Duration = 3 })
       -- end
   -- end

    -- Too dumb to make particles, just call cleave function 4head
    DoCleaveAttack(caster, target, self, 0, 200, 400, 500, "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength.vpcf")

    self.Target = target

    local slash = 
	{
		Ability = self,
        EffectName = "",
        iMoveSpeed = 99999,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = 500,
        fStartRadius = 200,
        fEndRadius = 400,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 500
	}

	local projectile = ProjectileManager:CreateLinearProjectile(slash)
end

function kuro_rosa_ichthys:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil or hTarget == self.Target then return end

	local damage = self:GetSpecialValueFor("damage")
	local hCaster = self:GetCaster()

	--if not hCaster.IsPTBAcquired then
		damage = damage / 2
	--end

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	--if hCaster:HasModifier("modifier_sovereign_attribute") and hCaster:HasModifier("modifier_aestus_domus_aurea_nero") then               
     --   if not target:HasModifier("modifier_rosa_buffer") then
       -- 	hTarget:AddNewModifier(hCaster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration") })
        --	hTarget:AddNewModifier(hCaster, self, "modifier_rosa_buffer", { Duration = 3 })
      --  end
  --  end
	
	--hTarget:AddNewModifier(caster, self, "modifier_rosa_buffer", { Duration = 5 })
end