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
FateHttp.stats = FateHttp.stats or { native = 0, relay = 0, ok = 0, fail = 0, retry = 0 }
-- Здоровье клиентов-реле. ⚠️ Не у всех клиентов реле работает: в матчах
-- 26.09.2026 до воркера не долетало 2–3 запроса из 16 (строки игроков и
-- начисление MMR) — у кого-то CEF не достаёт до workers.dev. Раньше такой
-- запрос пропадал молча, теперь уходит повтором через другого клиента.
FateHttp.bad = FateHttp.bad or {}           -- playerID -> сколько раз не донёс
FateHttp.verified = FateHttp.verified or {} -- playerID -> true (донёс хоть раз)
-- Сколько запросов сейчас на руках у клиента. Больше одного не даём: в 7×7
-- конец матча — 16 запросов на 14 клиентов, и в матчах 106–109 терялось
-- ровно 2 — ровно столько клиентов получали второй запрос в том же кадре.
-- Лишние ждут в очереди и уходят, как только кто-то ответит (~1 с).
-- ⚠️ В конце матча очередь так и не разобралась (матчи 110–113) — выгрузка
-- там идёт одним запросом в нескольких копиях, см. SendCopies.
FateHttp.inflight = FateHttp.inflight or {} -- playerID -> число запросов

FATE_HTTP_TIMEOUT = 12       -- секунд на круг «клиент → воркер → клиент → сервер»
FATE_HTTP_MAX_URL = 14000    -- символов; выше — сразу отказ, до сети не доходит
FATE_HTTP_MAX_ATTEMPTS = 3   -- столько разных клиентов пробуем, прежде чем сдаться

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
    self.rawUrl = url
    self.origin, self.path, self.query = FateHttp.SplitUrl(url)
    self.params = {}
    self.key = ""
    self.rid = nil
    self.callback = nil
    self.relayPlayer = nil
    self.timer = nil
    self.tried = {}          -- playerID -> true: этим клиентам уже раздавали
    self.attempts = 0
    self.maxAttempts = FATE_HTTP_MAX_ATTEMPTS
    self.pinned = nil        -- только этот клиент (проверка реле при входе)
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
    if (self.copies or 1) > 1 then
        self:SendCopies(callback)
        return
    end
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
    FateHttp:Submit(self)
end

-- Один и тот же запрос сразу через n разных клиентов, в одном кадре.
-- ⚠️ Зачем (матчи 110–113, 27.09.2026): в конце матча доходила только
-- первая волна — запросы, раздатые клиентам сразу. Всё, что ждало в очереди
-- освобождения клиента, пропадало (4–5 строк из 14 в каждом матче), то есть
-- ответы клиентов после победы до сервера не доходят или не успевают дойти.
-- Поэтому важное в конце матча уходит копиями: доставка не зависит ни от
-- ответа, ни от повтора. Получателю копии безопасны (upsert / mmr_applied).
-- Колбэк зовётся один раз: на первый 200 или, если не дошла ни одна копия,
-- на последний ответ.
function FateHttpRelayRequest:SendCopies(callback)
    local group = { left = self.copies, done = false }
    local tried = {}   -- общий: копии и их повторы расходятся по разным клиентам
    local function onCopy(res)
        group.left = group.left - 1
        if group.done then return end
        if res.StatusCode == 200 or group.left <= 0 then
            group.done = true
            if callback then callback(res) end
        end
    end
    for _ = 1, self.copies do
        local c = FateHttpRelayRequest.New(self.method, self.rawUrl)
        c.key = self.key
        c.params = self.params
        c.tried = tried
        c.isCopy = true
        c:Send(onCopy)
    end
end

-- Сколько копий слать (только реле; нативный запрос и так доходит один).
function FateHttpSetCopies(req, n)
    if type(req) == "table" and getmetatable(req) == FateHttpRelayRequest then
        req.copies = math.max(1, math.floor(tonumber(n) or 1))
    end
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
    -- Игрок вышел, держа запрос: ответа от него уже не будет, а таймаут на
    -- Timers в POST_GAME не сработает — без этого запрос висел бы вечно, и как
    -- раз в конце матча, когда люди расходятся сразу после победы.
    ListenToGameEvent("player_disconnect", function(_, keys)
        FateHttp:OnPlayerGone(keys and keys.PlayerID)
    end, FateHttp)
    log("реле инициализировано")
end

-- Клиент шлёт ready ежесекундно, пока не получит ack. Первые события приходят
-- с PlayerID = -1 (скрипт манифеста стартует раньше раздачи слотов) — их
-- молча пропускаем, не подтверждая.
function FateHttp:OnClientReady(playerID)
    if playerID == nil or playerID < 0 then return end
    -- Без хэндла игрока ни ack, ни запрос ему не доставить. Готовым не
    -- считаем: клиент не получит ack и повторит ready через секунду.
    local player = PlayerResource:GetPlayer(playerID)
    if not player then return end
    CustomGameEventManager:Send_ServerToPlayer(player, "fate_http_ack", {})
    if self.ready[playerID] then return end
    self.ready[playerID] = true
    log("клиент игрока " .. tostring(playerID) .. " готов к реле")
    self:Probe(playerID)
    self:FlushQueue()
end

-- Проверка реле при входе: один /health (без БД и рейт-лимита) через ЭТОГО
-- клиента. Кто не донёс, уходит в конец очереди выбора раньше, чем ему
-- достанется что-то важное: рейтинги в сетапе или выгрузка в конце матча.
function FateHttp:Probe(playerID)
    if not FATE_BINDS_HOST then return end
    if self.nativeAvailable == nil then
        self.nativeAvailable = CreateHTTPRequestScriptVM("GET", FATE_BINDS_HOST .. "/health") ~= nil
    end
    if self.nativeAvailable then return end      -- tools/дедик: реле не нужно
    local req = FateHttpRelayRequest.New("GET", FATE_BINDS_HOST .. "/health")
    req.pinned = playerID
    req.maxAttempts = 1
    req:Send(nil)
end

-- Кто-то отключился: всё, что висело на ушедших клиентах, раздаём заново.
-- PlayerID в событии бывает не всегда, поэтому заодно сверяем состояние.
function FateHttp:OnPlayerGone(playerID)
    -- ⚠️ Снять готовность обязательно. Иначе при переподключении клиент
    -- выбирается сразу, ещё в LOADING, когда его fate_http_relay.js не
    -- загружен: запрос уходит в пустоту, а в POST_GAME его никто не снимет
    -- по таймауту. Вернувшийся клиент сам пришлёт ready, заново пройдёт
    -- проверку и разберёт очередь.
    if playerID ~= nil then self.ready[playerID] = nil end
    local gone = {}
    for rid, req in pairs(self.pending) do
        local p = req.relayPlayer
        if p ~= nil and (p == playerID or not self:IsOnline(p)) then
            gone[#gone + 1] = rid
        end
    end
    for _, rid in ipairs(gone) do
        self:Finish(rid, 0, "relay player disconnected")
    end
    if playerID ~= nil then self.inflight[playerID] = nil end
end

function FateHttp:IsOnline(playerID)
    local state = PlayerResource:GetConnectionState(playerID)
    -- На старте матча клиенты ещё в LOADING; ждать CONNECTED — держать всё в очереди.
    return state == DOTA_CONNECTION_STATE_CONNECTED or state == DOTA_CONNECTION_STATE_LOADING
end

-- Живой человек с загруженным реле, по кругу: в конце матча уходит ~15
-- запросов разом, и лучше размазать их по клиентам, чем вешать все на одного.
-- ⚠️ Доступ в сеть у клиентов НЕ одинаковый (см. FateHttp.bad): сначала
-- хост лобби (см. HostPlayerID), потом проверенных, потом ещё не проверенных,
-- сбоивших — только если больше некого. Клиентов, которым этот запрос уже раздавали, пропускаем.
-- Возвращает playerID, либо nil и busy=true, если подходящие клиенты есть,
-- но все заняты — тогда запрос ждёт в очереди, а не сдаётся.
function FateHttp:SelectRelayPlayer(req)
    local tried = req and req.tried or {}
    if req and req.pinned ~= nil then
        local p = req.pinned
        if self.ready[p] and self:IsOnline(p) and not tried[p]
           and PlayerResource:GetPlayer(p) then
            if (self.inflight[p] or 0) > 0 then return nil, true end
            return p
        end
        return nil
    end
    local host = self:HostPlayerID()
    local free, busy = { {}, {}, {}, {} }, { false, false, false, false }
    for playerID = 0, (DOTA_MAX_TEAM_PLAYERS or 24) - 1 do
        -- GetPlayer: без хэндла Dispatch отложил бы запрос в очередь, а
        -- повтор оттуда не достаётся до появления нового клиента
        if self.ready[playerID]
           and not tried[playerID]
           and PlayerResource:IsValidPlayerID(playerID)
           and not PlayerResource:IsFakeClient(playerID)
           and self:IsOnline(playerID)
           and PlayerResource:GetPlayer(playerID) then
            local tier = (self.bad[playerID] and 4) or (playerID == host and 1)
                      or (self.verified[playerID] and 2) or 3
            if (self.inflight[playerID] or 0) > 0 then
                busy[tier] = true
            else
                free[tier][#free[tier] + 1] = playerID
            end
        end
    end
    for tier, candidates in ipairs(free) do
        -- Сбойному клиенту отдаём, только если хороших нет вовсе; если они
        -- просто заняты, лучше подождать секунду, чем почти наверняка
        -- потерять 10 с на таймаут.
        if tier == 4 and (busy[1] or busy[2] or busy[3]) then return nil, true end
        if #candidates > 0 then
            self.rr = (self.rr or 0) + 1
            return candidates[(self.rr % #candidates) + 1]
        end
    end
    return nil, (busy[1] or busy[2] or busy[3] or busy[4])
end

-- Хост локального лобби: сервер крутится на ЕГО машине, и если он выйдет,
-- матч кончается мгновенно — вместе со всеми запросами в полёте. Значит,
-- его реле самое надёжное из возможных: оно умирает только вместе с
-- сервером, когда терять уже нечего. Поэтому хост идёт первым (если его
-- проверка при входе прошла — сбойный хост остаётся в хвосте, как все).
-- На дедике/в tools хоста нет — nil.
function FateHttp:HostPlayerID()
    if self.hostID ~= nil then return self.hostID end
    if not GetListenServerHost then return nil end
    local ok, host = pcall(GetListenServerHost)
    if not ok or not host or not host.GetPlayerID then return nil end
    local id = host:GetPlayerID()
    if id == nil or id < 0 then return nil end   -- слот ещё не выдан: спросим позже
    self.hostID = id
    return id
end

function FateHttp:Submit(req)
    local playerID, busy = self:SelectRelayPlayer(req)
    if playerID == nil then
        -- Все подходящие клиенты заняты — ждём в очереди: FlushQueue
        -- позовётся на ближайшем ответе (событием, работает и в POST_GAME).
        if busy then
            self.queue[#self.queue + 1] = req
            return
        end
        -- Повтору (или проверке конкретного клиента) отдать некому — сдаёмся.
        -- Первую попытку держим в очереди до появления живого клиента.
        -- Копия, которой не хватило свободного клиента, лишняя: остальные
        -- копии уже в пути.
        if req.attempts > 0 or req.pinned ~= nil or (req.isCopy and next(req.tried) ~= nil) then
            self:Finish(req.rid, 0, "no relay client left", true)
            return
        end
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
    req.tried[playerID] = true
    req.attempts = req.attempts + 1
    self.inflight[playerID] = (self.inflight[playerID] or 0) + 1
    if Timers and Timers.CreateTimer then
        -- таймаут своей попытки: поздний таймер прошлой попытки не должен
        -- оборвать уже новую
        local rid, attempt = req.rid, req.attempts
        req.timer = Timers:CreateTimer(FATE_HTTP_TIMEOUT, function()
            local cur = FateHttp.pending[rid]
            if cur and cur.attempts == attempt then
                FateHttp:Finish(rid, 0, "timeout")
            end
        end)
    end
    log(req.rid .. " " .. req.method .. " " .. req.path .. " -> клиент " .. tostring(playerID)
        .. " (" .. #req.url .. " симв., попытка " .. req.attempts .. ")")
    CustomGameEventManager:Send_ServerToPlayer(player, "fate_http_request", {
        rid = req.rid,
        url = req.url,
    })
end

-- Раздать очередь заново: через Submit, чтобы повтор, которому больше некого
-- ждать, сдался, а не висел. Вложенный вызов (Submit -> Finish -> сюда)
-- пропускаем: внешний цикл и так дойдёт до всех.
function FateHttp:FlushQueue()
    if #self.queue == 0 or self.flushing then return end
    self.flushing = true
    local queued = self.queue
    self.queue = {}
    for _, req in ipairs(queued) do
        if self.pending[req.rid] then
            self:Submit(req)
        end
    end
    self.flushing = false
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

-- final = не повторять (некому больше отдать).
function FateHttp:Finish(rid, status, body, final)
    local req = self.pending[rid]
    if not req then return end
    if req.timer and Timers and Timers.RemoveTimer then
        Timers:RemoveTimer(req.timer)
    end
    req.timer = nil
    local p = req.relayPlayer
    if p ~= nil then
        -- клиент освободился — ниже раздаём очередь
        self.inflight[p] = math.max(0, (self.inflight[p] or 0) - 1)
        if status == 0 then
            self.bad[p] = (self.bad[p] or 0) + 1
        else
            self.verified[p] = true
            self.bad[p] = nil
        end
    end
    -- StatusCode 0 = не донёс именно этот клиент (таймаут, вышел из игры, CEF
    -- не открыл страницу) — пробуем через другого. Ответ воркера с ошибкой
    -- (4xx/5xx/570) не повторяем: другой клиент получит то же самое. Повтор
    -- безопасен: выгрузка — upsert, начисление MMR защищено ключом mmr_applied.
    if status == 0 and not final and req.attempts < req.maxAttempts then
        FateHttp.stats.retry = (FateHttp.stats.retry or 0) + 1
        log(rid .. " " .. tostring(req.path) .. ": клиент " .. tostring(p) .. " не донёс ("
            .. tostring(body) .. "), повтор")
        req.relayPlayer = nil
        self:Submit(req)
        self:FlushQueue()
        return
    end
    self.pending[rid] = nil
    for i = #self.queue, 1, -1 do
        if self.queue[i].rid == rid then table.remove(self.queue, i) end
    end
    self:FlushQueue()
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
    local badList = {}
    for pid, n in pairs(self.bad) do badList[#badList + 1] = tostring(pid) .. "x" .. tostring(n) end
    table.sort(badList)
    local pendingCount = 0
    for _ in pairs(self.pending) do pendingCount = pendingCount + 1 end
    local busyCount = 0
    for _, n in pairs(self.inflight) do if n > 0 then busyCount = busyCount + 1 end end
    return string.format("native=%d relay=%d ok=%d fail=%d retry=%d pending=%d queue=%d busy=%d ready=[%s] bad=[%s]",
        self.stats.native, self.stats.relay, self.stats.ok, self.stats.fail, self.stats.retry or 0,
        pendingCount, #self.queue, busyCount, table.concat(readyList, ","), table.concat(badList, ","))
end
