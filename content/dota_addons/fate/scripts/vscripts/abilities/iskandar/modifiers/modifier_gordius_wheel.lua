modifier_gordius_wheel = class({})

LinkLuaModifier("modifier_gordius_wheel_hit", "abilities/iskandar/modifiers/modifier_gordius_wheel_hit", LUA_MODIFIER_MOTION_NONE)

function modifier_gordius_wheel:DeclareFunctions()
	return { MODIFIER_EVENT_ON_UNIT_MOVED, 
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_MOVESPEED_MAX,
			 MODIFIER_PROPERTY_MOVESPEED_LIMIT,
			 MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE
			 }
end

function modifier_gordius_wheel:GetModifierMoveSpeed_Limit()
	return 5000
end

function modifier_gordius_wheel:GetModifierMoveSpeed_Max()
	return 5000
end

function modifier_gordius_wheel:GetModifierTurnRate_Percentage()
	return -350
end

if IsServer() then
	function modifier_gordius_wheel:CheckState()
		return self.State
	end

	function modifier_gordius_wheel:OnCreated(args)
		self.Movespeed = 1
		self.LastLocation = self:GetParent():GetAbsOrigin()
		local caster = self:GetParent()

		self.Damage = caster:GetMoveSpeedModifier(caster:GetBaseMoveSpeed(), true)

		CustomNetTables:SetTableValue("sync","gordius_wheel", {movespeed = self.Movespeed})

		caster.OriginalModel = "models/iskander/iskander_chariot.vmdl"
		caster:SetModel("models/iskander/iskander_chariot.vmdl")
		caster:SetOriginalModel("models/iskander/iskander_chariot.vmdl")
		caster:SetModelScale(1.0)

		self.Mounting = true
		self.State = { [MODIFIER_STATE_ROOTED] = true,
					   [MODIFIER_STATE_STUNNED] = true }

		self:StartIntervalThink(1)
	end

	function modifier_gordius_wheel:OnDestroy()
		local caster = self:GetParent()
		caster.OriginalModel = "models/iskander/iskander.vmdl"
	    caster:SetModel("models/iskander/iskander.vmdl")
	    caster:SetOriginalModel("models/iskander/iskander.vmdl")
	    caster:SetModelScale(1.0)
	end

	function modifier_gordius_wheel:OnIntervalThink()
		if self.Mounting then
			self.State = { [MODIFIER_STATE_ROOTED] = false,
						   [MODIFIER_STATE_STUNNED] = false }

			self.Mounting = false
			self:StartIntervalThink(0.25)
		else
			local new_position = self:GetParent():GetAbsOrigin()
			local caster = self:GetParent()

			if (self.LastLocation - new_position):Length2D() < 25 then
				self.Movespeed = 1
			else
				self.Movespeed = self.Movespeed + 8
			end

			self.LastLocation = new_position
			self.Damage = caster:GetMoveSpeedModifier(caster:GetBaseMoveSpeed(), true)

			CustomNetTables:SetTableValue("sync","gordius_wheel", { movespeed = self.Movespeed })
		end
	end

	function modifier_gordius_wheel:OnUnitMoved(args)
		if args.unit ~= self:GetParent() then return end

		local caster = self:GetParent()

		local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for i = 1, #enemies do	
        	if not enemies[i]:HasModifier("modifier_gordius_wheel_hit") then
	            DoDamage(caster, enemies[i], self.Damage * 1.25, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				enemies[i]:AddNewModifier(caster, self:GetAbility(), "modifier_gordius_wheel_hit", { Duration = 1.25})
				enemies[i]:AddNewModifier(caster, enemies[i], "modifier_stunned", { Duration = 0.75 })

				enemies[i]:EmitSound("Iskandar_Chariot_hit")
			end
		end

		local cow_position = caster:GetAbsOrigin() + caster:GetForwardVector() * 250

		local enemies = FindUnitsInRadius(caster:GetTeam(), cow_position, nil, 175, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for i = 1, #enemies do	
        	if not enemies[i]:HasModifier("modifier_gordius_wheel_hit") then
	            DoDamage(caster, enemies[i], self.Damage * 0.75, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				enemies[i]:AddNewModifier(caster, self:GetAbility(), "modifier_gordius_wheel_hit", { Duration = 1.25})
				enemies[i]:AddNewModifier(caster, enemies[i], "modifier_stunned", { Duration = 0.75 })

				enemies[i]:EmitSound("Iskandar_Chariot_hit")
			end
		end
	end
end

function modifier_gordius_wheel:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then        
        return self.Movespeed
    elseif IsClient() then
        local movespeed = CustomNetTables:GetTableValue("sync","gordius_wheel").movespeed
        return movespeed 
    end
end