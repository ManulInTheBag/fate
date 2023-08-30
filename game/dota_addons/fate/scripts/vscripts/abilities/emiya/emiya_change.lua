emiya_change = emiya_change or class({})

function emiya_change:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self

	if caster:FindAbilityByName("emiya_double_slash"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("emiya_double_slash"):SetLevel(self:GetLevel())
    end
 
 
end


function emiya_change:OnSpellStart()
	local vPoint = self:GetCursorPosition()
	self.arrowsPoint = vPoint 
	self.hCaster = self:GetCaster()
	self.vCasterPos = self.hCaster:GetAbsOrigin()
	self.vCastDirection =    vPoint - self.vCasterPos
	self.vCastDirection.z = 0
	self.hCaster:SetForwardVector(self.vCastDirection)
	local distance = self.vCastDirection:Length2D()
	if(distance > self:GetSpecialValueFor("distance")) then
		self.arrowsPoint = self.vCastDirection:Normalized() *  self:GetSpecialValueFor("distance") + self.vCasterPos
	end
	vPoint = self.vCastDirection:Normalized() * 20000 + self.vCasterPos
	StartAnimation(self.hCaster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})
	giveUnitDataDrivenModifier(self.hCaster, self.hCaster, "pause_sealenabled", 0.3)
	Timers:CreateTimer(0.257,function()
		self:ShootArrow(self.vCasterPos + self.hCaster:GetForwardVector() * - 50, vPoint, 3500)
		self.hCaster:EmitSound("Ability.Powershot.Alt")
	end)
	Timers:CreateTimer(0.6,function()
		if self:GetAutoCastState()  == true then
			self:DoSwap()
		end
	end)
	

end

function emiya_change:DoSwap()
	local swapAbil = self.hCaster:FindAbilityByName("emiya_weapon_swap")
	swapAbil:SwapWeapons(1)
	--self.hCaster:CastAbilityImmediately(swapAbil, self.hCaster:GetPlayerOwner():GetPlayerID())--- idk why do it like that, just for test
	self.hCaster:SetBodygroup(0,0)
end

function emiya_change:ShootArrow(vSpawnLoc, vPoint, nSpeed)
	pull_center = self.hCaster:GetForwardVector() * -300 +self.vCasterPos
	local endPos = self.hCaster:GetForwardVector()*700 + self.vCasterPos
	    self.knockback = { should_stun = false,
                                    knockback_duration = 0.2,
                                    duration = 0.2,
                                    knockback_distance = -300,
                                    knockback_height =  0,
                                    center_x = pull_center.x,
                                    center_y = pull_center.y,
                                    center_z = pull_center.z }
    self.hCaster:AddNewModifier( self.hCaster, self, "modifier_knockback", self.knockback) 
	local damage = self:GetSpecialValueFor("damage")
	CreateModifierThinker(self.hCaster, self, "modifier_archer_change_rain", {vx = self.vCastDirection.x,vy = self.vCastDirection.y,vz = self.vCastDirection.z,
																		damage = damage, initxend = self.arrowsPoint.x, inityend = self.arrowsPoint.y,
																		initzend = self.arrowsPoint.z, duration = self:GetSpecialValueFor("duration"),
																		radius = self:GetSpecialValueFor("radius")}, self.arrowsPoint, self.hCaster:GetTeamNumber(), false)
end
 
LinkLuaModifier("modifier_archer_change_rain", "abilities/emiya/emiya_change", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_archer_change_rain_slow", "abilities/emiya/emiya_change", LUA_MODIFIER_MOTION_NONE)


modifier_archer_change_rain = modifier_archer_change_rain or class({})

function modifier_archer_change_rain:IsHidden() return false end
function modifier_archer_change_rain:IsDebuff() return false end
function modifier_archer_change_rain:IsPurgable() return false end
function modifier_archer_change_rain:IsPurgeException() return false end
function modifier_archer_change_rain:RemoveOnDeath() return true end
function modifier_archer_change_rain:CheckState()
    local state = { [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_PROVIDES_VISION] = true, }
    return state
end
function modifier_archer_change_rain:OnCreated(hTable)
	if not IsServer() then return end
	self.hCaster = self:GetCaster()
	self.ability = self:GetAbility()
	self.radius = hTable.radius
	self.point =  Vector(hTable.initxend,hTable.inityend,hTable.initzend ) 
	self.damage = hTable.damage
	self.vCastDirection = Vector(hTable.vx,hTable.vy,hTable.vz):Normalized()
	self.point_particle = ParticleManager:CreateParticle("particles/emiya/emiya_arrow_rain.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(self.point_particle, 0,  Vector(self.vCastDirection.x*2500,self.vCastDirection.y*2500,-7500)) --speed
	ParticleManager:SetParticleControl(self.point_particle, 1, self.point) --point
	ParticleManager:SetParticleControl(self.point_particle, 3,  Vector(-self.vCastDirection.x*500,-self.vCastDirection.y * 500,1000) ) --offset
	ParticleManager:SetParticleControl(self.point_particle, 4,  Vector(-self.vCastDirection.x*500,-self.vCastDirection.y * 500,1500)) --offset
	ParticleManager:SetParticleControl(self.point_particle, 6,  Vector(-self.vCastDirection.x*40,-self.vCastDirection.y * 40,0)) --offset ground
	self:GetParent():SetDayTimeVisionRange(400)
	self:GetParent():SetNightTimeVisionRange(400)
    self:StartIntervalThink(0.1)
end
function modifier_archer_change_rain:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_archer_change_rain:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.point_particle,false)
	ParticleManager:ReleaseParticleIndex(self.point_particle)
end
function modifier_archer_change_rain:OnIntervalThink()
	if not  IsServer() then return end
    		local enemies = FindUnitsInRadius(  self.hCaster:GetTeamNumber(),
						self.point+Vector(-self.vCastDirection.x*40,-self.vCastDirection.y * 40,0),
                        nil,
                        self.radius,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_ALL,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)
		for _,enemy in pairs(enemies) do
			DoDamage(self.hCaster, enemy, self.damage/10, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
			enemy:AddNewModifier(self.hCaster, self.ability,"modifier_archer_change_rain_slow", {duration = 0.25})
       	end
end
 

 
modifier_archer_change_rain_slow = class({})

function modifier_archer_change_rain_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_archer_change_rain_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_archer_change_rain_slow:IsHidden()
	return true 
end
