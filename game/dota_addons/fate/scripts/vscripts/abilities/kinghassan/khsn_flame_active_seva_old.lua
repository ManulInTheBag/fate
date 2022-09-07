LinkLuaModifier("modifier_khsn_toggle_mana", "abilities/kinghassan/khsn_flame_active", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_flame1", "abilities/kinghassan/khsn_stab", LUA_MODIFIER_MOTION_NONE)

khsn_flame_active = class({})

 
function khsn_flame_active:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
		--[[local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
	                                        caster:GetAbsOrigin(),
	                                        nil,
	                                        99999,
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                        DOTA_UNIT_TARGET_ALL,
	                                        DOTA_UNIT_TARGET_FLAG_NONE,
	                                        FIND_ANY_ORDER,
	                                        false)]]

		caster:AddNewModifier(caster, self, "modifier_khsn_toggle_mana", {})

		--for _, enemy in pairs(enemies) do
		    --if enemy and not enemy:IsNull() and IsValidEntity(enemy) and not enemy:IsMagicImmune() and enemy:HasModifier("modifier_death_door") then
		    	--[[local modifier = enemy:FindModifierByName("modifier_khsn_flame1")
		    	local ability = caster:FindAbilityByName("khsn_stab")
		        local time_remaining = modifier.duration_pepeg
		        local damage = modifier.flame_damage_second
		        enemy.khsn_flame_remaining_duration = time_remaining
		        enemy:RemoveModifierByName("modifier_khsn_flame1")]]
		        --local ability = caster:FindAbilityByName("khsn_azrael")
		        --local new_modifier = enemy:AddNewModifier(caster, ability, "modifier_khsn_flame1", {duration = 99999})
		        --new_modifier.flame_damage_second = damage
		    --end
		--end
    else
		--[[local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
	                                        caster:GetAbsOrigin(),
	                                        nil,
	                                        99999,
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                        DOTA_UNIT_TARGET_ALL,
	                                        DOTA_UNIT_TARGET_FLAG_NONE,
	                                        FIND_ANY_ORDER,
	                                        false)]]

		caster:RemoveModifierByName("modifier_khsn_toggle_mana")
		self:StartCooldown(self:GetSpecialValueFor("cooldown"))

		--[[for _, enemy in pairs(enemies) do
		    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
		    	enemy:RemoveModifierByName("modifier_khsn_flame1")
		    end
		end]]
    end
end

modifier_khsn_toggle_mana = class({})

function modifier_khsn_toggle_mana:IsHidden() return false end
function modifier_khsn_toggle_mana:IsDebuff() return true end
function modifier_khsn_toggle_mana:RemoveOnDeath() return true end
function modifier_khsn_toggle_mana:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.mana = self.ability:GetSpecialValueFor("base_mana_per_second")
	self.add_mana = self.ability:GetSpecialValueFor("add_mana_per_second")
	self.duration_pepeg = 0.1

	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end
function modifier_khsn_toggle_mana:OnIntervalThink()
	if IsServer() then
		self.duration_pepeg = self.duration_pepeg + 0.1
		if self.duration_pepeg >= 1 then
			self.duration_pepeg = 0
			self.mana = self.mana + self.add_mana
		end
		local enemies = FindUnitsInRadius(  self.parent:GetTeamNumber(),
	                                        self.parent:GetAbsOrigin(),
	                                        nil,
	                                        99999,
	                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                        DOTA_UNIT_TARGET_ALL,
	                                        DOTA_UNIT_TARGET_FLAG_NONE,
	                                        FIND_ANY_ORDER,
	                                        false)

		for _, enemy in pairs(enemies) do
		    if enemy and not enemy:IsNull() and IsValidEntity(enemy) and not enemy:IsMagicImmune() and enemy:HasModifier("modifier_death_door") then
		    	--[[local modifier = enemy:FindModifierByName("modifier_khsn_flame1")
		    	local ability = caster:FindAbilityByName("khsn_stab")
		        local time_remaining = modifier.duration_pepeg
		        local damage = modifier.flame_damage_second
		        enemy.khsn_flame_remaining_duration = time_remaining
		        enemy:RemoveModifierByName("modifier_khsn_flame1")]]
		        local ability = self.parent:FindAbilityByName("khsn_azrael")
		        local new_modifier = enemy:AddNewModifier(self.parent, ability, "modifier_khsn_flame1", {duration = 0.2})
		        --new_modifier.flame_damage_second = damage
		    end
		end
		self.parent:SpendMana(self.mana/10, self.ability)
		if self.parent:GetMana() < 10 then
			self.parent:RemoveModifierByName("modifier_khsn_toggle_mana")
		end
	end
end
function modifier_khsn_toggle_mana:OnDestroy()
	if IsServer() then
        if self.ability:GetToggleState() then
            self.ability:ToggleAbility()
        end
    end
end