-- Created by Elfansoer
--[[
Ability checklist (erase if done/checked):
- Scepter Upgrade
- Break behavior
- Linken/Reflect behavior
- Spell Immune/Invulnerable/Invisible behavior
- Illusion behavior
- Stolen behavior
]]
--------------------------------------------------------------------------------
modifier_lu_bu_halberd_throw = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_lu_bu_halberd_throw:IsHidden()
	return false
end

function modifier_lu_bu_halberd_throw:IsDebuff()
	return true
end

function modifier_lu_bu_halberd_throw:IsStunDebuff()
	return true
end

function modifier_lu_bu_halberd_throw:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_lu_bu_halberd_throw:OnCreated( kv )
	-- references
	self.ability = self:GetAbility()

	if IsServer() then
		self.projectile = kv.projectile

		-- face towards
		self:GetParent():SetForwardVector( -self:GetAbility().projectiles[kv.projectile].direction )
		self:GetParent():FaceTowards( self.ability.projectiles[self.projectile].init_pos )

		-- try apply
		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
		end
	end
end

function modifier_lu_bu_halberd_throw:OnRefresh( kv )
	
end

function modifier_lu_bu_halberd_throw:OnRemoved()
	if not IsServer() then return end
	-- Compulsory interrupt
	self:GetParent():InterruptMotionControllers( false )
end

function modifier_lu_bu_halberd_throw:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_lu_bu_halberd_throw:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}

	return funcs
end

function modifier_lu_bu_halberd_throw:GetOverrideAnimation( params )
	return ACT_DOTA_FLAIL
end
--------------------------------------------------------------------------------
-- Status Effects
function modifier_lu_bu_halberd_throw:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_lu_bu_halberd_throw:OnIntervalThink()
end

--------------------------------------------------------------------------------
-- Motion Effects
function modifier_lu_bu_halberd_throw:UpdateHorizontalMotion( me, dt )
	-- check projectile data
	if not self.ability.projectiles[self.projectile] then
		self:Destroy()
		return
	end

	-- get location
	local data = self.ability.projectiles[self.projectile]

	if not data.active then return end

	-- move parent to projectile location
	self:GetParent():SetOrigin( data.location + data.direction*60 )
end

function modifier_lu_bu_halberd_throw:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end