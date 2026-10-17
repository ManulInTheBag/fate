gilgamesh_enuma_elish = class({})
gilgamesh_enuma_elish_activate = class({})

 

if not IsServer() then
  return
end
Wrappers.ChargedBeam(gilgamesh_enuma_elish,gilgamesh_enuma_elish_activate)
function gilgamesh_enuma_elish_activate:OnSpellStart()
	local caster = self:GetCaster()
  EndAnimation(caster)
  StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_END, rate=1.0})
end


--[[------------this function is not needed, merely for testing and adjusting numbers
function gilgamesh_enuma_elish:GetTestPrints()
  print("channeling:  "..self.channel_charge.."  channeltime: "..GameRules:GetGameTime()-self:GetChannelStartTime())
  local damage_total = self:GetBeamDamage()
  local bonus_base_total, bonus_per_charge = self:__Formula("damage_charge_start", "damage_charge_end", "damage_total")
  local damage_bonus_add = self:__Formula("add1_charge_start", "add1_charge_end", "damage_total", bonus_per_charge)
  print("DMG BONUS ADD:   ",damage_bonus_add,"    base bonus total: ", bonus_base_total, "   dmg total :   ",damage_total)
  local endradius_total = self:GetBeamEndRadius()
  local bonus_base_total_radius = self:__Formula("endradius_charge_start","endradius_charge_end","endradius_total")
  print("RADIUSEND BONUS base bonus total: ", bonus_base_total_radius, "   radius total :   ",endradius_total)
end
--]]

function gilgamesh_enuma_elish:VFX1_Red_Aura(caster)
  self.PI1 = ParticleManager:CreateParticle("particles/custom/gilgamesh/gilgamesh_enuma_elish_charge_wave.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
end

function gilgamesh_enuma_elish:VFX2_Sparkles(caster)
  self.PI2 = FxCreator("particles/custom/gilgamesh/enuma_elish/charging_sparkles.vpcf",PATTACH_ABSORIGIN_FOLLOW,caster,0,nil)
end

-- Волна вместо снаряда. Зона урона — вся линия от точки каста до фронта волны
-- (конус от radius до end_radius), цели в ней ищутся всё время полёта. Каждый
-- tick_interval все враги внутри получают долю урона, полный урон набирается за
-- damage_duration. Вышел из линии — урон прекращается. Дойдя до конца, волна
-- сразу гаснет: цели у края, задетые позже чем за damage_duration до конца, урон недобирают.
function gilgamesh_enuma_elish:ReleaseWave(caster)
  local origin = caster:GetAbsOrigin()
  local frontward = caster:GetForwardVector()
  local team = caster:GetTeamNumber()
  local targetPoint = self:GetCursorPosition()

  local speed = self:GetBeamSpeed()
  local start_radius = self:GetBeamRadius()
  local end_radius = self:GetBeamEndRadius()
  local distance = self:GetBeamRange() - end_radius -- как в LaunchBeam: дальний край волны = range
  local damage_total = self:GetBeamDamage()
  local tick = self:GetSpecialValueFor("tick_interval")
  local damage_duration = self:GetSpecialValueFor("damage_duration")
  local per_tick = damage_total * tick / damage_duration
  local travel_time = distance / speed
  local total_time = travel_time

  local dummy = CreateUnitByName("dummy_unit", origin, false, nil, nil, team)
  dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
  dummy:SetForwardVector(frontward)

  -- голова волны: wave_head (копия projectile.vpcf без кругов) + круги отдельными частицами,
  -- чтобы в конце полёта убрать круги сразу, а остальное дать дотаять
  local function HeadFx(name)
    local fx = ParticleManager:CreateParticle("particles/custom/gilgamesh/enuma_elish/"..name..".vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
    ParticleManager:SetParticleControl(fx, 2, Vector(start_radius,0,0))
    ParticleManager:SetParticleControl(fx, 3, targetPoint)
    return fx
  end
  local fxIndex = HeadFx("wave_head")
  local headCircles = { HeadFx("head_tornado"), HeadFx("head_ring"), HeadFx("head_trail_circle") }

  -- внутри ли точка линии: от точки каста до центра волны конус, впереди — круг волны
  local function IsInWave(pos, front, radius)
    local offset = pos - origin
    offset.z = 0
    local along = offset:Dot(frontward)
    if along >= 0 and along <= front then
      local width = start_radius + (end_radius - start_radius) * along / distance
      if (offset - frontward * along):Length2D() <= width then return true end
    end
    return (pos - (origin + frontward * front)):Length2D() <= radius or offset:Length2D() <= start_radius
  end

  -- след волны: вихрь волны вдоль пройденной линии, радиус = ширина зоны урона в этом месте
  local trail = {}
  local circles = {} -- оранжевые круги (воронки следа и круги головы)
  for _, fx in ipairs(headCircles) do table.insert(circles, fx) end
  local next_mark = 0
  -- свечение и вихрь тают сами, оранжевые круги убираем сразу: при мягком удалении они висят
  local function DestroyTrail()
    for _, fx in ipairs(trail) do
      ParticleManager:DestroyParticle(fx, false)
      ParticleManager:ReleaseParticleIndex(fx)
    end
    for _, fx in ipairs(circles) do
      ParticleManager:DestroyParticle(fx, true)
      ParticleManager:ReleaseParticleIndex(fx)
    end
    trail = {}
    circles = {}
  end
  local function MarkTrail(front)
    while next_mark <= front do
      local width = start_radius + (end_radius - start_radius) * next_mark / distance
      local fx = ParticleManager:CreateParticle("particles/custom/gilgamesh/enuma_elish/trail_glow.vpcf", PATTACH_WORLDORIGIN, nil)
      ParticleManager:SetParticleControl(fx, 0, GetGroundPosition(origin + frontward * next_mark, nil))
      ParticleManager:SetParticleControl(fx, 1, Vector(255,0,0))
      ParticleManager:SetParticleControl(fx, 2, Vector(width,0,0))
      table.insert(trail, fx)
      local circle = ParticleManager:CreateParticle("particles/custom/gilgamesh/enuma_elish/trail_tornado.vpcf", PATTACH_WORLDORIGIN, nil)
      ParticleManager:SetParticleControl(circle, 0, GetGroundPosition(origin + frontward * next_mark, nil))
      ParticleManager:SetParticleControl(circle, 2, Vector(width,0,0))
      table.insert(circles, circle)
      next_mark = next_mark + width * 0.75
    end
  end

  local dealt = {}
  local elapsed = 0
  local next_tick = 0

  -- визуал двигается шагом 0.03, урон — каждые tick_interval по всей пройденной линии
  Timers:CreateTimer(function()
    if not IsNotNull(dummy) then
      table.insert(trail, fxIndex) -- голова волны гаснет вместе со следом
      DestroyTrail()
      return nil
    end

    elapsed = math.min(elapsed + 0.03, total_time)
    local progress = math.min(elapsed / travel_time, 1)
    local front = distance * progress
    local radius = start_radius + (end_radius - start_radius) * progress
    dummy:SetAbsOrigin(GetGroundPosition(origin + frontward * front, dummy))
    ParticleManager:SetParticleControl(fxIndex, 2, Vector(radius,0,0))
    for _, fx in ipairs(headCircles) do
      ParticleManager:SetParticleControl(fx, 2, Vector(radius,0,0))
    end
    MarkTrail(front)

    if elapsed >= next_tick and IsNotNull(caster) and IsNotNull(self) then
      next_tick = next_tick + tick
      local search_center = origin + frontward * (front + radius) / 2
      local search_radius = (front + radius) / 2 + math.max(start_radius, radius)
      local enemies = FindUnitsInRadius(team, search_center, nil, search_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
      for _, enemy in pairs(enemies) do
        local id = enemy:entindex()
        local already = dealt[id] or 0
        local damage = math.min(per_tick, damage_total - already)
        if damage > 0.5 and enemy:IsAlive() and IsInWave(enemy:GetAbsOrigin(), front, radius) then
          if already == 0 then
            local impactFx = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_illuminate_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
            ParticleManager:ReleaseParticleIndex(impactFx)
          end
          dealt[id] = already + damage
          if enemy:GetUnitName() == "gille_gigantic_horror" then damage = damage * 1.3 end
          DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
        end
      end
    end

    if elapsed >= total_time then
      table.insert(trail, fxIndex) -- голова волны гаснет вместе со следом
      DestroyTrail()
      -- dummy держим, пока голова не дотает: без него её частицы теряют контрольную точку и застывают
      Timers:CreateTimer(2.0, function()
        if IsNotNull(dummy) then dummy:RemoveSelf() end
      end)
      return nil
    end
    return 0.03
  end)
end

function gilgamesh_enuma_elish:DestroyAllVFX()
  FxDestroyer(self.PI1, false)
  FxDestroyer(self.PI2, false)
end

function gilgamesh_enuma_elish:AfterOnSpellSt()
  local caster = self:GetCaster()
  self:VFX1_Red_Aura(caster)
  ParticleManager:SetParticleControl(self.PI1, 1, Vector(300,1,1))
  LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true  and playerHero:GetTeamNumber() == caster:GetTeamNumber() then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_gil_r"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
  --EmitSoundOnLocationForAllies(caster:GetAbsOrigin(), "gilgamesh_enuma_" .. math.random(2,5), caster)
  EmitGlobalSound("gilgamesh_enuma_" .. math.random(2,5))
  StartAnimation(self:GetCaster(), {duration=5.15, activity=ACT_DOTA_CAST_ABILITY_6, rate=1.1  })
  
 
end

function gilgamesh_enuma_elish:AfterThinkChargeIncr()
  local caster = self:GetCaster()
  --self:GetTestPrints()

  if self.channel_charge == 14 then
    caster:EmitSound("Hero_Weaver.CrimsonPique.Layer")
  elseif self.channel_charge == 15 then   
    --FreezeAnimation(self:GetCaster())
  elseif self.channel_charge == 29 then   
    self:VFX2_Sparkles(caster)
  end
  
  --red aura
  local intensity = self.channel_charge * 20 + 200
  ParticleManager:SetParticleControl(self.PI1, 1, Vector(intensity,1,1))    

  --red floor
  local intensity2 = self.channel_charge * 15 + 130
  ParticleManager:SetParticleControl(self.PI1, 3, Vector(intensity2,1,1))    

  --sparkles
  if self.channel_charge > 32 then
    local intensity = -0.6 + self.channel_charge / 100 * 6
    ParticleManager:SetParticleControl(self.PI2, 2, Vector(1, 1, intensity))
  end
end


function gilgamesh_enuma_elish:AfterChannelFin_Success()
  local caster = self:GetCaster()
  local pause = self:GetSpecialValueFor("endcast_pause")
  giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", pause)  
  caster:StopSound("Hero_Dark_Seer.Wall_of_Replica_lp")
  EmitGlobalSound("gilgamesh_enuma_elish") 

  Timers:CreateTimer(0.5,function()
    if not IsNotNull(caster) then return end
    self:ReleaseWave(caster)
  end)
  Timers:CreateTimer(0.8,function()
    self:DestroyAllVFX()
  end)
  EndAnimation(caster)
  StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_END, rate=1.0})
   
end

function gilgamesh_enuma_elish:AfterChannelFin_Fail()
  local caster = self:GetCaster()
 
  EndAnimation(caster)
  caster:StopSound("Hero_Dark_Seer.Wall_of_Replica_lp")
  self:DestroyAllVFX()
end

function gilgamesh_enuma_elish:GetBeamSpeed()
  return self:GetSpecialValueFor("speed") 
end

function gilgamesh_enuma_elish:GetBeamRange()
  local range = self:GetSpecialValueFor("range")
  local caster = self:GetCaster()
  if caster.IsEnumaImproved then 
    local attribute_ability = caster.MasterUnit2:FindAbilityByName("gilgamesh_attribute_sword_of_creation")
    local bonus = attribute_ability:GetSpecialValueFor("enuma_range")
    range = range + bonus
  end
  return range
end

function gilgamesh_enuma_elish:GetBeamRadius()
  return self:GetSpecialValueFor("radius")
end

function gilgamesh_enuma_elish:GetBeamEndRadius()
  local end_radius = self:ChargeGetTotal("end_radius","endradius_charge_start","endradius_charge_end","endradius_total")
  local caster = self:GetCaster()
  if caster.IsEnumaImproved then 
    local attribute_ability = caster.MasterUnit2:FindAbilityByName("gilgamesh_attribute_sword_of_creation")
    local bonus = attribute_ability:GetSpecialValueFor("enuma_radius")
    end_radius = end_radius + bonus
  end
  return end_radius
end

function gilgamesh_enuma_elish:GetBeamDamage()
  return self:ChargeGetTotal("damage","damage_charge_start","damage_charge_end","damage_total", "add1_charge_start", "add1_charge_end")
end

function gilgamesh_enuma_elish:GetCastAnimation()
  return nil
end

function gilgamesh_enuma_elish:GetAbilityTextureName()
  return "custom/gilgamesh_enuma_elish"
end
function gilgamesh_enuma_elish_activate:GetAbilityTextureName()
  return "custom/gilgamesh_enuma_elish"
end