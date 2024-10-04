LinkLuaModifier("modifier_jeanne_combo_window", "abilities/jeanne/jeanne_charisma", LUA_MODIFIER_MOTION_NONE)

jeanne_charisma = class({})

function jeanne_charisma:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function jeanne_charisma:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	caster:EmitSound("Jeanne_Skill_"..math.random(7,8))
	if caster:HasModifier("modifier_jeanne_crimson_saint") then
		local allies = FindUnitsInRadius(
			caster:GetTeamNumber(),	-- int, your team number
			target:GetAbsOrigin() ,	-- point, center point
			nil,	-- handle, cacheUnit. (not known)
			700,	-- float, radius. or use FIND_UNITS_EVERYWHERE
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,	-- int, team filter
			DOTA_UNIT_TARGET_HERO,	-- int, type filter
			0,	-- int, flag filter
			FIND_CLOSEST,	-- int, order filter
			false	-- bool, can grow cache
		)
		if #allies > 1 then
			if allies[2] == target then
				self:Pepega(allies[3], false)
			else
				self:Pepega(allies[2], false)
			end

		end
	end
	if caster ~= target then
		self:Pepega(caster, true)
		self:Pepega(target, true)
		local rope_fx = ParticleManager:CreateParticle("particles/jeanne/jeanne_heal_rope.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(rope_fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
		ParticleManager:SetParticleControlEnt(rope_fx, 1, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)

		ParticleManager:ReleaseParticleIndex(rope_fx)
	else
		if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		    if caster:FindAbilityByName("jeanne_crimson_saint"):IsCooldownReady() and caster:IsAlive() then	    		
		    	caster:AddNewModifier(caster, self, "modifier_jeanne_combo_window", {duration = 1})
			end
		end
		self:Pepega(caster, true)
	end
end

function jeanne_charisma:Pepega(target, bcleanse)
	local caster = self:GetCaster()

	local radius = self:GetSpecialValueFor("radius")
	local heal = self:GetSpecialValueFor("heal")
	local damage = self:GetSpecialValueFor("damage")

	target:EmitSound("Hero_Dazzle.Shadow_Wave")

	target:Heal(heal, self)
	if caster.IsRevelationAcquired and bcleanse then
		HardCleanse(target)
	end
	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do				
	    DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end

	local effect_target = ParticleManager:CreateParticle( "particles/jeanne/jeanne_purge_new.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(effect_target, 1, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	ParticleManager:SetParticleControl(effect_target, 3, Vector(radius,0,0))
	ParticleManager:ReleaseParticleIndex( effect_target )
end

----

modifier_jeanne_combo_window = class({})

if IsServer() then
	function modifier_jeanne_combo_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("jeanne_luminosite_eternelle", "jeanne_crimson_saint", false, true)
	end

	function modifier_jeanne_combo_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("jeanne_luminosite_eternelle", "jeanne_crimson_saint", true, false)
	end
end

function modifier_jeanne_combo_window:IsHidden()
	return true
end

function modifier_jeanne_combo_window:RemoveOnDeath()
	return true 
end