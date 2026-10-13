-- Модификатор скина вынесен из hero_replacer.lua: тот файл падает в клиентской VM
-- (HeroSelection = nil), и клиент не знал этот модификатор вовсе ("unknown modifier type").
-- Без него клиентские эффекты (GetEffectName / GetStatusEffectName) не видели скин.
modifier_hero_selection_skin = modifier_hero_selection_skin or class({})

function modifier_hero_selection_skin:IsHidden()                                                                       return true end
function modifier_hero_selection_skin:IsDebuff()                                                                       return false end
function modifier_hero_selection_skin:IsPurgable()                                                                     return false end
function modifier_hero_selection_skin:IsPurgeException()                                                               return false end
function modifier_hero_selection_skin:RemoveOnDeath()                                                                  return false end
function modifier_hero_selection_skin:IsDimensionException()                                                           return true end
function modifier_hero_selection_skin:AllowIllusionDuplicate()                                                         return true end
function modifier_hero_selection_skin:GetPriority()                                                                    return MODIFIER_PRIORITY_LOW end
function modifier_hero_selection_skin:DeclareFunctions()
    -- на клиенте модель не меняем (sModelName там nil): модификатор нужен клиенту
    -- только ради номера скина в стаках (SkinParticle / GetSkinNumber)
    if not IsServer() then return {} end
    local tFunc =   {
                        MODIFIER_PROPERTY_MODEL_CHANGE
                    }
    return tFunc
end
function modifier_hero_selection_skin:GetModifierModelChange(keys)
    return self.sModelName
end
function modifier_hero_selection_skin:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    self.skinNumber = hTable.skinNumber
    if IsServer() then
    	-- Номер скина дублируем в стаки: они сетевые, а таблица OnCreated на
    	-- клиент не приходит (там skinNumber = nil). Модификатор скрытый —
    	-- стаков в UI не видно. Нужно клиентским эффектам скинов (Barghest/Guts).
    	self:SetStackCount(self.skinNumber or 0)
    	-- клиенту номер скина отдаём ещё и сетевой таблицей: клиентская VM
    	-- не всегда знает этот модификатор ("unknown modifier type"), тогда и стаков не видно
    	CustomNetTables:SetTableValue("sync", "hero_skin_" .. self.hParent:entindex(), { skin = self.skinNumber or 0 })
    	local tableData = PlayerTables:GetTableValue("hero_selection_heroes_data", self.hCaster:GetUnitName())
    	local skinData = tableData.skins["skin_"..self.skinNumber]
    	
    	if skinData then
        	self.sModelName = tableData.skins["skin_"..self.skinNumber].model--"models/zlodemon/salter_skin/sbr_alter.vmdl"
        else
        	self.sModelName = tableData.skins["skin_0"].model
        end
    end
end
function modifier_hero_selection_skin:OnRefresh(hTable)
    self:OnCreated(hTable)
end
