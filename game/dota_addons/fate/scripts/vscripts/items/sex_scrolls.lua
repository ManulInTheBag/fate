--unfinished ass

item_s_scroll = class({})

function item_s_scroll:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	if caster:HasModifier("jump_pause_nosilence") then
		RefundItem(caster, ability)
		return
	end

	self:SetRefCountsModifiers(true)
	caster:AddNewModifier(caster, self, "modifier_item_s_scroll_fix_cringe", {duration = 20})
    self:SpendCharge(1)

	local target_point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local delay = self:GetSpecialValueFor("delay")
	hero.ServStat:useS()

	local timer_fx = ParticleManager:CreateParticle("particles/items/s_scroll_timer.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(timer_fx, 0, target_point)
	ParticleManager:SetParticleControl(timer_fx, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(timer_fx, 2, Vector(delay, 0, 0))

	ParticleManager:ReleaseParticleIndex(timer_fx)

	EmitSoundOnLocationWithCaster(target_point, "sex_scroll_precast", caster)

	Timers:CreateTimer(delay, function()
		EmitSoundOnLocationWithCaster(target_point, "sex_scroll_impact", caster)
		local enemies = FindUnitsInRadius(caster:GetTeam(), target_point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

		for _, target in pairs(enemies) do
		    if target and not target:IsNull() and IsValidEntity(target) then
		    	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				ApplyPurge(target)

				target:AddNewModifier(caster, ability, "modifier_sex_scroll_root", {duration = 1.0})

				if not IsImmuneToSlow(target) then
					target:AddNewModifier(caster, ability, "modifier_sex_scroll_slow", {duration = 4.0})
				end
				local boltFx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_ABSORIGIN, caster)
				ParticleManager:SetParticleControl(boltFx, 0, target_point + Vector(0, 0, 2000))
				ParticleManager:SetParticleControl(boltFx, 1, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z+((target:GetBoundingMaxs().z - target:GetBoundingMins().z)/2)))
				Timers:CreateTimer(2.0, function()
					ParticleManager:DestroyParticle(boltFx, false)
				end)
		    end
		end

		local lightningBoltFx = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(lightningBoltFx,0, target_point + Vector(0, 0, 2000))
		ParticleManager:SetParticleControl(lightningBoltFx,1, target_point)

		Timers:CreateTimer(2.0, function()
			ParticleManager:DestroyParticle(lightningBoltFx, false)
		end)
	end)
end

LinkLuaModifier("modifier_item_s_scroll_fix_cringe", "items/sex_scrolls", LUA_MODIFIER_MOTION_NONE)

modifier_item_s_scroll_fix_cringe = modifier_item_s_scroll_fix_cringe or class({})

function modifier_item_s_scroll_fix_cringe:IsHidden() return true end
function modifier_item_s_scroll_fix_cringe:RemoveOnDeath() return true end
function modifier_item_s_scroll_fix_cringe:IsPurgable() return false end
function modifier_item_s_scroll_fix_cringe:IsPurgeException() return false end



item_ex_scroll = class({})

function item_ex_scroll:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	if caster:HasModifier("jump_pause_nosilence") then
		RefundItem(caster, ability)
		return
	end

	self:SetRefCountsModifiers(true)
	caster:AddNewModifier(caster, self, "modifier_item_ex_scroll_fix_cringe", {duration = 20})
    self:SpendCharge(1)

	local target_point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local delay = self:GetSpecialValueFor("delay")
	hero.ServStat:useS()

	local timer_fx = ParticleManager:CreateParticle("particles/items/ex_scroll_timer.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(timer_fx, 0, target_point)
	ParticleManager:SetParticleControl(timer_fx, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(timer_fx, 2, Vector(delay, 0, 0))

	ParticleManager:ReleaseParticleIndex(timer_fx)

	EmitSoundOnLocationWithCaster(target_point, "sex_scroll_precast", caster)

	Timers:CreateTimer(delay, function()
		EmitSoundOnLocationWithCaster(target_point, "sex_scroll_impact", caster)
		local enemies = FindUnitsInRadius(caster:GetTeam(), target_point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

		for _, target in pairs(enemies) do
		    if target and not target:IsNull() and IsValidEntity(target) then
		    	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				ApplyPurge(target)

				target:AddNewModifier(caster, ability, "modifier_sex_scroll_root", {duration = 1.0})

				if not IsImmuneToSlow(target) then
					target:AddNewModifier(caster, ability, "modifier_sex_scroll_slow", {duration = 4.0})
				end
				local boltFx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_ABSORIGIN, caster)
				ParticleManager:SetParticleControl(boltFx, 0, target_point + Vector(0, 0, 2000))
				ParticleManager:SetParticleControl(boltFx, 1, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z+((target:GetBoundingMaxs().z - target:GetBoundingMins().z)/2)))
				Timers:CreateTimer(2.0, function()
					ParticleManager:DestroyParticle(boltFx, false)
				end)
		    end
		end

		local lightningBoltFx = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(lightningBoltFx,0, target_point + Vector(0, 0, 2000))
		ParticleManager:SetParticleControl(lightningBoltFx,1, target_point)

		Timers:CreateTimer(2.0, function()
			ParticleManager:DestroyParticle(lightningBoltFx, false)
		end)
	end)
end

LinkLuaModifier("modifier_item_ex_scroll_fix_cringe", "items/sex_scrolls", LUA_MODIFIER_MOTION_NONE)

modifier_item_ex_scroll_fix_cringe = modifier_item_ex_scroll_fix_cringe or class({})

function modifier_item_ex_scroll_fix_cringe:IsHidden() return true end
function modifier_item_ex_scroll_fix_cringe:RemoveOnDeath() return true end
function modifier_item_ex_scroll_fix_cringe:IsPurgable() return false end
function modifier_item_ex_scroll_fix_cringe:IsPurgeException() return false end