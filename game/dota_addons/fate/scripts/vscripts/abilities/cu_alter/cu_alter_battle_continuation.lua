-- Battle Continuation (attribute 4). Hidden passive that always sits on the hero: the intrinsic
-- modifier is applied by the engine at spawn (LevelAllAbility) and re-applied on respawn, so the
-- effect never depends on whether Cú Chulainn was alive when the attribute was bought.
-- The attribute itself only sets hero.CuAlterAttr4Acquired, which gates the modifier below.

cu_alter_battle_continuation = cu_alter_battle_continuation or class({})

LinkLuaModifier("modifier_cu_alter_battle_cont",    "abilities/cu_alter/cu_alter_battle_continuation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cu_alter_battle_cont_cd", "abilities/cu_alter/cu_alter_battle_continuation", LUA_MODIFIER_MOTION_NONE)
-- fear modifier is defined in cu_alter_roar.lua; Battle Continuation reuses it for its desperate roar
LinkLuaModifier("modifier_cu_alter_fear", "abilities/cu_alter/cu_alter_roar", LUA_MODIFIER_MOTION_NONE)

function cu_alter_battle_continuation:GetIntrinsicModifierName()
	return "modifier_cu_alter_battle_cont"
end

---------------------------------------------------------------------------------------------------
-- The first lethal blow (while off cooldown, and only with the attribute bought) leaves Cú Chulainn
-- alive; he is healed back up, spears burst out of him, then it goes on cooldown.
modifier_cu_alter_battle_cont = modifier_cu_alter_battle_cont or class({})

function modifier_cu_alter_battle_cont:IsHidden()      return true end
function modifier_cu_alter_battle_cont:IsDebuff()      return false end
function modifier_cu_alter_battle_cont:IsPurgable()    return false end
function modifier_cu_alter_battle_cont:IsPermanent()   return true end
function modifier_cu_alter_battle_cont:RemoveOnDeath() return false end

function modifier_cu_alter_battle_cont:DeclareFunctions()
	return { MODIFIER_PROPERTY_MIN_HEALTH }
end

function modifier_cu_alter_battle_cont:GetMinHealth()
	if not IsServer() then return end
	local parent  = self:GetParent()
	local ability = self:GetAbility()
	if not parent.CuAlterAttr4Acquired
		or not parent:IsAlive()
		or not parent:IsRealHero()
		or not ability:IsCooldownReady()
		or parent:HasModifier("modifier_cu_alter_battle_cont_cd") then
		return nil
	end

	-- a blow that would drop him to (near) death instead triggers Battle Continuation
	if parent:GetHealth() <= 2 then
		HardCleanse(parent)
		parent:EmitSound("cu_alter_sfx_roar_weak")	-- weakened roar as he refuses to die
		local reviveHp = parent:GetMaxHealth() * ability:GetSpecialValueFor("revive_heal_pct") / 100
		parent:SetHealth(math.max(parent:GetHealth(), reviveHp))

		local fx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_spears_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(fx, 0, parent:GetAbsOrigin() + Vector(0, 0, 80))
		Timers:CreateTimer(0.6, function()
			ParticleManager:DestroyParticle(fx, true)
			ParticleManager:ReleaseParticleIndex(fx)
		end)

		-- desperate roar: refusing to die, he lets out a roar that fears nearby enemies (reuses the
		-- Roar of the Hound fear modifier). A ríastrad-flavoured breather when he cheats death.
		local waveFx = ParticleManager:CreateParticle("particles/cu_alter/cu_alter_roar_wind.vpcf", PATTACH_ABSORIGIN, parent)
		Timers:CreateTimer(1.5, function()
			ParticleManager:DestroyParticle(waveFx, false)
			ParticleManager:ReleaseParticleIndex(waveFx)
		end)
		local enemies = FindUnitsInRadius(
			parent:GetTeamNumber(),
			parent:GetAbsOrigin(),
			nil,
			ability:GetSpecialValueFor("bc_fear_radius"),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false)
		for _, enemy in pairs(enemies) do
			if IsNotNull(enemy) then
				enemy:AddNewModifier(parent, ability, "modifier_cu_alter_fear", { duration = ability:GetSpecialValueFor("bc_fear_duration") })
			end
		end

		-- the ability's own cooldown is the real gate (survives death and respawn); the modifier below
		-- is only the visible timer icon for the player.
		local cd = ability:GetSpecialValueFor("cooldown")
		ability:StartCooldown(cd)
		parent:AddNewModifier(parent, ability, "modifier_cu_alter_battle_cont_cd", { duration = cd })
	end

	return 1
end

---------------------------------------------------------------------------------------------------
-- Visible cooldown icon for Battle Continuation (the passive itself is hidden, so its cooldown
-- would otherwise be invisible).
modifier_cu_alter_battle_cont_cd = modifier_cu_alter_battle_cont_cd or class({})

function modifier_cu_alter_battle_cont_cd:IsHidden()      return false end
function modifier_cu_alter_battle_cont_cd:IsDebuff()      return true end
function modifier_cu_alter_battle_cont_cd:IsPurgable()    return false end
function modifier_cu_alter_battle_cont_cd:RemoveOnDeath() return false end

function modifier_cu_alter_battle_cont_cd:GetTexture()
	return "custom/cu_alter/sa3"
end
