-- Presence detection passive + the mod-wide CC modifier container.
-- Lua port of the old datadriven presence_detection_passive: every generic
-- state modifier applied via giveUnitDataDrivenModifier lives here now.
presence_detection_passive = class({})

function presence_detection_passive:GetIntrinsicModifierName()
	return "modifier_detect"
end

local THIS = "abilities/general/presence_detection_passive"

-- factory: build a simple modifier class out of a spec table
local function DefineModifier(name, spec)
	local m = class({})
	m.IsHidden      = function(self) return spec.hidden == true end
	m.IsDebuff      = function(self) return spec.debuff == true end
	m.IsPurgable    = function(self) return false end
	if spec.texture then m.GetTexture = function(self) return spec.texture end end
	if spec.states then
		m.CheckState = function(self)
			local t = {}
			for _, st in ipairs(spec.states) do t[st] = true end
			return t
		end
	end
	if spec.effect then
		m.GetEffectName       = function(self) return spec.effect end
		m.GetEffectAttachType = function(self) return spec.attach or PATTACH_ABSORIGIN_FOLLOW end
	end
	if spec.funcs then
		local safe = {}
		for f, impl in pairs(spec.funcs) do
			if f ~= nil then safe[f] = impl end
		end
		m.DeclareFunctions = function(self)
			local fs = {}
			for f in pairs(safe) do table.insert(fs, f) end
			return fs
		end
		for f, impl in pairs(safe) do
			m[impl[1]] = function(self) return impl[2] end
		end
	end
	_G[name] = m
	LinkLuaModifier(name, THIS, LUA_MODIFIER_MOTION_NONE)
	return m
end

local STUN = MODIFIER_STATE_STUNNED

DefineModifier("pause_sealenabled",  { debuff=true, texture="custom/stunned", states={STUN} })
DefineModifier("drag_pause",         { debuff=true, texture="custom/stunned", states={STUN} })
DefineModifier("pause_sealdisabled", { debuff=true, texture="custom/revoked", states={STUN} })
DefineModifier("rb_sealdisabled",    { debuff=true, texture="custom/revoked" })

DefineModifier("silenced", { debuff=true, texture="silencer_last_word",
	states={MODIFIER_STATE_SILENCED},
	effect="particles/generic_gameplay/generic_silence.vpcf", attach=PATTACH_OVERHEAD_FOLLOW })
DefineModifier("muted",    { debuff=true, texture="silencer_last_word",
	states={MODIFIER_STATE_MUTED} })
DefineModifier("stunned",  { debuff=true, texture="custom/stunned",
	states={STUN},
	effect="particles/generic_gameplay/generic_stunned.vpcf", attach=PATTACH_OVERHEAD_FOLLOW })
DefineModifier("revoked",  { debuff=true, texture="custom/revoked",
	effect="particles/revoked_test.vpcf", attach=PATTACH_OVERHEAD_FOLLOW })
DefineModifier("locked",   { debuff=true, texture="shadow_shaman_shackles",
	effect="particles/units/heroes/hero_oracle/oracle_fortune_purge.vpcf" })
DefineModifier("rooted",   { debuff=true, texture="lone_druid_spirit_bear_entangle",
	states={MODIFIER_STATE_ROOTED},
	effect="particles/units/heroes/hero_winter_wyvern/wyvern_cold_embrace_borealis.vpcf" })
DefineModifier("disarmed", { debuff=true, texture="troll_warlord_berserkers_rage",
	states={MODIFIER_STATE_DISARMED},
	effect="particles/generic_gameplay/generic_disarm.vpcf" })
DefineModifier("dragged",  { debuff=true,
	states={MODIFIER_STATE_ROOTED, MODIFIER_STATE_SILENCED, MODIFIER_STATE_DISARMED} })
DefineModifier("can_be_executed", { debuff=true, states={MODIFIER_STATE_ROOTED} })

DefineModifier("zero_attack_damage", { debuff=true, hidden=true,
	funcs={ [MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE] = {"GetModifierBaseDamageOutgoing_Percentage", -100} } })
DefineModifier("out_of_game",  { states={MODIFIER_STATE_UNSELECTABLE, MODIFIER_STATE_OUT_OF_GAME, MODIFIER_STATE_NO_UNIT_COLLISION} })
DefineModifier("no_collision", { states={MODIFIER_STATE_NO_UNIT_COLLISION} })
DefineModifier("modifier_astolfo_disable_mstrength", { hidden=true })

DefineModifier("jump_pause", { texture="faceless_void_time_lock",
	states={MODIFIER_STATE_INVULNERABLE, MODIFIER_STATE_NO_HEALTH_BAR, STUN} })
DefineModifier("jump_pause_nosilence", { texture="faceless_void_time_lock",
	states={MODIFIER_STATE_INVULNERABLE, MODIFIER_STATE_NO_HEALTH_BAR, MODIFIER_STATE_ROOTED, MODIFIER_STATE_DISARMED} })
DefineModifier("jump_pause_noinvul", { texture="faceless_void_time_lock",
	states={MODIFIER_STATE_ROOTED, MODIFIER_STATE_DISARMED, MODIFIER_STATE_MUTED} })
DefineModifier("jump_pause_postdelay", { texture="faceless_void_time_lock", states={STUN} })
DefineModifier("jump_pause_postlock",  { texture="faceless_void_time_lock", states={MODIFIER_STATE_ROOTED} })
DefineModifier("round_pause", { debuff=true, texture="faceless_void_time_lock",
	states={MODIFIER_STATE_COMMAND_RESTRICTED, MODIFIER_STATE_SILENCED, MODIFIER_STATE_DISARMED,
	        MODIFIER_STATE_ROOTED, MODIFIER_STATE_INVULNERABLE} })

DefineModifier("spawn_invulnerable", {
	states={MODIFIER_STATE_INVULNERABLE, MODIFIER_STATE_NO_HEALTH_BAR},
	effect="particles/units/heroes/hero_omniknight/omniknight_repel_buff.vpcf",
	funcs={ [MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE] = {"GetModifierTotalPercentageManaRegen", 10},
	        [MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE]     = {"GetModifierHealthRegenPercentage", 10} } })
DefineModifier("gille_attack_speed_boost", { hidden=true,
	funcs={ [MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT] = {"GetModifierAttackSpeedBonus_Constant", 50} } })

-- ward: 3000 phys block, magic immune, no collision, custom on-damage script
modifier_ward_dmg_reduce = class({})
LinkLuaModifier("modifier_ward_dmg_reduce", THIS, LUA_MODIFIER_MOTION_NONE)
function modifier_ward_dmg_reduce:IsPurgable() return false end
function modifier_ward_dmg_reduce:CheckState()
	return { [MODIFIER_STATE_MAGIC_IMMUNE] = true,
	         [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end
function modifier_ward_dmg_reduce:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK, MODIFIER_EVENT_ON_TAKEDAMAGE }
end
function modifier_ward_dmg_reduce:GetModifierPhysical_ConstantBlock() return 3000 end
function modifier_ward_dmg_reduce:OnTakeDamage(args)
	if not IsServer() then return end
	local ward = self:GetParent()
	if args.unit ~= ward then return end
	-- any damage instance chips a fixed amount off the ward, with a short
	-- cooldown so multi-hit spells count as one hit
	if ward.dmgcooldown == true then return end
	ward.dmgcooldown = true
	local dmg = 2
	if args.attacker:GetClassname() == "npc_dota_base_additive" then
		dmg = 1
	end
	ApplyDamage({
		attacker = args.attacker,
		victim = ward,
		damage = dmg,
		damage_type = DAMAGE_TYPE_PURE,
	})
	Timers:CreateTimer(0.05, function()
		ward.dmgcooldown = false
	end)
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
