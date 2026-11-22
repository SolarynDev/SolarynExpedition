--[[---------------------------------------------------------------------------
    Solaryn's Expedition — version, what's new, and "is there a newer one?".

    An addon can't reach the internet, so the only way to learn about a newer
    release is from other players running it. Like most popular addons we
    quietly tell guild and group mates which version we run (an addon message,
    invisible in chat) and listen for theirs. Hearing a newer version prints
    one line per session, adds a line to the minimap tooltip and the About
    page, and is remembered until you update. Hearing an older one replies
    with ours, so the news spreads.

    After an update, the first login shows a short "what's new" (ns.WHATS_NEW,
    also /sol version and Options → About).
-----------------------------------------------------------------------------]]

local ADDON_NAME = ...
local ns = _G.SolarynExpedition

ns.Version = {}

local Version = ns.Version

Version.PREFIX = "SolarynExp"         -- addon message prefix (16 chars max)
local MSG_TAG = "V1:"                 -- message format version, then our version
local SEND_COOLDOWN = 60              -- seconds between broadcasts per channel
local REPLY_COOLDOWN = 120            -- seconds between replies to older versions

--- A few lines per release, newest first. The first entry is shown after an
--- update; keep it in step with CHANGELOG.md.
ns.WHATS_NEW = {
    { version = "1.5.0", lines = {
        "Click the current stop on the tracker to read its quest (right-click an upcoming stop; Ctrl-click in the panel).",
        "Hard quests last: elite, group and 3+ levels-up quests come after easier ones, labelled.",
        "Tidier routes that don't double back, re-planned from where you stand when the guide starts.",
        "Where to level: zones with your quests, quests seen offered and unexplored ground rank higher, with reasons.",
        "Discovery announcements, and /sol stats for XP per hour and time to level.",
        "You're told when a guild or group mate has a newer version.",
    } },
}

---------------------------------------------------------------------------
-- Comparing versions
---------------------------------------------------------------------------
--- "1.10.2" -> { 1, 10, 2 }. Anything after the numbers ("-beta") is ignored.
function Version.Parse(v)
    if type(v) ~= "string" then return nil end
    local head = v:match("^v?(%d[%d%.]*)")
    if not head then return nil end
    local nums = {}
    for n in head:gmatch("%d+") do nums[#nums + 1] = tonumber(n) end
    return nums
end

--- -1, 0 or 1 as a is older than, the same as, or newer than b; nil if
--- either can't be read.
function Version.Compare(a, b)
    local pa, pb = Version.Parse(a), Version.Parse(b)
    if not (pa and pb) then return nil end
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then return x < y and -1 or 1 end
    end
    return 0
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local function db() return _G.SolarynDB end

--- The newest version heard from another player, if newer than ours.
function Version:Newer()
    local d = db()
    local v = d and d.newerVersion
    if v and Version.Compare(v, ns.version) == 1 then return v end
    return nil
end

--- One line on whether you're up to date, for tooltips and the About page.
function Version:StatusText()
    local newer = self:Newer()
    if newer then
        return string.format("|cffff9933v%s is available|r (you have v%s). Update through CurseForge or GitHub.",
            newer, tostring(ns.version))
    end
    return string.format("v%s. No newer version seen among your guild and group.", tostring(ns.version))
end

--- What's new in this version (a list of lines, maybe empty).
function Version:WhatsNew(v)
    v = v or ns.version
    for _, entry in ipairs(ns.WHATS_NEW) do
        if Version.Compare(entry.version, v) == 0 then return entry.lines end
    end
    return {}
end

local announced   -- the newer version already printed this session

local function announce(v)
    if announced and Version.Compare(announced, v) >= 0 then return end
    announced = v
    ns:Print("|cffff9933a newer version (v%s) is out|r — you have v%s. Update through CurseForge or GitHub.",
        v, tostring(ns.version))
end

--- Note a version heard from someone else. Returns "newer", "older" or "same".
function Version:Heard(v)
    local cmp = Version.Compare(v, ns.version)
    if cmp == nil then return nil end
    if cmp == 1 then
        local d = db()
        if d and (not d.newerVersion or Version.Compare(v, d.newerVersion) == 1) then d.newerVersion = v end
        announce(v)
        return "newer"
    end
    return cmp == 0 and "same" or "older"
end

---------------------------------------------------------------------------
-- Talking to other copies
---------------------------------------------------------------------------
local function chatInfo(fn)
    local ci = _G.C_ChatInfo
    if type(ci) == "table" and type(ci[fn]) == "function" then return ci[fn] end
    return type(_G[fn]) == "function" and _G[fn] or nil
end

local function call(name, ...)
    local f = _G[name]
    if type(f) ~= "function" then return nil end
    local ok, a = pcall(f, ...)
    return ok and a or nil
end

local function now() return type(_G.GetTime) == "function" and _G.GetTime() or time() end

local lastSent = {}

--- Channels worth telling: guild, and whichever group you're in.
function Version:Channels()
    local out = {}
    if call("IsInGuild") then table.insert(out, "GUILD") end
    local instanceCat = _G.LE_PARTY_CATEGORY_INSTANCE or 2
    if call("IsInGroup", instanceCat) then
        table.insert(out, "INSTANCE_CHAT")
    elseif call("IsInRaid") then
        table.insert(out, "RAID")
    elseif call("IsInGroup") then
        table.insert(out, "PARTY")
    end
    return out
end

--- Tell one channel our version (rate-limited). Returns true if sent.
function Version:Send(channel, force)
    local send = chatInfo("SendAddonMessage")
    if not send or not channel then return false end
    -- Addon messages can be restricted in combat; it can always wait.
    if call("InCombatLockdown") then return false end
    if not force and lastSent[channel] and now() - lastSent[channel] < SEND_COOLDOWN then return false end
    lastSent[channel] = now()
    return pcall(send, Version.PREFIX, MSG_TAG .. tostring(ns.version), channel) and true or false
end

function Version:Broadcast(force)
    local n = 0
    for _, ch in ipairs(self:Channels()) do
        if self:Send(ch, force) then n = n + 1 end
    end
    return n
end

local lastReply = 0

--- Our own broadcasts come back to us; "Name" or "Name-Realm".
local function isMe(sender)
    if not (ns.playerName and type(sender) == "string") then return false end
    local name, realm = sender:match("^([^%-]+)%-?(.*)$")
    local myRealm = (tostring(ns.realmName or ""):gsub("%s", ""))
    return name == ns.playerName and (realm == "" or realm == myRealm)
end

local function onAddonMessage(_, prefix, text, channel, sender)
    -- Payloads can be secret values in restricted situations: check first.
    if not (ns.IsSafe(prefix) and ns.IsSafe(text)) then return end
    if prefix ~= Version.PREFIX or type(text) ~= "string" then return end
    if ns.IsSafe(sender) and isMe(sender) then return end
    local v = text:match("^" .. MSG_TAG:gsub("%p", "%%%0") .. "(.+)$")
    if not v then return end
    local result = Version:Heard(v)
    -- They're behind: answer on the same channel so they hear about ours.
    if result == "older" and ns.IsSafe(channel) and type(channel) == "string" and channel ~= "WHISPER"
        and now() - lastReply >= REPLY_COOLDOWN then
        lastReply = now()
        Version:Send(channel, true)
    end
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
--- After an update: say so once, with the highlights. Silent on a fresh
--- install (the welcome line covers that). Returns true if it printed.
function Version:CheckUpdated()
    local d = db()
    if not d then return false end
    local last = d.lastVersion
    -- Versions before 1.5.0 didn't record this: an existing install without
    -- it is an update from one of them.
    if not last and not ns.freshInstall then last = "1.4.0" end
    d.lastVersion = ns.version
    -- Our own update caught up with what we'd heard about.
    if d.newerVersion and Version.Compare(d.newerVersion, ns.version) ~= 1 then d.newerVersion = nil end
    if not last or Version.Compare(last, ns.version) ~= -1 then return false end
    ns:Print("updated to |cffffd100v%s|r. What's new:", tostring(ns.version))
    for _, line in ipairs(self:WhatsNew()) do ns:Print("  · %s", line) end
    ns:Print("(/sol version shows this again)")
    return true
end

function Version:Initialize()
    local register = chatInfo("RegisterAddonMessagePrefix")
    if register then pcall(register, Version.PREFIX) end
end

function Version:OnLogin()
    self:CheckUpdated()
    local newer = self:Newer()
    if newer then announce(newer) end
    -- Give the guild roster a moment to load before telling it.
    ns:Debounce("version-broadcast", 10, function() Version:Broadcast() end)
end

-- Testing hooks.
function Version:ResetSession() announced, lastReply = nil, 0; lastSent = {} end

ns:RegisterEvent("CHAT_MSG_ADDON", onAddonMessage, Version)
ns:RegisterEvent("GROUP_ROSTER_UPDATE", function()
    ns:Debounce("version-broadcast", 5, function() Version:Broadcast() end)
end, Version)

ns:RegisterModule("Version", Version)

return Version
