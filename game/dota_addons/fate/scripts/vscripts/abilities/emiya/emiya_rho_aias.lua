emiya_rho_aias = class({})

LinkLuaModifier("modifier_rho_aias", "abilities/emiya/modifiers/modifier_rho_aias", LUA_MODIFIER_MOTION_NONE)

local rhoTarget = nil

function emiya_rho_aias:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	local ability = self
	local ply = caster:GetPlayerOwner()
	
	rhoTarget = target 
	target.rhoShieldAmount = self:GetSpecialValueFor("shield_amount")

	local soundQueue = math.random(1,2)

	if soundQueue == 1 then
		caster:EmitSound("Archer.RhoAias" ) 
	else
		caster:EmitSound("Emiya_Rho_Aias_Alt")
	end
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true    then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_emiya_d"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	caster:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")

	target:AddNewModifier(caster, self, "modifier_rho_aias", { Duration = self:GetSpecialValueFor("duration") })
end