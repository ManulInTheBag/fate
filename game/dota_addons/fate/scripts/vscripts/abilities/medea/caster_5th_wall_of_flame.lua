-- caster_5th_wall_of_flame — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_wall_of_flame = class({})

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnFirewallStart

-- См. caster_5th_divine_words.lua: множитель был глобалом, который мог оказаться nil.
local HG_INT_MULTIPLIER = 1.5

OnFirewallStart = function(keys)
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	if caster.IsHGImproved then keys.Damage = keys.Damage + caster:GetIntellect()*HG_INT_MULTIPLIER end

	-- Flame spread particle
	local caster = keys.caster
	local angle = 0
	local increment_factor = 45
	local origin = caster:GetAbsOrigin()
	local forward = caster:GetForwardVector() * 1150
	local destination = origin + forward
	local ubwflame = 
	{
		Ability = keys.ability,
        EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
        iMoveSpeed = 500,
        vSpawnOrigin = origin,
        fDistance = 300,
        fStartRadius = 500,
        fEndRadius = 500,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_NONE,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = forward 
	}
	for i=1, 8 do
		-- Start rotating
		local theta = ( angle - i * increment_factor ) * math.pi / 180
		local px = math.cos( theta ) * ( destination.x - origin.x ) - math.sin( theta ) * ( destination.y - origin.y ) + origin.x
		local py = math.sin( theta ) * ( destination.x - origin.x ) + math.cos( theta ) * ( destination.y - origin.y ) + origin.y
		local new_forward = ( Vector( px, py, origin.z ) - origin ):Normalized()
		ubwflame.vVelocity = new_forward * 500
		local projectile = ProjectileManager:CreateLinearProjectile(ubwflame)
	end 
	

    local targets = FindUnitsInRadius(caster:GetTeam(), casterPos, nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false) 
    for k,v in pairs(targets) do
    	if v:GetName() ~= "npc_dota_ward_base" then
	    	DoDamage(caster, v, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	    	if not IsKnockbackImmune(v) then
				giveUnitDataDrivenModifier(caster, v, "drag_pause", 0.5)
				local pushback = Physics:Unit(v)
				v:PreventDI()
				v:SetPhysicsFriction(0)
				v:SetPhysicsVelocity((v:GetAbsOrigin() - casterPos):Normalized() * keys.Pushback * 2)
				v:SetNavCollisionType(PHYSICS_NAV_NOTHING)
				v:FollowNavMesh(false)

				Timers:CreateTimer(0.5, function()  
					v:PreventDI(false)
					v:SetPhysicsVelocity(Vector(0,0,0))
					v:OnPhysicsFrame(nil)
					FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
					return 
				end)
			end
		end
	end
end


function caster_5th_wall_of_flame:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnFirewallStart
	OnFirewallStart({
		caster = caster,
		ability = self,
		target = caster,
		Damage = self:GetSpecialValueFor("damage"),
		Pushback = self:GetSpecialValueFor("pushback"),
		Radius = self:GetSpecialValueFor("radius")
	})
	EmitSoundOn("Hero_EmberSpirit.FlameGuard.Cast", caster)
end
