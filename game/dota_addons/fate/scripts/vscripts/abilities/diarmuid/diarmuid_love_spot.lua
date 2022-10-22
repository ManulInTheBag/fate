diarmuid_love_spot = class({})

LinkLuaModifier("modifier_love_spot", "abilities/diarmuid/modifiers/modifier_love_spot", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rampant_warrior_window", "abilities/diarmuid/modifiers/modifier_rampant_warrior_window", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_love_spot_charmed", "abilities/diarmuid/modifiers/modifier_love_spot_charmed", LUA_MODIFIER_MOTION_NONE)

function diarmuid_love_spot:OnSpellStart()
	local caster = self:GetCaster()
	local target  = self:GetCursorTarget()
	local forcemove = {
		UnitIndex = nil,
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION ,
		Position = nil
	}
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
			if playerHero.gachi == true then
				-- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="diar_love_spot"})
				--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		 
			end
		   end)
		 
	--caster:AddNewModifier(caster, self, "modifier_love_spot", { Duration = self:GetSpecialValueFor("duration"),	Radius = self:GetSpecialValueFor("radius") })
	--self:CheckCombo()
	target:AddNewModifier(caster, self, "modifier_love_spot_charmed", { Duration = self:GetSpecialValueFor("duration") })
	
	caster:EmitSound("Hero_Warlock.ShadowWord")
end

--[[
function diarmuid_love_spot:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("diarmuid_double_spearmanship"):IsCooldownReady() and not caster:HasModifier("modifier_rampant_warrior_cooldown") then
			caster:AddNewModifier(caster, self, "modifier_rampant_warrior_window", { Duration = 3 })
		end
	end
end
]]