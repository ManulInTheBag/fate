require("abilities/barghest/barghest_shared")

barghest_f = class({})

--[[ Blood of the Beast (F)
     Пассивка: немного магического сопротивления и брони, которые РАСТУТ с
     числом врагов вокруг — `bonus_mr` + `mr_per_enemy` за каждого вражеского
     Слугу в `enemy_radius` (то же с бронёй: `bonus_armor` + `armor_per_enemy`),
     не больше `max_enemies` штук. Чем плотнее её обступили, тем она крепче.
     Плюс лечение от НАНЕСЁННОГО урона — и от атак, и от способностей. Каждый
     стак разгона (`modifier_barghest_frenzy` из R) добавляет к вампиризму
     `lifesteal_per_frenzy`: чем дольше держится ротация qrqrqr, тем больше
     она с неё лечится.
     Прокачивается не уровнями, а атрибутом (в KV MaxLevel 2, NOT_LEARNABLE).

     ⚠️ Число врагов считает сервер и кладёт в СТАКИ модификатора: стаки
     сетевые, и клиент считает те же бонусы, что и сервер, — цифры брони и МР
     в интерфейсе совпадают с реальными. Заодно стаки на иконке показывают
     игроку, сколько врагов сейчас «в счёт». Мастера (npc_dota_hero_wisp) и
     иллюзии не считаются.
]]

LinkLuaModifier("modifier_barghest_f", "abilities/barghest/barghest_f", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barghest_combo_switch", "abilities/barghest/barghest_f", LUA_MODIFIER_MOTION_NONE)
function barghest_f:GetIntrinsicModifierName()
    return "modifier_barghest_f"
end

function barghest_f:OnSpellStart()
    if type(GetComboAvailability) == "function" then 
        if GetComboAvailability(self:GetCaster()) ~= 0 then
            --print("нет статов")
        else
            self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_barghest_combo_switch", { duration = 3 })
        end
    end
end
modifier_barghest_combo_switch = modifier_barghest_combo_switch or class({})

function modifier_barghest_combo_switch:IsHidden()      return true end
function modifier_barghest_combo_switch:IsPurgable()    return false end
function modifier_barghest_combo_switch:RemoveOnDeath() return true end

if IsServer() then
	function modifier_barghest_combo_switch:OnCreated()
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(3) and caster:GetAbilityByIndex(3):GetName() == "barghest_d" then
			caster:SwapAbilities("barghest_d", "barghest_combo", false, true)
		end
	end

	function modifier_barghest_combo_switch:OnDestroy()
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(3) and caster:GetAbilityByIndex(3):GetName() == "barghest_combo" then
			caster:SwapAbilities("barghest_d", "barghest_combo", true, false)
		end
	end
end



modifier_barghest_f = class({})

function modifier_barghest_f:IsHidden()      return false end
function modifier_barghest_f:IsDebuff()      return false end
function modifier_barghest_f:IsPurgable()    return false end
function modifier_barghest_f:RemoveOnDeath() return false end

-- ⚠️ Без IsServer-гарда: сопротивление и броня обязаны считаться и на
-- клиенте, иначе игрок увидит в интерфейсе не то, что реально работает.
function modifier_barghest_f:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_barghest_f:GetModifierMagicalResistanceBonus()
    local hAbility = self:GetAbility()
    return hAbility:GetSpecialValueFor("bonus_mr")
           + hAbility:GetSpecialValueFor("mr_per_enemy") * self:GetStackCount()
end

function modifier_barghest_f:GetModifierPhysicalArmorBonus()
    local hAbility = self:GetAbility()
    return hAbility:GetSpecialValueFor("bonus_armor")
           + hAbility:GetSpecialValueFor("armor_per_enemy") * self:GetStackCount()
end

function modifier_barghest_f:OnCreated()
    if not IsServer() then return end
    self:OnIntervalThink()
    self:StartIntervalThink(0.25)
end

--[[ Пересчёт врагов вокруг. Вражеские Слуги, живые, без иллюзий и Мастеров;
     сколько нашли — столько стаков (с потолком `max_enemies`). ]]
function modifier_barghest_f:OnIntervalThink()
    if not IsServer() then return end
    local hParent  = self:GetParent()
    local hAbility = self:GetAbility()
    if not Barghest_Alive(hParent) or not Barghest_Alive(hAbility) then return end

    local nCount = 0
    if hParent:IsAlive() then
        local tEnemies = FindUnitsInRadius(hParent:GetTeamNumber(), hParent:GetAbsOrigin(), nil,
            hAbility:GetSpecialValueFor("enemy_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
        for _, hUnit in pairs(tEnemies) do
            if Barghest_Alive(hUnit) and hUnit:GetUnitName() ~= "npc_dota_hero_wisp" then
                nCount = nCount + 1
            end
        end
        nCount = math.min(nCount, hAbility:GetSpecialValueFor("max_enemies"))
    end
    if nCount ~= self:GetStackCount() then
        self:SetStackCount(nCount)
    end
end

--[[ Сколько процентов урона возвращается здоровьем сейчас. ]]
function modifier_barghest_f:GetLifestealPct()
    local hAbility = self:GetAbility()
    local nPct = hAbility:GetSpecialValueFor("lifesteal_pct")
    local hFrenzy = self:GetParent():FindModifierByName("modifier_barghest_frenzy")
    if hFrenzy then
        nPct = nPct + hAbility:GetSpecialValueFor("lifesteal_per_frenzy")
                      * hFrenzy:GetStackCount()
    end
    return nPct
end

function modifier_barghest_f:OnTakeDamage(keys)
    if not IsServer() then return end
    local hParent = self:GetParent()
    if keys.attacker ~= hParent then return end
    if keys.damage <= 0 then return end
    if keys.unit == hParent then return end     -- с урона по себе не лечимся
    if not hParent:IsAlive() then return end

    local nHeal = keys.damage * self:GetLifestealPct() * 0.01
    if nHeal <= 0 then return end

    -- ⚠️ Лечить прямо из колбэка урона нельзя: движок в этот момент идёт по
    -- модификаторам юнита, и вложенная правка здоровья роняет сервер.
    -- Следующим тиком.
    local hAbility = self:GetAbility()
    Timers:CreateTimer(0, function()
        if not Barghest_Alive(hParent) or not hParent:IsAlive() then return end
        hParent:Heal(nHeal, hAbility)
        Barghest_FxAt(BARGHEST_FX.LIFESTEAL, hParent:GetAbsOrigin(), hParent)
    end)
end
