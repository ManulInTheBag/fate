gilgamesh_sword_rain = class({})

LinkLuaModifier("modifier_sword_rain_thinker", "abilities/gilgamesh/modifiers/modifier_sword_rain_thinker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rain_of_swords_count", "abilities/gilgamesh/modifiers/modifier_rain_of_swords_count", LUA_MODIFIER_MOTION_NONE)

function gilgamesh_sword_rain:GetAOERadius()
	if self:GetCaster():HasModifier("modifier_rain_of_swords_attribute") and self:GetCaster():HasModifier("modifier_rain_of_swords_count") then 
		local stacks = self:GetCaster():GetModifierStackCount("modifier_rain_of_swords_count", self:GetCaster())
		--print(stacks)
		return self:GetSpecialValueFor("radius") + (stacks * self:GetSpecialValueFor("attribute_bonus_aoe"))
	else
		return self:GetSpecialValueFor("radius")
	end
end

function gilgamesh_sword_rain:GetManaCost()
	if self:GetCaster():HasModifier("modifier_rain_of_swords_attribute") and self:GetCaster():HasModifier("modifier_rain_of_swords_count") then 
		local stacks = self:GetCaster():GetModifierStackCount("modifier_rain_of_swords_count", self:GetCaster())
		--print(stacks)
		return self:GetSpecialValueFor("manacost") + (stacks * self:GetSpecialValueFor("attribute_bonus_manacost"))
	else
		return self:GetSpecialValueFor("manacost")
	end
end

--[[
function gilgamesh_sword_rain:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function gilgamesh_sword_rain:GetCastPoint()
	return self:GetSpecialValueFor("cast_point")
end
]]

function gilgamesh_sword_rain:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
 	self.dummy = CreateUnitByName("dummy_unit", target, false, nil, nil, caster:GetTeamNumber())
	self.dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	local dummy = self.dummy
	Timers:CreateTimer(3, function()
		dummy:RemoveSelf()
	end)
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true  and playerHero:GetTeamNumber() == caster:GetTeamNumber() then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_gil_w"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
 
	local damage_per_tick = self:GetSpecialValueFor("damage")

	if caster:HasModifier("modifier_rain_of_swords_attribute") and self:GetCaster():HasModifier("modifier_rain_of_swords_count") then
		local stacks = caster:GetModifierStackCount("modifier_rain_of_swords_count", caster)
		damage_per_tick = damage_per_tick + (stacks * self:GetSpecialValueFor("attrbute_bonus_damage"))
	end

	caster:EmitSound("Archer.UBWAmbient")
	CreateModifierThinker(caster, self, "modifier_sword_rain_thinker", 
						  { Damage = damage_per_tick,
						    Radius = self:GetAOERadius(),
						    Duration = self:GetSpecialValueFor("duration") + 0.033 }, 
						  self:GetCursorPosition(), caster:GetTeamNumber(), false)

	if caster:HasModifier("modifier_rain_of_swords_attribute") then
		caster:AddNewModifier(caster, self, "modifier_rain_of_swords_count", { Duration = 5 })
	end
end