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
	if args.unit ~= self:GetParent() then return end
	WardOnTakeDamage({ unit = args.unit, attacker = args.attacker })
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
	OnPresenceDetectionThink({ caster = self:GetParent() })
end
function modifier_detect:DeclareFunctions()
	return { MODIFIER_EVENT_ON_RESPAWN }
end
function modifier_detect:OnRespawn(args)
	if not IsServer() then return end
	if args.unit ~= self:GetParent() then return end
	OnHeroRespawn({ caster = self:GetParent(), ability = self:GetAbility() })
end
