LinkLuaModifier("modifier_mordred_mb", "abilities/mordred/mordred_mana_burst.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("mordred_combo_window", "abilities/mordred/mordred_mana_burst", LUA_MODIFIER_MOTION_NONE)

mordred_mana_burst = class({})

function mordred_mana_burst:OnSpellStart()
	local caster = self:GetCaster()
	local mana_perc = self:GetSpecialValueFor("mana_percent")
	local mana = caster:GetMaxMana()*mana_perc/100

	if caster:GetMana() < mana then
        mana = caster:GetMana()
    end

	if not caster:HasModifier("pedigree_off") then
		mana = 1
	end

	caster:SpendMana(mana, self)

	caster:AddNewModifier(caster, self, "modifier_mordred_mb", {duration = self:GetSpecialValueFor("duration"),
																		mana = mana})
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then		
		if caster:FindAbilityByName("mordred_mb_lightning"):IsCooldownReady() 
		and caster:FindAbilityByName("mordred_mmb_lightning"):IsCooldownReady()  
		and caster:GetAbilityByIndex(2):GetName() ~= "mordred_mmb_lightning" 
		then
			caster:AddNewModifier(caster, self, "mordred_combo_window", {duration = 4})
		end
	end

	EmitSoundOn("mordred_tamare", caster)

	--[[if caster.CurseOfRetributionAcquired then
		caster:FindAbilityByName("mordred_curse_passive"):ShieldCharge()
	end]]
end

modifier_mordred_mb = class({})

function modifier_mordred_mb:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

function modifier_mordred_mb:OnCreated(args)
	if IsServer() then
		self.mana = args.mana
		self.attack_speed = self:GetAbility():GetSpecialValueFor("base_as") + self.mana*self:GetAbility():GetSpecialValueFor("mana_as")/100
		CustomNetTables:SetTableValue("sync","mordred_mana_burst_as", { as_bonus = self.attack_speed })
	end
end

function modifier_mordred_mb:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self:GetAbility():GetSpecialValueFor("base_as") + self.mana*self:GetAbility():GetSpecialValueFor("mana_as")/100
	else
		local as_bonus = CustomNetTables:GetTableValue("sync","mordred_mana_burst_as").as_bonus
        return as_bonus
    end
end

function modifier_mordred_mb:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end
	local caster_position = args.attacker:GetAbsOrigin()
	self.damage = self:GetAbility():GetSpecialValueFor("base_damage") + self.mana*self:GetAbility():GetSpecialValueFor("mana_damage")/100

	EmitSoundOn("mordred_lightning", args.target)

	local lightning_Fx = ParticleManager:CreateParticle("particles/custom/mordred/zuus_arc_lightning.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( lightning_Fx, 0, args.attacker:GetAbsOrigin())
    ParticleManager:SetParticleControl( lightning_Fx, 1, args.target:GetAbsOrigin())

	DoDamage(args.attacker, args.target, self.damage , DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)

	local zuus_static_field = ParticleManager:CreateParticle("particles/custom/mordred/zuus_static_field.vpcf", PATTACH_ABSORIGIN_FOLLOW, args.attacker)
	ParticleManager:SetParticleControl(zuus_static_field, 0, Vector(caster_position.x, caster_position.y, caster_position.z))		
	ParticleManager:SetParticleControl(zuus_static_field, 1, Vector(caster_position.x, caster_position.y, caster_position.z) * 100)	
end

mordred_combo_window = class({})

function mordred_combo_window:IsHidden() return true end