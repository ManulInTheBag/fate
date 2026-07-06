-- Presence detection passive: pings enemies that newly enter the 2500 radius
-- (after the first minute of a round) + per-map respawn bonuses.
-- The generic CC/state modifiers live in modifiers/cc_modifiers.lua.
presence_detection_passive = class({})

local THIS = "abilities/general/presence_detection_passive"

function presence_detection_passive:GetIntrinsicModifierName()
	return "modifier_detect"
end

LinkLuaModifier("modifier_sasaki_vision", "abilities/sasaki/modifiers/modifier_sasaki_vision", LUA_MODIFIER_MOTION_NONE)

-- Eye of Serenity attribute (FA): reveal the detected enemy for a while
local function FAEyeAttribute(caster, enemy)
	enemy:AddNewModifier(caster, nil, "modifier_sasaki_vision", { Duration = 10 })
end

-- presence detection thinker (0.5s) + respawn hook
modifier_detect = class({})
LinkLuaModifier("modifier_detect", THIS, LUA_MODIFIER_MOTION_NONE)
function modifier_detect:IsHidden() return true end
function modifier_detect:IsPurgable() return false end
function modifier_detect:RemoveOnDeath() return false end
function modifier_detect:OnCreated()
	if IsServer() then self:StartIntervalThink(0.5) end
end
function modifier_detect:OnIntervalThink()
	local caster = self:GetParent()
	local hasSpecialPresenceDetection = false
	if caster:GetName() == "npc_dota_hero_juggernaut" and caster.IsEyeOfSerenityAcquired and caster.IsEyeOfSerenityActive then
		hasSpecialPresenceDetection = true
	elseif caster:GetName() == "npc_dota_hero_shadow_shaman" and caster.IsEyeForArtAcquired then
		hasSpecialPresenceDetection = true
	elseif caster:GetName() == "npc_dota_hero_beastmaster" and caster.DiscernPoorAttribute then
		hasSpecialPresenceDetection = true
	end

	if GameRules:GetGameTime() < RoundStartTime + 60 then
		if hasSpecialPresenceDetection == false then return end
	end

	local oldEnemyTable = caster.PresenceTable
	local newEnemyTable = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 2500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)

	-- Flag everyone in range as true before comparing two tables
	for i=1, #newEnemyTable do
		newEnemyTable[i].IsPresenceDetected = true
	end

	-- If enemy has not moved out of range since last presence detection, flag them as false
	if oldEnemyTable then
		for i=1,#oldEnemyTable do
			for j=1, #newEnemyTable do
				if oldEnemyTable[i] == newEnemyTable[j] then
					newEnemyTable[j].IsPresenceDetected = false
					break
				end
			end
		end
	end

	-- Do the ping for everyone with IsPresenceDetected marked as true
	for i=1, #newEnemyTable do
		local enemy = newEnemyTable[i]
		if enemy:IsRealHero() and not enemy:IsIllusion() and CanBeDetected(enemy) then
			if enemy.IsPresenceDetected == true or enemy.IsPresenceDetected == nil then
				MinimapEvent( caster:GetTeamNumber(), caster, enemy:GetAbsOrigin().x, enemy:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2 )
				SendErrorMessage(caster:GetPlayerOwnerID(), "#Presence_Detected")
				local dangerping = ParticleManager:CreateParticleForPlayer("particles/ui_mouseactions/ping_world.vpcf", PATTACH_ABSORIGIN, caster, PlayerResource:GetPlayer(caster:GetPlayerID()))

				ParticleManager:SetParticleControl(dangerping, 0, enemy:GetAbsOrigin())
				ParticleManager:SetParticleControl(dangerping, 1, enemy:GetAbsOrigin())

				if not caster.bIsAlertSoundDisabled then
					CustomGameEventManager:Send_ServerToPlayer(caster:GetPlayerOwner(), "emit_presence_sound", {sound="Misc.BorrowedTime"})
				end
				-- Process Eye of Serenity attribute
				if caster:GetName() == "npc_dota_hero_juggernaut" and caster.IsEyeOfSerenityAcquired == true and caster.IsEyeOfSerenityActive == true then
					FAEyeAttribute(caster, enemy)
				end
				-- Process Eye for Art attribute
				local hPlayer = caster:GetPlayerOwner()
				if IsValidEntity(hPlayer) and not hPlayer:IsNull() then
					if caster:GetName() == "npc_dota_hero_shadow_shaman" and caster.IsEyeForArtAcquired == true then
						local choice = math.random(1,3)
						if choice == 1 then
							Say(hPlayer, FindName(enemy:GetName()) .. ", dare to enter the demon's lair on your own?", true)
						elseif choice == 2 then
							Say(hPlayer, "This presence...none other than " .. FindName(enemy:GetName()) .. "!", true)
						elseif choice == 3 then
							Say(hPlayer, "Come forth, " .. FindName(enemy:GetName()) .. "...The fresh terror awaits you!", true)
						end
					end
				end
			end
		end
	end
	caster.PresenceTable = newEnemyTable
end
function modifier_detect:DeclareFunctions()
	return { MODIFIER_EVENT_ON_RESPAWN }
end
function modifier_detect:OnRespawn(args)
	if not IsServer() then return end
	local caster = self:GetParent()
	if args.unit ~= caster then return end
	if _G.GameMap == "fate_trio_rumble_3v3v3v3" or _G.GameMap == "fate_ffa" then
		caster:ModifyGold(2000, true, 0)
		giveUnitDataDrivenModifier(caster, caster, "spawn_invulnerable", 3.0)
	end
	FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )
end
