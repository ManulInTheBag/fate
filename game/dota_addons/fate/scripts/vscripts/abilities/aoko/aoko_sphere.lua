LinkLuaModifier("modifier_aoko_sphere_dummy", "abilities/aoko/aoko_sphere", LUA_MODIFIER_MOTION_NONE)

aoko_sphere = class({})

function aoko_sphere:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	local range = self:GetSpecialValueFor("range")
	local ori = caster:GetAbsOrigin()
	local vec = target - ori
	if vec:Length2D() > range then
		target = ori + vec:Normalized()*range
	end

	local height_att = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_beamu")).z - caster:GetAbsOrigin().z
	local part9 = caster:GetAbsOrigin() + Vector(0, 0, height_att) + caster:GetForwardVector()*100

	local particle = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, part9)
	ParticleManager:SetParticleControl(particle, 9, part9)

	local dummy = CreateUnitByName("aoko_sphere", caster:GetAbsOrigin() + caster:GetForwardVector()*100, false, nil, nil, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive_fly_pathing"):SetLevel(1)
	dummy:SetDayTimeVisionRange(500)
	dummy:SetNightTimeVisionRange(500)
	dummy:SetForwardVector(caster:GetForwardVector())
	dummy:AddNewModifier(caster, self, "modifier_aoko_sphere_dummy", {Duration  = self:GetSpecialValueFor("duration"), posx = target.x, posy = target.y, posz = target.z})
end

modifier_aoko_sphere_dummy = class({})

function modifier_aoko_sphere_dummy:OnCreated(keys)
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.target = Vector(keys.posx, keys.posy, keys.posz)

	local vec = (self.target - self.parent:GetAbsOrigin())
	vec.z = 0
	self.direction = vec:Normalized()
	self.range = vec:Length2D()

	self.count = 1

	self.fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)

	self:AddParticle(self.fx, false, false, -1, false, false)

	self.explodable = true
	self.explosions_remaining = self:GetAbility():GetSpecialValueFor("explosion_count")

	self:StartIntervalThink(FrameTime())
end

function modifier_aoko_sphere_dummy:OnIntervalThink()
	if not IsServer() then return end
	local point = self.parent:GetAbsOrigin() + 2*(30-self.count)/30*self.range/30*self.direction
	self.parent:SetAbsOrigin(GetGroundPosition(point, self.parent))

	self.count = self.count + 1
	if self.count >= 29 then
		self:StartIntervalThink(-1)
	end
end

function modifier_aoko_sphere_dummy:Explode()
	if not IsServer() then return end
	if not self.explodable then return end

	self.explodable = false
	Timers:CreateTimer(FrameTime(), function()
		if self then
			self.explodable = true
		end
	end)

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")

	local ori = self.parent:GetAbsOrigin()

	local explosion_fx = ParticleManager:CreateParticle("particles/aoko/aoko_sphere_aoe_area.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(explosion_fx, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(explosion_fx, 2, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(explosion_fx, 7, Vector(radius, 0, 0))

	ParticleManager:ReleaseParticleIndex(explosion_fx)

	self.explosions_remaining = self.explosions_remaining - 1
	if self.explosions_remaining <= 0 then
		self:Destroy()
	end

	local enemies = FindUnitsInRadius(caster:GetTeam(), ori, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

	for _, enemy in pairs(enemies) do
	    if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
	        DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	    end
	end
end

function modifier_aoko_sphere_dummy:OnDestroy()
	if not IsServer() then return end
	if self.explosions_remaining >= 1 then
		self:Explode()
	end
	self:GetParent():RemoveSelf()
end