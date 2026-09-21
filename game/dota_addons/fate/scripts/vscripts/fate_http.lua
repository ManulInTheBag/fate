-- ============================================================================
-- fate_http.lua — HTTP-запросы игрового сервера с обходом блокировки локальных
-- лобби (сентябрь 2026).
--
-- С патча ~18.09.2026 CreateHTTPRequestScriptVM в ОБЫЧНОМ (не tools) локальном
-- лобби возвращает nil — внешние запросы кастомок Valve отрезали
-- (Dota2-Gameplay #35497). В tools-режиме и на дедиках объект по-прежнему есть.
--
-- Обход — «реле через клиента»: сервер строит URL и просит ОДНОГО живого игрока
-- открыть его в скрытом DOTAHTMLPanel (это CEF-браузер, ему интернет не
-- закрывали). Воркер на такой запрос отвечает HTML-страницей, у которой в
-- <title> лежит «rid|status|body»; клиент ловит событие HTMLTitle и шлёт ответ
-- обратно событием. Панорамная половина — fate_http_relay.js (подключён в
-- custom_ui_manifest.xml, грузится раньше экрана выбора команд).
--
-- Интерфейс повторяет нативный объект, чтобы вызывающий код не менялся:
--   local req = FateCreateHTTPRequest("POST", FATE_BINDS_HOST .. "/binds")
--   req:SetHTTPRequestHeaderValue("X-Fate-Key", key)
--   req:SetHTTPRequestGetOrPostParameter("steamid", id)
--   req:Send(function(res) ... res.StatusCode, res.Body ... end)
-- Если нативный запрос доступен — используется он (tools/дедик), реле — только
-- когда движок вернул nil. Ошибка реле приходит как StatusCode = 0.
--
-- Ограничения реле (см. воркер, /relay):
--   * всё уезжает в GET: URL не длиннее FATE_HTTP_MAX_URL (Cloudflare режет 16 КБ);
--   * ответ едет в <title>: ~4000 символов, длиннее воркер отдаёт 570;
--   * ключ API уезжает в query — он и так лежит в VPK, уровень защиты тот же;
--   * ответ принимается ТОЛЬКО от игрока, которому раздали запрос.
-- ⚠️ Таймаут через Timers: в POST_GAME таймеры не тикают, там запрос без
-- ответа просто останется висеть в pending — это безвредно.
-- ============================================================================

FateHttp = FateHttp or {}
FateHttp.seq = FateHttp.seq or 0
FateHttp.ready = FateHttp.ready or {}       -- playerID -> true (клиент с реле)
FateHttp.pending = FateHttp.pending or {}   -- rid -> запрос в полёте
FateHttp.queue = FateHttp.queue or {}       -- запросы, ждущие живого клиента
FateHttp.stats = FateHttp.stats or { native = 0, relay = 0, ok = 0, fail = 0 }

FATE_HTTP_TIMEOUT = 12       -- секунд на круг «клиент → воркер → клиент → сервер»
FATE_HTTP_MAX_URL = 14000    -- символов; выше — сразу отказ, до сети не доходит

local function urlencode(s)
    s = tostring(s)
    return (string.gsub(s, "[^%w%-%_%.%~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function log(msg)
    print("[FateHttp] " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- Объект запроса-реле (совместим по методам с нативным)
-- ---------------------------------------------------------------------------
FateHttpRelayRequest = FateHttpRelayRequest or {}
FateHttpRelayRequest.__index = FateHttpRelayRequest

function FateHttpRelayRequest.New(method, url)
    local self = setmetatable({}, FateHttpRelayRequest)
    self.method = string.upper(tostring(method or "GET"))
    self.origin, self.path, self.query = FateHttp.SplitUrl(url)
    self.params = {}
    self.key = ""
    self.rid = nil
    self.callback = nil
    self.relayPlayer = nil
    self.timer = nil
    return self
end

function FateHttpRelayRequest:SetHTTPRequestHeaderValue(name, value)
    -- Из заголовков воркеру нужен только ключ; остальные некуда положить.
    if string.lower(tostring(name)) == "x-fate-key" then
        self.key = tostring(value or "")
    end
end

function FateHttpRelayRequest:SetHTTPRequestGetOrPostParameter(name, value)
    self.params[#self.params + 1] = { tostring(name), tostring(value) }
end

-- Заглушки: у реле собственный таймаут, а сырое тело завернуть в GET нельзя.
function FateHttpRelayRequest:SetHTTPRequestAbsoluteTimeoutMS(_) end
function FateHttpRelayRequest:SetHTTPRequestNetworkActivityTimeout(_) end
function FateHttpRelayRequest:SetHTTPRequestRawPostBody(_, _)
    log("SetHTTPRequestRawPostBody не поддерживается реле — тело потеряно")
end

function FateHttpRelayRequest:BuildUrl()
    local parts = {
        "rid=" .. urlencode(self.rid),
        "key=" .. urlencode(self.key),
        "m=" .. urlencode(self.method),
        "p=" .. urlencode(self.path),
        "_=" .. tostring(RandomInt(1, 999999999)),   -- антикэш CEF
    }
    for _, kv in ipairs(self.params) do
        parts[#parts + 1] = urlencode(kv[1]) .. "=" .. urlencode(kv[2])
    end
    local url = self.origin .. "/relay?" .. table.concat(parts, "&")
    if self.query ~= "" then
        url = url .. "&" .. self.query   -- уже закодирован вызывающим кодом
    end
    return url
end

function FateHttpRelayRequest:Send(callback)
    self.callback = callback
    FateHttp.seq = FateHttp.seq + 1
    self.rid = "r" .. tostring(FateHttp.seq) .. "_" .. tostring(RandomInt(100000, 999999))
    self.url = self:BuildUrl()
    FateHttp.stats.relay = FateHttp.stats.relay + 1
    if #self.url > FATE_HTTP_MAX_URL then
        log(self.rid .. " " .. self.path .. ": URL слишком длинный (" .. #self.url .. ")")
        FateHttp.Deliver(self, 0, "url too long")
        return
    end
    FateHttp.pending[self.rid] = self
    if Timers and Timers.CreateTimer then
        local rid = self.rid
        self.timer = Timers:CreateTimer(FATE_HTTP_TIMEOUT, function()
            FateHttp:Finish(rid, 0, "timeout")
        end)
    end
    FateHttp:Submit(self)
end

-- ---------------------------------------------------------------------------
-- Диспетчер
-- ---------------------------------------------------------------------------

-- "https://host/path?a=b" -> "https://host", "/path", "a=b"
function FateHttp.SplitUrl(url)
    url = tostring(url or "")
    local origin, rest = string.match(url, "^(https?://[^/?]+)(.*)$")
    if not origin then
        return url, "/", ""
    end
    local path, query = string.match(rest, "^([^?]*)%??(.*)$")
    if path == nil or path == "" then path = "/" end
    return origin, path, query or ""
end

-- Точка входа вместо CreateHTTPRequestScriptVM.
function FateCreateHTTPRequest(method, url)
    local native = CreateHTTPRequestScriptVM(method, url)
    if native ~= nil then
        FateHttp.stats.native = FateHttp.stats.native + 1
        return native
    end
    return FateHttpRelayRequest.New(method, url)
end

function FateHttp:Init()
    if self.initialized then return end
    self.initialized = true
    CustomGameEventManager:RegisterListener("fate_http_ready", function(_, args)
        FateHttp:OnClientReady(args.PlayerID)
    end)
    CustomGameEventManager:RegisterListener("fate_http_response", function(_, args)
        FateHttp:OnResponse(args.PlayerID, args)
    end)
    CustomGameEventManager:RegisterListener("fate_http_failure", function(_, args)
        FateHttp:OnFailure(args.PlayerID, args)
    end)
    log("реле инициализировано")
end

-- Клиент шлёт ready ежесекундно, пока не получит ack. Первые события приходят
-- с PlayerID = -1 (скрипт манифеста стартует раньше раздачи слотов) — их
-- молча пропускаем, не подтверждая.
function FateHttp:OnClientReady(playerID)
    if playerID == nil or playerID < 0 then return end
    local player = PlayerResource:GetPlayer(playerID)
    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "fate_http_ack", {})
    end
    if self.ready[playerID] then return end
    self.ready[playerID] = true
    log("клиент игрока " .. tostring(playerID) .. " готов к реле")
    self:FlushQueue()
end

function FateHttp:IsOnline(playerID)
    local state = PlayerResource:GetConnectionState(playerID)
    -- На старте матча клиенты ещё в LOADING; ждать CONNECTED — держать всё в очереди.
    return state == DOTA_CONNECTION_STATE_CONNECTED or state == DOTA_CONNECTION_STATE_LOADING
end

-- Живой человек с загруженным реле, по кругу: в конце матча уходит ~15
-- запросов разом, и лучше размазать их по клиентам, чем вешать все на одного.
-- Хост не выделяем: в локальном лобби у любого клиента одинаковый доступ в сеть.
function FateHttp:SelectRelayPlayer()
    local candidates = {}
    for playerID = 0, (DOTA_MAX_TEAM_PLAYERS or 24) - 1 do
        if self.ready[playerID]
           and PlayerResource:IsValidPlayerID(playerID)
           and not PlayerResource:IsFakeClient(playerID)
           and self:IsOnline(playerID) then
            candidates[#candidates + 1] = playerID
        end
    end
    if #candidates == 0 then return nil end
    self.rr = (self.rr or 0) + 1
    return candidates[(self.rr % #candidates) + 1]
end

function FateHttp:Submit(req)
    local playerID = self:SelectRelayPlayer()
    if playerID == nil then
        log(req.rid .. " " .. req.path .. ": нет готового клиента, в очередь")
        self.queue[#self.queue + 1] = req
        return
    end
    self:Dispatch(req, playerID)
end

function FateHttp:Dispatch(req, playerID)
    local player = PlayerResource:GetPlayer(playerID)
    if not player then
        self.queue[#self.queue + 1] = req
        return
    end
    req.relayPlayer = playerID
    log(req.rid .. " " .. req.method .. " " .. req.path .. " -> клиент " .. tostring(playerID)
        .. " (" .. #req.url .. " симв.)")
    CustomGameEventManager:Send_ServerToPlayer(player, "fate_http_request", {
        rid = req.rid,
        url = req.url,
    })
end

function FateHttp:FlushQueue()
    if #self.queue == 0 then return end
    local playerID = self:SelectRelayPlayer()
    if playerID == nil then return end
    local queued = self.queue
    self.queue = {}
    for _, req in ipairs(queued) do
        if self.pending[req.rid] then
            self:Dispatch(req, playerID)
        end
    end
end

-- Ответ засчитываем только от того клиента, которому раздали запрос: чужой
-- клиент, даже угадав rid, подменить результат не сможет.
function FateHttp:IsFromRelay(playerID, rid)
    local req = self.pending[rid]
    if not req then return false end
    if req.relayPlayer ~= playerID then
        log(tostring(rid) .. ": ответ от игрока " .. tostring(playerID)
            .. ", а реле был " .. tostring(req.relayPlayer) .. " — игнор")
        return false
    end
    return true
end

function FateHttp:OnResponse(playerID, args)
    local rid = tostring(args.rid or "")
    if not self:IsFromRelay(playerID, rid) then return end
    self:Finish(rid, tonumber(args.status) or 0, tostring(args.data or ""))
end

function FateHttp:OnFailure(playerID, args)
    local rid = tostring(args.rid or "")
    if not self:IsFromRelay(playerID, rid) then return end
    self:Finish(rid, 0, tostring(args.reason or "client failure"))
end

function FateHttp:Finish(rid, status, body)
    local req = self.pending[rid]
    if not req then return end
    self.pending[rid] = nil
    for i = #self.queue, 1, -1 do
        if self.queue[i].rid == rid then table.remove(self.queue, i) end
    end
    if req.timer and Timers and Timers.RemoveTimer then
        Timers:RemoveTimer(req.timer)
    end
    FateHttp.Deliver(req, status, body)
end

function FateHttp.Deliver(req, status, body)
    if status == 200 then
        FateHttp.stats.ok = FateHttp.stats.ok + 1
    else
        FateHttp.stats.fail = FateHttp.stats.fail + 1
        log(tostring(req.rid) .. " " .. tostring(req.path) .. " -> " .. tostring(status)
            .. " " .. string.sub(tostring(body), 1, 120))
    end
    if req.callback then
        -- Ошибка в колбэке иначе нигде не видна (движок её глотает).
        local ok, err = pcall(req.callback, { StatusCode = status, Body = body })
        if not ok then
            log("ошибка в колбэке " .. tostring(req.rid) .. ": " .. tostring(err))
        end
    end
end

-- Сводка для отладки: -http в чате (см. addon_game_mode.lua).
function FateHttp:Summary()
    local readyList = {}
    for pid, _ in pairs(self.ready) do readyList[#readyList + 1] = tostring(pid) end
    table.sort(readyList)
    local pendingCount = 0
    for _ in pairs(self.pending) do pendingCount = pendingCount + 1 end
    return string.format("native=%d relay=%d ok=%d fail=%d pending=%d queue=%d ready=[%s]",
        self.stats.native, self.stats.relay, self.stats.ok, self.stats.fail,
        pendingCount, #self.queue, table.concat(readyList, ","))
end
