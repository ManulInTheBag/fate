LinkLuaModifier("modifier_mordred_mb_silence", "abilities/mordred/mordred_mana_burst_hit.lua", LUA_MODIFIER_MOTION_NONE)

mordred_mana_burst_hit = class({})

function mordred_mana_burst_hit:OnAbilityPhaseStart()
    local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	EmitSoundOn("mordred_shut_up", caster)
	EmitSoundOn("mordred_shut_up", target)
    return true
end

function mordred_mana_burst_hit:OnAbilityPhaseInterrupted()
    local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	StopSoundOn("mordred_shut_up", caster)
	StopSoundOn("mordred_shut_up", target)
end

function mordred_mana_burst_hit:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local mana_perc = self:GetSpecialValueFor("mana_percent")
	local mana = caster:GetMana()*mana_perc/100

	if caster:GetMana() < mana then
        mana = caster:GetMana()
    end
	
	if not caster:HasModifier("pedigree_off") then
		mana = 1
	end
	local damage = self:GetSpecialValueFor("damage") + mana*self:GetSpecialValueFor("mana_damage")/100

	local particle = ParticleManager:CreateParticle("particles/custom/mordred/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, target)
	local target_point = target:GetAbsOrigin()
	ParticleManager:SetParticleControl(particle, 0, Vector(target_point.x, target_point.y, target_point.z))
	ParticleManager:SetParticleControl(particle, 1, Vector(target_point.x, target_point.y, 2000))
	ParticleManager:SetParticleControl(particle, 2, Vector(target_point.x, target_point.y, target_point.z))

	caster:SpendMana(mana, self)

	EmitSoundOn("mordred_lightning", caster)
	EmitSoundOn("mordred_lightning", target)

	if IsSpellBlocked(target) then return end

	target:AddNewModifier(caster, self, "modifier_mordred_mb_silence", {duration = self:GetSpecialValueFor("duration")})

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	
	if caster:HasModifier("pedigree_off") and caster:HasModifier("modifier_mordred_overload") then
    	local kappa = caster:FindModifierByName("modifier_mordred_overload")
    	kappa:Doom()
   	end

	--[[if caster.CurseOfRetributionAcquired then
		caster:FindAbilityByName("mordred_curse_passive"):ShieldCharge()
	end]]
end

modifier_mordred_mb_silence = class({})

function modifier_mordred_mb_silence:CheckState()
    local state =   {
                        [MODIFIER_STATE_SILENCED] = true
                    }
    return state
end

function modifier_mordred_mb_silence:IsDebuff() return true end