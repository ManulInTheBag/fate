LinkLuaModifier("modifier_ryougi_backflip", "abilities/ryougi/ryougi_backflip", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_backflip_2", "abilities/ryougi/ryougi_backflip", LUA_MODIFIER_MOTION_NONE)

ryougi_backflip = class({})

function ryougi_backflip:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=1.20, activity=ACT_DOTA_CAST_ABILITY_4, rate=2})
    return true
end

function ryougi_backflip:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function ryougi_backflip:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	StartAnimation(self:GetCaster(), {duration=1.20, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.5})
	--caster:AddNewModifier(caster, self, "modifier_ryougi_backflip_2", {duration = 0.11})
	--StartAnimation(caster, {duration=1.20, activity=ACT_DOTA_CAST_ABILITY_4, rate=1})
	Timers:CreateTimer(0.0, function()
		--if caster:IsStunned() then return end

		ProjectileManager:ProjectileDodge(caster)

		local origin = caster:GetAbsOrigin()
		local direction = (caster:GetAbsOrigin() - target):Normalized()
		direction.z = 0
		caster:SetForwardVector(-direction)
		local range = self:GetSpecialValueFor("range")

		--[[if (Vector(target.x, target.y, 0) == Vector(origin.x, origin.y, 0)) then
			direction = caster:GetForwardVector()
		end]]

		caster:AddNewModifier(caster, self, "modifier_ryougi_backflip", {duration = 0.5})
		Timers:CreateTimer(0, function()
			if not caster:IsAlive() then
				return
			end
			if not caster:HasModifier("modifier_ryougi_backflip") then
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
				return
			end

			local origin_t = caster:GetAbsOrigin()
			--caster:SetForwardVector(direction)
			caster:SetAbsOrigin(GetGroundPosition(origin_t + direction*range/0.5*0.033, caster))
			return 0.033
		end)
	end)
end

modifier_ryougi_backflip = class({})

function modifier_ryougi_backflip:CheckState()
	return { [MODIFIER_STATE_INVULNERABLE] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 [MODIFIER_STATE_UNSELECTABLE] = true,
			 [MODIFIER_STATE_STUNNED] = true}
end

function modifier_ryougi_backflip:IsHidden() return true end

modifier_ryougi_backflip_2 = class({})

function modifier_ryougi_backflip_2:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true}
end

function modifier_ryougi_backflip_2:IsHidden() return true end

function modifier_ryougi_backflip_2:DeclareFunctions()
	return { MODIFIER_PROPERTY_DISABLE_TURNING }
end

function modifier_ryougi_backflip_2:GetModifierDisableTurning()
	return 1
end


-- LinkLuaModifier("modifier_ryougi_model_swap", "abilities/ryougi/ryougi_backflip", LUA_MODIFIER_MOTION_NONE)
-- --NOTE: Function to handle swapping between models in-game.
-- if IsServer() then
--     if type(ryougi_abilities_chat_event) == "number" then
--         StopListeningToGameEvent(ryougi_abilities_chat_event)
--     end
--     --===--
--     _G.ryougi_abilities_chat_event = ListenToGameEvent("player_chat", function(tEventTable)
--         local nPlayerID = tEventTable.playerid
--         local sText     = tEventTable.text
--         local hHero     = PlayerResource:GetSelectedHeroEntity(nPlayerID)
--         if not (hHero:GetName() == "npc_dota_hero_phantom_assassin") then
--             return
--         end
--         if IsNotNull(hHero) then
--             if sText == "-ryougi1" then
--                 hHero:RemoveModifierByName("modifier_ryougi_model_swap")
--             end
--             if sText == "-ryougi2" then
--                 if GameRules:GetDOTATime(false, false) <= 300 then --300
--                     hHero:AddNewModifier(hHero, nil, "modifier_ryougi_model_swap", {})
--                 end
--             end
--         end
--     end, nil)
-- end


-- modifier_ryougi_model_swap = modifier_ryougi_model_swap or class({})

-- function modifier_ryougi_model_swap:IsHidden()                                                                       return true end
-- function modifier_ryougi_model_swap:IsDebuff()                                                                       return false end
-- function modifier_ryougi_model_swap:IsPurgable()                                                                     return false end
-- function modifier_ryougi_model_swap:IsPurgeException()                                                               return false end
-- function modifier_ryougi_model_swap:RemoveOnDeath()                                                                  return false end
-- function modifier_ryougi_model_swap:IsDimensionException()                                                           return true end
-- function modifier_ryougi_model_swap:AllowIllusionDuplicate()                                                         return true end
-- function modifier_ryougi_model_swap:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
-- function modifier_ryougi_model_swap:DeclareFunctions()
--     local tFunc =   {
--                         MODIFIER_PROPERTY_MODEL_CHANGE
--                     }
--     return tFunc
-- end
-- function modifier_ryougi_model_swap:GetModifierModelChange(keys)
--     return self.sModelName
-- end
-- function modifier_ryougi_model_swap:OnCreated(hTable)
--     self.hCaster  = self:GetCaster()
--     self.hParent  = self:GetParent()
--     self.hAbility = self:GetAbility()
--     if IsServer() then
--         self.sModelName = "models/zlodemon/shiki_ryougi_skin/ryougi_skin.vmdl"
--     end
-- end
-- function modifier_ryougi_model_swap:OnRefresh(hTable)
--     self:OnCreated(hTable)
-- end

-- --========================================--
