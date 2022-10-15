LinkLuaModifier("mordred_combo_window", "abilities/mordred/mordred_top_secret", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("mordred_armor_shred", "abilities/mordred/mordred_top_secret", LUA_MODIFIER_MOTION_NONE)

mordred_slash = class({})

function mordred_slash:OnSpellStart()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then		
		if caster:FindAbilityByName("mordred_clarent"):IsCooldownReady() 
		and caster:FindAbilityByName("mordred_mmb_lightning"):IsCooldownReady()  
		and caster:GetAbilityByIndex(2):GetName() ~= "mordred_mmb_lightning" 
		then
			caster:AddNewModifier(caster, self, "mordred_combo_window", {duration = 4})
		end
	end

	if caster:HasModifier("pedigree_off") and caster:HasModifier("modifier_mordred_overload") then
    	local kappa = caster:FindModifierByName("modifier_mordred_overload")
    	kappa:Doom()
   	end

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        500,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies) do
		local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
		local origin_diff_norm = origin_diff:Normalized()
		if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
			if caster:HasModifier("pedigree_off") and not enemy:IsMagicImmune() then
				DoDamage(caster, enemy, self:GetSpecialValueFor("mana_damage")/100*caster:GetMana()*self:GetSpecialValueFor("mana_percent")/100, DAMAGE_TYPE_MAGICAL, 0, self, false)
		       	enemy:AddNewModifier(caster, self, "modifier_stunned", {Duration = self:GetSpecialValueFor("duration")})
		        EmitSoundOn("mordred_lightning", enemy)
		        Timers:CreateTimer(0.01, function()
		            local particle = ParticleManager:CreateParticle("particles/custom/mordred/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, enemy)
		            local target_point = enemy:GetAbsOrigin()
		            ParticleManager:SetParticleControl(particle, 0, Vector(target_point.x, target_point.y, target_point.z))
		            ParticleManager:SetParticleControl(particle, 1, Vector(target_point.x, target_point.y, 2000))
		            ParticleManager:SetParticleControl(particle, 2, Vector(target_point.x, target_point.y, target_point.z))
		        end)
		    end
		    if caster.RampageAcquired then
		    	enemy:AddNewModifier(caster, self, "mordred_armor_shred", {})
		    end
		    DoDamage(caster, enemy, self:GetSpecialValueFor("base_damage") + self:GetSpecialValueFor("crit_damage")*caster:GetAverageTrueAttackDamage(caster)/100, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		    if caster.RampageAcquired then
		    	enemy:RemoveModifierByName("mordred_armor_shred")
		    end
		    DoCleaveAttack(caster, enemy, self, 0, 200, 400, 500, "particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength.vpcf")
        end
    end
end

mordred_combo_window = class({})

function mordred_combo_window:IsHidden() return true end

mordred_armor_shred = class({})

function mordred_armor_shred:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

if IsServer() then
	function mordred_armor_shred:OnCreated(args)
		self.ArmorReduction = (self:GetParent():GetPhysicalArmorValue(false)) * -0.5
	end
end

function mordred_armor_shred:GetModifierPhysicalArmorBonus()
	return self.ArmorReduction
end

function mordred_armor_shred:IsHidden()
	return true 
end