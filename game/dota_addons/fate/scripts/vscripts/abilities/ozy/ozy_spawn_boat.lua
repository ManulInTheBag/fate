ozy_spawn_boat = class({})
LinkLuaModifier("modifier_ozy_no_healthbar", "abilities/ozy/ozy_spawn_piramid", LUA_MODIFIER_MOTION_NONE)

function ozy_spawn_boat:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local playerId = hCaster:GetPlayerID()

	if IsNotNull(hCaster.boat) then
		CustomGameEventManager:Send_ServerToPlayer( hCaster:GetPlayerOwner(), "ozy_select_boat", {boat = hCaster.boat:entindex()} )
	else
		local life_dur = 90
		local boat = CreateUnitByName("ozy_boat", vTargetPoint, false, hCaster, hCaster, hCaster:GetTeamNumber())
		boat:SetControllableByPlayer(hCaster:GetPlayerID(), true)
		boat:SetOwner(hCaster)
		boat:AddNewModifier(hCaster, self, "modifier_ozy_no_healthbar", {duration = life_dur})
		--hCaster.Piramid = Piramid
		boat:AddNewModifier(hCaster, self, "modifier_phased", {duration = life_dur})
		hCaster.boat = boat
		boat.ozy = hCaster
	end


	--Piramid.Ozy = hCaster
	--FindClearSpaceForUnit(Piramid, Piramid:GetAbsOrigin(), true)
	
	-- Level abilities

	hCaster.boat:SetHullRadius(0)
	hCaster.boat:SetBaseMoveSpeed(0)
	hCaster.boat:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE )
			

end

function ozy_spawn_boat:OnOwnerDied()
	local hCaster = self:GetCaster()
	if IsNotNull(hCaster.boat) and hCaster.boat:IsAlive() then
		hCaster.boat:Kill(nil, hCaster)
	end
end
