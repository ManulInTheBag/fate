karna_armor = class({})

LinkLuaModifier("modifier_karna_armor", "abilities/karna/karna_new_abilities/karna_armor", LUA_MODIFIER_MOTION_NONE)
function karna_armor:GetAOERadius()
	return self:GetSpecialValueFor("explosion_radius")
end

function karna_armor:CastFilterResult()
    local caster = self:GetCaster()
    if IsServer() and  (caster:FindModifierByName("modifier_karna_self_pause") or caster:FindModifierByName("modifier_karna_self_pause_2") or caster:FindModifierByName("karna_no_spear")) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function karna_armor:GetCustomCastError()
	return "Performing other ability"
end

local tArmorAbilities = {
    "karna_spin",
    "karna_slashes",
    "karna_buff_melee",
    "karna_jump",
    
}
 

local tNoArmorAbilities = {
    "karna_push",
    "karna_brahmastra_new",
	"karna_brahmastra_kundala_new",
    "karna_spears_barrage",
}

function karna_armor:OnSpellStart()
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_karna_armor")
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.5) 
	caster:RemoveModifierByName("modifier_karna_buff_melee")
	local buff_ability = caster:FindAbilityByName("karna_buff_melee")
	if (buff_ability.fx) then	
		ParticleManager:DestroyParticle( buff_ability.fx, false )
		ParticleManager:ReleaseParticleIndex( buff_ability.fx )
		Timers:RemoveTimer("karna_buff_melee_fx")
	end
	caster:GiveMana(caster:GetMaxMana() * self:GetSpecialValueFor("mana_resplenish_percentage")/100)
	if modifier.ArmorActive == true then
		caster:EmitSound("karna_new_karna_remove_armor_voice")
		caster:EmitSound("karna_new_fire_explosion")
		StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_COLD_SNAP, rate=1})
		modifier:RestoreArmorPercentage(50)
		local effect_shield= ParticleManager:CreateParticle("particles/karna/karna_armor_shield.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(effect_shield, 0, caster, PATTACH_POINT_FOLLOW, "attach_shield", caster:GetAbsOrigin(), false )
		--print("active armor disable")
		
		Timers:CreateTimer(0.4, function()
			ParticleManager:DestroyParticle(effect_shield, true)
			ParticleManager:ReleaseParticleIndex(effect_shield)
			local origin = caster:GetAbsOrigin()
			local damage = self:GetSpecialValueFor("explosion_damage_base") + modifier:GetStackCount() * self:GetSpecialValueFor("explosion_damage_armor_pct")/100
			local effect_ground_= ParticleManager:CreateParticle("particles/karna/karna_armor_change_use.vpcf", PATTACH_WORLDORIGIN, caster)
			ParticleManager:SetParticleControl(effect_ground_, 0, caster:GetAbsOrigin() )
			ParticleManager:SetParticleControl(effect_ground_, 1, Vector(self:GetSpecialValueFor("explosion_radius"),1,2))
			ParticleManager:SetParticleControl(effect_ground_, 3, caster:GetAbsOrigin())
			local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, self:GetSpecialValueFor("explosion_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
			for k,v in pairs(targets) do
				if v:GetName() ~= "npc_dota_ward_base" then
						DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
						if( not IsKnockbackImmune(v)) then
							local dur = self:GetSpecialValueFor("explosion_stun_duration")
							local knockback = { should_stun = true,
												knockback_duration = dur,
												duration = dur,
												knockback_distance = self:GetSpecialValueFor("explosion_radius") - (caster:GetAbsOrigin() - v:GetAbsOrigin()):Length2D(),
												knockback_height = 50,
												center_x = origin.x,
												center_y = origin.y,
												center_z = origin.z }
							v:RemoveModifierByName("modifier_knockback")
							v:AddNewModifier(caster,self, "modifier_knockback", knockback)
						end
				end
			end
			ParticleManager:ReleaseParticleIndex(effect_ground_)
			caster:SetBodygroup(0, 1)
			modifier:RemoveArmor()
			caster:SwapAbilities(tArmorAbilities[1], tNoArmorAbilities[1], false, true)
			caster:SwapAbilities(tArmorAbilities[2], tNoArmorAbilities[2], false, true)
			caster:SwapAbilities(tArmorAbilities[3], tNoArmorAbilities[3], false, true)
			if caster:GetAbilityByIndex(5):GetName() == "karna_jump" then
				caster:SwapAbilities(tArmorAbilities[4], tNoArmorAbilities[4], false, true)
			else
				Timers:RemoveTimer("karna_jump_ab_change_window")
				caster:SwapAbilities(caster:GetAbilityByIndex(5):GetName(), tNoArmorAbilities[4], false, true)
			end
			if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then		
				if caster:FindAbilityByName("karna_combo_vasavi_new"):IsCooldownReady() 	
				then
					caster:SwapAbilities("karna_armor", "karna_combo_vasavi_new", false, true)
					Timers:CreateTimer("karna_combo_window", {
						endTime = 3,
						callback = function()
						if caster:GetAbilityByIndex(4):GetName() == "karna_combo_vasavi_new"  then
							caster:SwapAbilities("karna_armor", "karna_combo_vasavi_new", true, false)
						end
						return end
					})
				end
			end
		end)


		return
	end
	if modifier.ArmorActive == false then
		caster:EmitSound("karna_new_karna_return_armor_voice")
		StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ICE_WALL, rate=1})
		--print("active armor enable")
		caster:SetBodygroup(0, 3)
		Timers:CreateTimer(0.3, function()
			caster:SetBodygroup(0, 0)
			modifier:ReturnArmor()
			caster:SwapAbilities(tArmorAbilities[1], tNoArmorAbilities[1], true, false)
			caster:SwapAbilities(tArmorAbilities[2], tNoArmorAbilities[2], true, false)
			if caster:GetAbilityByIndex(2):GetName() == "karna_brahmastra_kundala_new" then
				caster:SwapAbilities(tArmorAbilities[3], tNoArmorAbilities[3], true, false)
			else
				caster:SwapAbilities("karna_brahmastra_kundala_retrieve", "karna_brahmastra_kundala_new", false, true)
				caster:SwapAbilities(tArmorAbilities[3], tNoArmorAbilities[3], true, false)
			end
			caster:SwapAbilities(tArmorAbilities[4], tNoArmorAbilities[4], true, false)
	
		end)


		return
	end
end




function karna_armor:GetIntrinsicModifierName()
	return "modifier_karna_armor"
end

modifier_karna_armor = class({})
 

function modifier_karna_armor:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			 MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
			 MODIFIER_EVENT_ON_RESPAWN,
			 MODIFIER_EVENT_ON_HEAL_RECEIVED,
			 MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE }
end

if IsServer() then

	function modifier_karna_armor:OnRespawn(args) 
		if(self.hCaster ~= args.unit) then return end

		self.hCaster:SetBodygroup(0,0)
		if self.hCaster:GetAbilityByIndex(0):GetName() ~= "karna_spin" then
			self.hCaster:SwapAbilities(tArmorAbilities[1], tNoArmorAbilities[1], true, false)
		end
		if self.hCaster:GetAbilityByIndex(1):GetName() ~= "karna_slashes" then
			self.hCaster:SwapAbilities(tArmorAbilities[2], tNoArmorAbilities[2], true, false)
		end
		if self.hCaster:GetAbilityByIndex(2):GetName() ~= "karna_buff_melee" then
			self.hCaster:SwapAbilities(tArmorAbilities[3], tNoArmorAbilities[3], true, false)
		end
		if self.hCaster:GetAbilityByIndex(5):GetName() ~= "karna_jump" then
			self.hCaster:SwapAbilities(tArmorAbilities[4], tNoArmorAbilities[4], true, false)
		end
		self.hAbility:EndCooldown()
		self.fMaxBarrierBlock = self.hAbility:GetSpecialValueFor("armor_base") + self.hAbility:GetSpecialValueFor("armor_per_level") * self.hCaster:GetLevel()
		self.Armor = self.hAbility:GetSpecialValueFor("bonus_armor")
		self.MagicResist = self.hAbility:GetSpecialValueFor("bonus_resist")
		CustomNetTables:SetTableValue("sync","karna_armor", { armor = self.Armor,
																magic_resist = self.MagicResist })
		self.fBarrierBlock = self.fMaxBarrierBlock
		self:SetStackCount(self.fMaxBarrierBlock)
		self:ReturnArmor()
		self.ArmorRegenActive = false
		--self:StartIntervalThink(0.1)
	end

	function modifier_karna_armor:OnHealReceived(args) 
		if(self.hCaster ~= args.unit) then return end
		if self.hCaster.ArmorActive == false then return end

		if (self.hCaster:GetHealth() < self.hCaster:GetMaxHealth()) then
			local diff = self.hCaster:GetMaxHealth() - self.hCaster:GetHealth()
			if args.gain < diff then return end
			local shield_gain = args.gain - diff
			local percentage = shield_gain/self.fMaxBarrierBlock * 100
			self:RestoreArmorPercentage(percentage)
		else
			if self.fBarrierBlock < self.fMaxBarrierBlock then 
				local shield_gain = args.gain
				local percentage = shield_gain/self.fMaxBarrierBlock * 100
				self:RestoreArmorPercentage(percentage)
			end
		end
	end
	
	
	function modifier_karna_armor:OnCreated(args)
		--print("oncreated")
		self.hCaster  = self:GetCaster()
		self.hParent  = self:GetParent()
		self.hAbility = self:GetAbility()
		self.Armor = self.hAbility:GetSpecialValueFor("bonus_armor")
		self.MagicResist = self.hAbility:GetSpecialValueFor("bonus_resist")
		self.ArmorActive = true
		self.ArmorRegenActive = false

		self.fMaxBarrierBlock = self.hAbility:GetSpecialValueFor("armor_base") + self.hAbility:GetSpecialValueFor("armor_per_level") * self.hCaster:GetLevel()
		self.fBarrierBlock = self.fMaxBarrierBlock
		self:SetStackCount(self.fBarrierBlock)
		--self.hAbility:GetSpecialValueFor("attribute_shield_amount")
		CustomNetTables:SetTableValue("sync","karna_armor", { armor = self.Armor,
																  magic_resist = self.MagicResist })
	end


	function modifier_karna_armor:RemoveArmor()
		if self.ArmorActive == false then return end
		self.Armor = 0
		self.MagicResist = 0
		self.ArmorActive = false
		--self:SetDuration(0.1, true) -- why is it not working???????????
		self.ArmorRegenActive = false
		self:SetStackCount(0)
		self:StartIntervalThink(-1)
		CustomNetTables:SetTableValue("sync","karna_armor", { armor = self.Armor,
																  magic_resist = self.MagicResist })

	end

	function modifier_karna_armor:ReturnArmor()
		if self.ArmorActive == true then return end
		self.Armor = self.hAbility:GetSpecialValueFor("bonus_armor")
		self.MagicResist = self.hAbility:GetSpecialValueFor("bonus_resist")
		self.ArmorActive = true
		self.ArmorRegenActive = false
		self.fMaxBarrierBlock = self.hAbility:GetSpecialValueFor("armor_base") + self.hAbility:GetSpecialValueFor("armor_per_level") * self.hCaster:GetLevel()
		self.fBarrierBlock = self.fMaxBarrierBlock
		self:SetStackCount(self.fMaxBarrierBlock)
		self.hAbility:EndCooldown()
		self:StartIntervalThink(-1)
		CustomNetTables:SetTableValue("sync","karna_armor", { armor = self.Armor,
																  magic_resist = self.MagicResist })

	end

	function modifier_karna_armor:RestoreArmorPercentage(percentage)
		if self.ArmorActive == false then return end
		local stack_count = self:GetStackCount()
		self.fMaxBarrierBlock = self.hAbility:GetSpecialValueFor("armor_base") + self.hAbility:GetSpecialValueFor("armor_per_level") * self.hCaster:GetLevel()
		local new_stack_count = self.fMaxBarrierBlock * percentage/100 + stack_count
		if new_stack_count > self.fMaxBarrierBlock then new_stack_count = self.fMaxBarrierBlock end
		self:SetStackCount(new_stack_count)
		self.Armor = self.hAbility:GetSpecialValueFor("bonus_armor")
		self.MagicResist = self.hAbility:GetSpecialValueFor("bonus_resist")
		self.fBarrierBlock = new_stack_count
		CustomNetTables:SetTableValue("sync","karna_armor", { armor = self.Armor,
																  magic_resist = self.MagicResist })

	end
end
function modifier_karna_armor:GetModifierHPRegenAmplify_Percentage()
	if self.ArmorActive and  (self.hCaster:GetHealth() >= self.hCaster:GetMaxHealth()) then
		 return -100
	else 
		return nil
	end
end

function modifier_karna_armor:GetModifierMagicalResistanceBonus()
	--if self.fBarrierBlock <= 0 then return 0 end
	if IsServer() then
		--if self.fBarrierBlock <= 0 then return 0 end
		return self.MagicResist
	elseif IsClient() then
		local magic_resist = CustomNetTables:GetTableValue("sync","karna_armor").magic_resist
        return magic_resist 
	end
end

function modifier_karna_armor:GetModifierPhysicalArmorBonus()
	--if self.fBarrierBlock <= 0 then return 0 end
	if IsServer() then
		--if self.fBarrierBlock <= 0 then return 0 end
		return self.Armor
	elseif IsClient() then
		local armor = CustomNetTables:GetTableValue("sync","karna_armor").armor
		return armor 
	end
end

function modifier_karna_armor:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_karna_armor:IsDebuff()
	return false
end

function modifier_karna_armor:DestroyOnExpire()
	return false
end


function modifier_karna_armor:OnIntervalThink()
	if self.ArmorActive == false then return end
	if self.ArmorRegenActive == false then
		--print("jopa")
		self:StartIntervalThink(-1)
		self:StartIntervalThink(0.1)

		self.ArmorRegenActive = true
		return
	end
	--print("jopa2")
	self.fMaxBarrierBlock = self.hAbility:GetSpecialValueFor("armor_base") + self.hAbility:GetSpecialValueFor("armor_per_level") * self.hCaster:GetLevel()
	self.fBarrierBlock = self.fBarrierBlock + self.fMaxBarrierBlock/10
	if self.fBarrierBlock >= self.fMaxBarrierBlock then 
		self.fBarrierBlock = self.fMaxBarrierBlock
		self:StartIntervalThink(-1)
		self.ArmorRegenActive = false

	end
	self:SetStackCount(self.fBarrierBlock)
	self.Armor = self.hAbility:GetSpecialValueFor("bonus_armor")
	self.MagicResist = self.hAbility:GetSpecialValueFor("bonus_resist")
	CustomNetTables:SetTableValue("sync","karna_armor", { armor = self.Armor,
															  magic_resist = self.MagicResist })
end

 
function modifier_karna_armor:GetModifierIncomingDamageConstant(keys)
	if self.ArmorActive == false then return end
	self:StartIntervalThink(-1)
	self:StartIntervalThink(10)

	self:SetDuration(10, true)
	self.ArmorRegenActive = false
	if IsServer() then
		if self:GetStackCount() > 0 then 
			if keys.damage > 0 then
				local block_now   = self:GetStackCount()
				local block_check = block_now - keys.damage
				local blocked = 0
				if block_check > 0 then
					blocked = keys.damage
					self:SetStackCount(block_check)
					self.fBarrierBlock = block_check
				else
					blocked = keys.damage--block_now
					local damage = keys.damage - block_now
					local unblocked_dmg_percentage = damage/keys.damage
					damage = keys.original_damage *unblocked_dmg_percentage
					local dmgtable = {
						attacker = keys.attacker,
						victim = keys.target,
						damage = damage,
						damage_type = keys.damage_type,
						damage_flags = keys.damage_flags,
						ability = keys.inflictor
					}
					--self:Destroy()
					self:SetStackCount(0)
					--self.ArmorActive = false
					self.Armor = 0
					self.MagicResist = 0
					CustomNetTables:SetTableValue("sync","karna_armor", { armor = self.Armor,
																			  magic_resist = self.MagicResist })
					ApplyDamage(dmgtable)


					self:SetDuration(10, true)
				end

				return -1*blocked
			end
		end
	else
		return self:GetStackCount()
	end
end


