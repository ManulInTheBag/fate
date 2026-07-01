ozy_piramid_auto_defence = class({})
modifier_ozy_piramid_passive = class({})


LinkLuaModifier("modifier_ozy_piramid_auto_defence", "abilities/ozy/ozy_piramid_auto_defence", LUA_MODIFIER_MOTION_NONE)


-- Passive
function ozy_piramid_auto_defence:GetIntrinsicModifierName()
	return "modifier_ozy_piramid_auto_defence"
end

function ozy_piramid_auto_defence:OnUpgrade()
	self:GetCaster():FindModifierByName("modifier_ozy_piramid_auto_defence"):RewriteValues()

end

function ozy_piramid_auto_defence:OnToggle()
	--Разраб конченый долбоеб почему ты не создаешь пустой onToggle без моего вмешательства

end

modifier_ozy_piramid_auto_defence = class({})

function modifier_ozy_piramid_auto_defence:RewriteValues()
	self.damage = self:GetAbility():GetSpecialValueFor("damage")
	self.max_targets = self:GetAbility():GetSpecialValueFor("max_targets")
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.hit_radius = self:GetAbility():GetSpecialValueFor("hit_radius")
	self.delay_before_damage = self:GetAbility():GetSpecialValueFor("delay_before_damage")
	self.hCaster = self:GetCaster()
end

function modifier_ozy_piramid_auto_defence:OnCreated()
	self:RewriteValues()
	self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("delay"))

end


function modifier_ozy_piramid_auto_defence:OnIntervalThink()
	if IsServer() then
		if self.hCaster:IsAlive() == false then return end
		if self.hCaster:IsChanneling() then return end
		--if self:GetAbility():GetToggleState() then return end
		local selfPosition = self.hCaster:GetAbsOrigin()
		local tEnemies = FindUnitsInRadius(self.hCaster.Ozy:GetTeam(), selfPosition, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
		local counter = 0
		for k, v in pairs(tEnemies) do
			if counter < self.max_targets then
				self:CreateBeam(v)
				counter = counter + 1
			end
		end
	
	end
end


function modifier_ozy_piramid_auto_defence:CreateBeam(target)
	
	local targetPos = target:GetAbsOrigin()
	local SphereParticle = ParticleManager:CreateParticle("particles/heroes/anime_hero_leonidas/leonidas_thermopylae_enomotia_sphere_ring.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleShouldCheckFoW(SphereParticle, false)
	ParticleManager:SetParticleControl(SphereParticle, 0, targetPos + Vector(0,0, 100))
	
	----------
	Timers:CreateTimer(self.delay_before_damage, function()
		local BeamParticle = ParticleManager:CreateParticle("particles/ozy/piramid/piramid_beam.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(BeamParticle, 0, targetPos)
		ParticleManager:SetParticleControl(BeamParticle, 1, targetPos)
		ParticleManager:SetParticleControl(BeamParticle, 5, targetPos)
		ParticleManager:SetParticleShouldCheckFoW(BeamParticle, false)
		ParticleManager:ReleaseParticleIndex(BeamParticle)
		ParticleManager:DestroyParticle(SphereParticle, true)
		ParticleManager:ReleaseParticleIndex(SphereParticle)
		target:EmitSound("Hero_Luna.LucentBeam.Target")
		local tEnemies = FindUnitsInRadius(self.hCaster:GetTeam(), targetPos, nil, self.hit_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(tEnemies) do
			DoDamage(self.hCaster.Ozy, v, self.damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
	
	end)


end