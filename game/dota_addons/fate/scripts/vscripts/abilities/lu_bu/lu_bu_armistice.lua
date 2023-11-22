-----------------------------
--    Armistice    --
-----------------------------

LinkLuaModifier( "modifier_lu_bu_armistice", "abilities/lu_bu/modifiers/modifier_lu_bu_armistice", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_armistice_stun", "abilities/lu_bu/modifiers/modifier_lu_bu_armistice_stun", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_armistice_movement", "abilities/lu_bu/modifiers/modifier_lu_bu_armistice_movement", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_armistice_leap", "abilities/lu_bu/modifiers/modifier_lu_bu_armistice_leap", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier( "modifier_assault_skillswap_1", "abilities/lu_bu/modifiers/modifier_assault_skillswap_1", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_relentless_assault_blocker", "abilities/lu_bu/modifiers/modifier_relentless_assault_blocker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_halberd_throw_self_stun", "abilities/lu_bu/modifiers/modifier_lu_bu_halberd_throw_self_stun", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_relentless_assault", "abilities/lu_bu/modifiers/modifier_lu_bu_relentless_assault", LUA_MODIFIER_MOTION_NONE )

lu_bu_armistice = class({})

function lu_bu_armistice:GetIntrinsicModifierName()
	return
end

function lu_bu_armistice:CastFilterResultLocation(vLocation)
	if IsServer() then
		if GridNav:IsBlocked(vLocation) or not GridNav:IsTraversable(vLocation) then
			return UF_FAIL_INVALID_LOCATION
		end
	end

	return UF_SUCCESS
end

function lu_bu_armistice:GetCastRange(vLocation, hTarget)
	local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_lu_bu_fangtian_huaji_attribute") then
		return self:GetSpecialValueFor("distance") + 200
	end

	return self:GetSpecialValueFor("distance")
end

-- Ability Start
function lu_bu_armistice:OnSpellStart()

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local radius = self:GetSpecialValueFor("radius")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	
	if caster:HasModifier("modifier_lu_bu_fangtian_huaji_attribute") then
		damage = damage + 100 + (caster:GetStrength()*1)
	end
	
	caster:EmitSound("lu_bu_generic_1")
	
	Timers:CreateTimer(1.00, function()
		if caster:IsAlive() then
		
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
			for k,armistice_target in pairs(targets) do
				if armistice_target:IsMagicImmune() then
					return
				end
			
				DoDamage(caster, armistice_target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				armistice_target:AddNewModifier(caster, self, "modifier_lu_bu_armistice_stun", { Duration = stun_duration })
			end
			ScreenShake(caster:GetOrigin(), 5, 0.5, 2, 20000, 0, true)
				-- Create Particle
			local blastFx = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_armistice_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl( blastFx, 0, caster:GetAbsOrigin())
			
			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( blastFx, false )
				ParticleManager:ReleaseParticleIndex( blastFx )
			end)
			
			caster:EmitSound("lu_bu_armistice_impact")
		end
	end)


	if self:GetCaster() ~= self:GetCursorTarget() then
		-- Doesn't seem to work?
		self:GetCaster():FaceTowards(self:GetCursorPosition())
	
		-- local modifier_movement_handler = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_lu_bu_armistice_movement", {})
		local modifier_movement_handler = self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_lu_bu_armistice_leap",
			{
				duration	= 1,
				x			= self:GetCursorPosition().x,
				y			= self:GetCursorPosition().y,
				z			= self:GetCursorPosition().z,
			})

		if modifier_movement_handler then
			modifier_movement_handler.target_point = self:GetCursorPosition()
		end
	else
		EmitSoundOn("Hero_EarthShaker.Totem", self:GetCaster())
	
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_lu_bu_armistice", {duration = self:GetDuration()})

	end
	
	local relentless_assault = caster:FindModifierByNameAndCaster( "modifier_lu_bu_relentless_assault", caster )
	local assault_stack = caster:GetModifierStackCount("modifier_lu_bu_relentless_assault", caster)
	
	if caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack < 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
		relentless_assault:SetStackCount(assault_stack + 1)
	elseif caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack >= 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
		caster:AddNewModifier(caster, self, "modifier_assault_skillswap_1", {})
		caster:AddNewModifier(caster, self, "modifier_relentless_assault_blocker", {})
	end
end

function  lu_bu_armistice:GetIntrinsicModifierName()
	return "modifier_lu_bu_relentless_assault"
end

function lu_bu_armistice:OnUpgrade()
    local relentless_assault = self:GetCaster():FindAbilityByName("lu_bu_relentless_assault_one")
    relentless_assault:SetLevel(self:GetLevel())
end