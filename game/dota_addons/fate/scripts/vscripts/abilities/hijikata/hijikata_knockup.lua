hijikata_knockup = class({})

 
function hijikata_knockup:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
    local damage = self:GetSpecialValueFor("damage")
    local width = self:GetSpecialValueFor("width")
	local vector = (self:GetCursorPosition() - caster:GetAbsOrigin()):Normalized()
	local knockbackEndpoint = caster:GetAbsOrigin() - vector * 400
    local AttackedTargets = {}
	local knockbackDuration = self:GetSpecialValueFor("root_duration")
	local knockBackDistance = (knockbackEndpoint - caster:GetAbsOrigin()):Length2D() * 1.3
    local targets = FindUnitsInLine(caster:GetTeamNumber(),
									caster:GetAbsOrigin(),
									caster:GetAbsOrigin()+vector*300,
									nil,
									100,
									DOTA_UNIT_TARGET_TEAM_ENEMY,
									DOTA_UNIT_TARGET_ALL,
									0)
 

	caster:EmitSound("nero_w")
	caster:SwapAbilities("hijikata_knockup", "hijikata_ult", false, true)
	local slash_fx = ParticleManager:CreateParticle("particles/hijikata/hijikata_knockup_slash.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
	ParticleManager:SetParticleControl(slash_fx, 7, caster:GetAbsOrigin() + caster:GetForwardVector()*150)
	ParticleManager:SetParticleControl(slash_fx, 8, caster:GetAbsOrigin() + caster:GetForwardVector()*150 + Vector(0, 0, 500))
	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(slash_fx, false)
		ParticleManager:ReleaseParticleIndex(slash_fx)
	end)
	-- local slash_fx = ParticleManager:CreateParticle("particles/nero/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	-- ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin() + Vector(0, 0, 80))
	-- ParticleManager:SetParticleControl(slash_fx, 5, Vector(400, 1, 1))
	-- ParticleManager:SetParticleControl(slash_fx, 10, Vector(45, 0, 0))

	Timers:CreateTimer(0.4, function()
		ParticleManager:DestroyParticle(slash_fx, false)
		ParticleManager:ReleaseParticleIndex(slash_fx)
	end)

 
	for _, enemy in pairs(targets) do
		if enemy and not enemy:IsNull() and IsValidEntity(enemy) then

			AttackedTargets[enemy:entindex()] = true

			if not enemy:IsMagicImmune() then
				DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			end
			
			Timers:CreateTimer(knockbackDuration, function()
				enemy:SetAbsOrigin(GetGroundPosition(enemy:GetAbsOrigin(),enemy))
			end)
		end
	end
   

end

 