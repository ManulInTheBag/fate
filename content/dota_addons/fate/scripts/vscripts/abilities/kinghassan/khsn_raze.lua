LinkLuaModifier("modifier_khsn_flame", "abilities/kinghassan/khsn_fire", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_flame_ch", "abilities/kinghassan/khsn_raze", LUA_MODIFIER_MOTION_NONE)

khsn_raze1 = class({})

function khsn_raze1:OnSpellStart()
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin() + caster:GetForwardVector()*self:GetSpecialValueFor("range")
	local kappa_checker = false

	local raze2 = caster:FindAbilityByName("khsn_raze2")
	local raze3 = caster:FindAbilityByName("khsn_raze3")

	local enemies2 = FindUnitsInRadius(  caster:GetTeamNumber(),
                                            point, 
                                            nil, 
                                            self:GetSpecialValueFor("radius"), 
                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                            DOTA_UNIT_TARGET_ALL, 
                                            0, 
                                            FIND_ANY_ORDER, 
                                            false)

	local projectile = CreateUnitByName("dummy_unit", point, false, caster, caster, caster:GetTeamNumber())
	projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	projectile:SetAbsOrigin(point)
	projectile:SetForwardVector(caster:GetForwardVector())

	EmitSoundOnLocationWithCaster(point, "Hero_SkeletonKing.Hellfire_BlastImpact", caster)

	local burn_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_shadowraze.vpcf", PATTACH_ABSORIGIN, projectile)
	ParticleManager:SetParticleControl(burn_fx, 0, point)

	local flame_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_flame_kappa.vpcf", PATTACH_ABSORIGIN, projectile)
	ParticleManager:SetParticleControl(flame_fx, 0, point)
	ParticleManager:SetParticleControl(flame_fx, 1, Vector(0, 0, 1000))

	for _,enemy in ipairs(enemies2) do
		if caster.FlameAcquired then 
			caster:GiveMana(50)
			if kappa_checker == false then
				kappa_checker = true
				local raze2cd = raze2:GetCooldownTimeRemaining()
				local raze3cd = raze3:GetCooldownTimeRemaining()
				raze2:EndCooldown()
				raze3:EndCooldown()
				if raze2cd - 4 > 0 then
					raze2:StartCooldown(raze2cd - 4)
				end
				if raze3cd - 4 > 0 then
					raze3:StartCooldown(raze3cd - 4)
				end
			end
		end
		local stacks = 0
		enemy:AddNewModifier(caster, self, "modifier_khsn_flame", {duration = self:GetSpecialValueFor("duration")})
		if enemy:HasModifier("modifier_khsn_flame_ch") then
			stacks = enemy:FindModifierByName("modifier_khsn_flame_ch"):GetStackCount()
		end

		enemy:AddNewModifier(caster, self, "modifier_khsn_flame_ch", {duration = self:GetSpecialValueFor("duration")})
		if enemy:FindModifierByName("modifier_khsn_flame_ch"):GetStackCount() < 3 then
			enemy:FindModifierByName("modifier_khsn_flame_ch"):SetStackCount((stacks and stacks or 0) + 1)
		end
		DoDamage(caster, enemy, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    end
end

function khsn_raze1:OnUpgrade()
	local caster = self:GetCaster()
	local raze2 = caster:FindAbilityByName("khsn_raze2")
	local raze3 = caster:FindAbilityByName("khsn_raze3")

	raze2:SetLevel(self:GetLevel())
	raze3:SetLevel(self:GetLevel())
end

khsn_raze2 = class({})

function khsn_raze2:OnSpellStart()
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin() + caster:GetForwardVector()*self:GetSpecialValueFor("range")
	local kappa_checker = false

	local raze1 = caster:FindAbilityByName("khsn_raze1")
	local raze3 = caster:FindAbilityByName("khsn_raze3")

	local enemies2 = FindUnitsInRadius(  caster:GetTeamNumber(),
                                            point, 
                                            nil, 
                                            self:GetSpecialValueFor("radius"), 
                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                            DOTA_UNIT_TARGET_ALL, 
                                            0, 
                                            FIND_ANY_ORDER, 
                                            false)

	local projectile = CreateUnitByName("dummy_unit", point, false, caster, caster, caster:GetTeamNumber())
	projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	projectile:SetAbsOrigin(point)

	EmitSoundOnLocationWithCaster(point, "Hero_SkeletonKing.Hellfire_BlastImpact", caster)

	local burn_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_shadowraze.vpcf", PATTACH_ABSORIGIN, projectile)
	ParticleManager:SetParticleControl(burn_fx, 0, point)

	local flame_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_flame_kappa.vpcf", PATTACH_ABSORIGIN, projectile)
	ParticleManager:SetParticleControl(flame_fx, 0, point)
	ParticleManager:SetParticleControl(flame_fx, 1, Vector(0, 0, 1000))

	for _,enemy in ipairs(enemies2) do
		if caster.FlameAcquired then 
			caster:GiveMana(50)
			if kappa_checker == false then
				kappa_checker = true
				local raze1cd = raze1:GetCooldownTimeRemaining()
				local raze3cd = raze3:GetCooldownTimeRemaining()
				raze1:EndCooldown()
				raze3:EndCooldown()
				if raze1cd - 4 > 0 then
					raze1:StartCooldown(raze1cd - 4)
				end
				if raze3cd - 4 > 0 then
					raze3:StartCooldown(raze3cd - 4)
				end
			end
		end
		local stacks = 0
		enemy:AddNewModifier(caster, self, "modifier_khsn_flame", {duration = self:GetSpecialValueFor("duration")})
		if enemy:HasModifier("modifier_khsn_flame_ch") then
			stacks = enemy:FindModifierByName("modifier_khsn_flame_ch"):GetStackCount()
		end

		enemy:AddNewModifier(caster, self, "modifier_khsn_flame_ch", {duration = self:GetSpecialValueFor("duration")})
		if enemy:FindModifierByName("modifier_khsn_flame_ch"):GetStackCount() < 3 then
			enemy:FindModifierByName("modifier_khsn_flame_ch"):SetStackCount((stacks and stacks or 0) + 1)
		end
		DoDamage(caster, enemy, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    end
end

khsn_raze3= class({})

function khsn_raze3:OnSpellStart()
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin() + caster:GetForwardVector()*self:GetSpecialValueFor("range")
	local kappa_checker = false

	local raze2 = caster:FindAbilityByName("khsn_raze2")
	local raze1 = caster:FindAbilityByName("khsn_raze1")

	local enemies2 = FindUnitsInRadius(  caster:GetTeamNumber(),
                                            point, 
                                            nil, 
                                            self:GetSpecialValueFor("radius"), 
                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                            DOTA_UNIT_TARGET_ALL, 
                                            0, 
                                            FIND_ANY_ORDER, 
                                            false)

	local projectile = CreateUnitByName("dummy_unit", point, false, caster, caster, caster:GetTeamNumber())
	projectile:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	projectile:SetAbsOrigin(point)

	EmitSoundOnLocationWithCaster(point, "Hero_SkeletonKing.Hellfire_BlastImpact", caster)

	local burn_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_shadowraze.vpcf", PATTACH_ABSORIGIN, projectile)
	ParticleManager:SetParticleControl(burn_fx, 0, point)

	local flame_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_flame_kappa.vpcf", PATTACH_ABSORIGIN, projectile)
	ParticleManager:SetParticleControl(flame_fx, 0, point)
	ParticleManager:SetParticleControl(flame_fx, 1, Vector(0, 0, 1000))

	for _,enemy in ipairs(enemies2) do
		if caster.FlameAcquired then 
			caster:GiveMana(50)
			if kappa_checker == false then
				kappa_checker = true
				local raze2cd = raze2:GetCooldownTimeRemaining()
				local raze1cd = raze1:GetCooldownTimeRemaining()
				raze2:EndCooldown()
				raze1:EndCooldown()
				if raze2cd - 4 > 0 then
					raze2:StartCooldown(raze2cd - 4)
				end
				if raze1cd - 4 > 0 then
					raze1:StartCooldown(raze1cd - 4)
				end
			end
		end
		local stacks = 0
		enemy:AddNewModifier(caster, self, "modifier_khsn_flame", {duration = self:GetSpecialValueFor("duration")})
		if enemy:HasModifier("modifier_khsn_flame_ch") then
			stacks = enemy:FindModifierByName("modifier_khsn_flame_ch"):GetStackCount()
		end

		enemy:AddNewModifier(caster, self, "modifier_khsn_flame_ch", {duration = self:GetSpecialValueFor("duration")})
		if enemy:FindModifierByName("modifier_khsn_flame_ch"):GetStackCount() < 3 then
			enemy:FindModifierByName("modifier_khsn_flame_ch"):SetStackCount((stacks and stacks or 0) + 1)
		end
		DoDamage(caster, enemy, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    end
end

modifier_khsn_flame_ch = class({})

function modifier_khsn_flame_ch:IsHidden() return true end

function modifier_khsn_flame_ch:OnCreated()
	Timers:CreateTimer(self:GetAbility():GetSpecialValueFor("duration") - 0.01, function()
		if self then
			self:SetStackCount(self:GetStackCount() - 1)
		end
	end)
end