LinkLuaModifier("modifier_altera_adaptive", "abilities/altera/altera_adaptive", LUA_MODIFIER_MOTION_NONE)

altera_adaptive = class({})

function altera_adaptive:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=1.5, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.0})
    return true
end

function altera_adaptive:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function altera_adaptive:DeployToPosition(position, isOutOfTimeEffect)
	local caster = self:GetCaster()
	if self.isDashPerformed then return end
	if caster and caster:IsAlive() then
		local delay = 0.3
		local damage = self:GetSpecialValueFor("damage")
		local damage2 = 0
		local mult = self:GetSpecialValueFor("damage_mult")
		local radius = self:GetSpecialValueFor("radius")
		local time = 0.3
		self.isDashPerformed = true

		StartAnimation(caster, {duration=0.5 , activity=ACT_DOTA_CAST_ABILITY_ROT, rate=1})
		local curPos = caster:GetAbsOrigin()
		local ascendCount = 0
		local groundPOs = GetGroundPosition(caster:GetAbsOrigin(), caster)
			Timers:CreateTimer('altera_descend', {
				endTime = 0,
				callback = function()
				if ascendCount >= (time+0.1)/0.033 then 	
						local point = GetGroundPosition(position, caster)
						FindClearSpaceForUnit(caster, point, true)  
					return 
				end
				caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z- 50) +  Vector(-(curPos.x - position.x)/9,-(curPos.y - position.y)/9, 0))
				ascendCount = ascendCount + 1;
				return 0.033
			end
			})
		
		Timers:CreateTimer(time, function()
			if caster and caster:IsAlive() then
				if caster:HasModifier("modifier_altera_form_str") then
					damage2 = damage + mult*caster:GetStrength()
					particlename2 = "particles/altera/altera_adaptive_red.vpcf"
				end
				if caster:HasModifier("modifier_altera_form_agi") then
					damage2 = damage + mult*caster:GetAgility()
					particlename2 = "particles/altera/altera_adaptive_green.vpcf"
				end
				if caster:HasModifier("modifier_altera_form_int") then
					damage2 = damage + mult*caster:GetIntellect()
					particlename2 = "particles/altera/altera_adaptive_blue.vpcf"
				end
			end

			caster:FindAbilityByName("altera_form_close"):OnSpellCalled(true)

			local point = GetGroundPosition(position, caster)
			EmitSoundOnLocationWithCaster(point, "Hero_Leshrac.Split_Earth", caster)

			local hit_fx2 = ParticleManager:CreateParticle(particlename2, PATTACH_ABSORIGIN, caster )
			ParticleManager:SetParticleControl( hit_fx2, 0, point)
			ParticleManager:SetParticleControl( hit_fx2, 1, Vector(radius, radius/3, 25))

			local enemies2 = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for _, enemy in pairs(enemies2) do
				if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
					DoDamage(caster, enemy, damage2, DAMAGE_TYPE_MAGICAL, 0, self, false)
					if caster:HasModifier("modifier_altera_form_str") then
						enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("str_stun_duration")})
					end
					if caster:HasModifier("modifier_altera_form_agi") then
						DoDamage(caster, enemy,self:GetSpecialValueFor("agi_damage")/100 * enemy:GetMaxHealth() , DAMAGE_TYPE_PURE, 0, self, false)
					end
				end
			end

			if caster:HasModifier("modifier_altera_form_int") then
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for _, ally in pairs(allies) do
				if ally and not ally:IsNull() and IsValidEntity(ally) then
					ally:Heal(self:GetSpecialValueFor("int_heal") + mult*caster:GetIntellect(), caster)
				end
			end
			end
			if caster:HasModifier("modifier_altera_adaptive") then
				caster:RemoveModifierByName("modifier_altera_adaptive")
			end
		end)
	end
end

function altera_adaptive:OnSpellStart()
	local caster = self:GetCaster()
	local delay = self:GetSpecialValueFor("duration")
	self.isDashPerformed = false
	local damage = self:GetSpecialValueFor("damage")
	local damage1 = 0
	local damage2 = 0
	local mult = self:GetSpecialValueFor("damage_mult")
	local radius = self:GetSpecialValueFor("radius")
	local form = "neutral"
	local ascendCount = 0
	Timers:CreateTimer('altera_ascend', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 9 then 	  
	
		   	return 
		end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+50) )
		ascendCount = ascendCount + 1;
		return 0.033
	end
	})

	caster:AddNewModifier(caster, self, "modifier_altera_adaptive", {duration = delay})
	caster:FindAbilityByName("altera_form_open"):OpenSezame()
	caster:FindAbilityByName("altera_form_close"):StartCooldown(caster:FindAbilityByName("altera_form_open"):GetCooldown(0))

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

	local particlename1 = "particles/altera/altera_adaptive.vpcf"
	local particlename2 = "particles/altera/altera_adaptive.vpcf"

	if caster:HasModifier("modifier_altera_form_str") then
        damage1 = damage + mult*caster:GetStrength()
        particlename1 = "particles/altera/altera_adaptive_red.vpcf"
    end
    if caster:HasModifier("modifier_altera_form_agi") then
        damage1 = damage + mult*caster:GetAgility()
        particlename1 = "particles/altera/altera_adaptive_green.vpcf"
    end
    if caster:HasModifier("modifier_altera_form_int") then
        damage1 = damage + mult*caster:GetIntellect()
        particlename1 = "particles/altera/altera_adaptive_blue.vpcf"
    end

    local hit_fx = ParticleManager:CreateParticle(particlename1, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( hit_fx, 0, GetGroundPosition(caster:GetAbsOrigin(), caster))
	ParticleManager:SetParticleControl( hit_fx, 1, Vector(radius - 50, (radius-50)/3, 25))

	for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
			DoDamage(caster, enemy, damage1, DAMAGE_TYPE_MAGICAL, 0, self, false)
        end
    end

	
end

modifier_altera_adaptive = class({})

function modifier_altera_adaptive:IsHidden() return true end
function modifier_altera_adaptive:OnIntervalThink()

	if self:GetRemainingTime() <= 0.3 then
		if not self:GetAbility().isDashPerformed then
			self:GetAbility():DeployToPosition(self:GetParent():GetAbsOrigin(), true)
			self:GetAbility().isDashPerformed = true
		end
	end
end

function modifier_altera_adaptive:OnCreated()
	self:StartIntervalThink(0.033)

end


function modifier_altera_adaptive:CheckState()
	return { [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 [MODIFIER_STATE_UNSELECTABLE] = true,
			 [MODIFIER_STATE_INVULNERABLE] = true,
			 [MODIFIER_STATE_STUNNED] = true}
end