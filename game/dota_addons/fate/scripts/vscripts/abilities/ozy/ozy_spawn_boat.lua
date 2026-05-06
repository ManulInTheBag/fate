ozy_spawn_boat = class({})
LinkLuaModifier("modifier_ozy_no_healthbar", "abilities/ozy/ozy_spawn_piramid", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ozy_boat_passive", "abilities/ozy/ozy_spawn_boat", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)
function ozy_spawn_boat:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTargetPoint = self:GetCursorPosition()
	local playerId = hCaster:GetPlayerID()
	if (vTargetPoint-hCaster:GetAbsOrigin()):Length2D() > 1000 then
		vTargetPoint = hCaster:GetAbsOrigin() + (vTargetPoint-hCaster:GetAbsOrigin()):Normalized() * 1000
	end
	if IsNotNull(hCaster.boat) then
		CustomGameEventManager:Send_ServerToPlayer( hCaster:GetPlayerOwner(), "ozy_select_boat", {boat = hCaster.boat:entindex()} )
	else
		local life_dur = 120
		local boat = CreateUnitByName("ozy_boat", vTargetPoint, false, hCaster, hCaster, hCaster:GetTeamNumber())
		boat:SetControllableByPlayer(hCaster:GetPlayerID(), true)
		boat:SetOwner(hCaster)
		boat:AddNewModifier(hCaster, self, "modifier_ozy_no_healthbar", {duration = life_dur})
		boat:AddNewModifier(hCaster, self, "modifier_kill", { duration = life_dur })
		boat:AddNewModifier(hCaster, self, "modifier_ozy_boat_passive", { duration = life_dur })
		if hCaster.ozySa2Acquired then
			boat:FindAbilityByName("ozy_boat_sunstrike"):SetLevel(2)
			boat:FindAbilityByName("ozy_boat_orbital_laser"):SetLevel(2)
		end
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

modifier_ozy_boat_passive = class({})

function modifier_ozy_boat_passive:IsDebuff() return true end
function modifier_ozy_boat_passive:IsHidden() return true end
function modifier_ozy_boat_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT }
end
function modifier_ozy_boat_passive:GetModifierConstantManaRegen()
	return math.max( 0,  self:GetAbility():GetSpecialValueFor("mana_regen_min") + (self:GetAbility():GetSpecialValueFor("mana_regen_distance") - (self:GetParent():GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D())/self:GetAbility():GetSpecialValueFor("mana_regen_distance") * ( self:GetAbility():GetSpecialValueFor("mana_regen_max") - self:GetAbility():GetSpecialValueFor("mana_regen_min") ))
end

function modifier_ozy_boat_passive:OnCreated()
		if IsServer() then
			local particlefx = ParticleManager:CreateParticle("particles/ozy/boat/boat_marker.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
			ParticleManager:SetParticleControl(particlefx, 0, self:GetParent():GetAbsOrigin())
			ParticleManager:SetParticleShouldCheckFoW(particlefx, false)
			self:AddParticle(particlefx, true, false, -1, false, false)
		end
		self:StartIntervalThink(0.1)
	
	
end
if IsServer() then
	function modifier_ozy_boat_passive:OnIntervalThink()
		self:GetParent():RemoveModifierByName("modifier_ozy_no_healthbar")
		local targets = FindUnitsInRadius(self:GetCaster():GetTeam(), self:GetParent():GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			self:GetParent():AddNewModifier(v, self:GetAbility(), "modifier_vision_provider", {duration = 0.3})
		end
		self:GetParent():AddNewModifier(self:GetParent().ozy, self:GetAbility(), "modifier_ozy_no_healthbar", {duration = 120})
	end

end
