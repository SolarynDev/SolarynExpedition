--[[---------------------------------------------------------------------------
    Solaryn's Expedition — this play session at a glance.

    Counts what you've done since login: experience gained (and the rate),
    quests handed in, new areas discovered. The rate gives a rough time to
    your next level. Nothing is saved; a /reload starts a new session.
-----------------------------------------------------------------------------]]

local ADDON_NAME = ...
local ns = _G.SolarynExpedition

ns.Session = {}

local Session = ns.Session

local state

local function now()
    return type(_G.GetTime) == "function" and _G.GetTime() or time()
end

local function xpNow()
    local xp = type(_G.UnitXP) == "function" and ns.SafeNum(_G.UnitXP("player")) or nil
    local max = type(_G.UnitXPMax) == "function" and ns.SafeNum(_G.UnitXPMax("player")) or nil
    return xp, max
end

--- Start counting from now.
function Session:Reset()
    local xp, max = xpNow()
    state = {
        started = now(), xp = 0, quests = 0, questXP = 0, areas = 0,
        lastXP = xp, lastMax = max, level = ns.UnitLevelSafe(), levels = 0,
    }
end

--- Experience moved: add what was gained, across a level-up too.
function Session:NoteXP()
    if not state then self:Reset() end
    local xp, max = xpNow()
    if not xp then return end
    local last, lastMax = state.lastXP, state.lastMax
    if last then
        if xp >= last then
            state.xp = state.xp + (xp - last)
        elseif lastMax then
            -- Levelled: the rest of the old bar, then the new bar so far.
            state.xp = state.xp + (lastMax - last) + xp
        end
    end
    state.lastXP, state.lastMax = xp, max
end

function Session:NoteTurnIn(xpReward)
    if not state then self:Reset() end
    state.quests = state.quests + 1
    state.questXP = state.questXP + (ns.SafeNum(xpReward) or 0)
end

function Session:NoteDiscovery(n)
    if not state then self:Reset() end
    state.areas = state.areas + (n or 1)
end

--- { minutes, xp, xpPerHour, toLevel, etaMinutes, quests, questXP, areas, levels }
function Session:Stats()
    if not state then self:Reset() end
    local minutes = math.max(0, (now() - state.started) / 60)
    local perHour = minutes >= 1 and (state.xp / minutes * 60) or nil
    local xp, max = xpNow()
    local toLevel = (xp and max and max > 0) and (max - xp) or nil
    local eta = (perHour and perHour > 0 and toLevel) and (toLevel / perHour * 60) or nil
    local level = ns.UnitLevelSafe()
    return {
        minutes = minutes, xp = state.xp, xpPerHour = perHour, toLevel = toLevel, etaMinutes = eta,
        quests = state.quests, questXP = state.questXP, areas = state.areas,
        levels = (level and state.level) and math.max(0, level - state.level) or 0,
    }
end

local function short(n)
    if n >= 10000 then return string.format("%.1fk", n / 1000) end
    return tostring(math.floor(n + 0.5))
end
Session.Short = short

local function duration(minutes)
    if minutes < 1 then return "under a minute" end
    if minutes < 60 then return string.format("%d min", math.floor(minutes + 0.5)) end
    return string.format("%dh %02dm", math.floor(minutes / 60), math.floor(minutes % 60))
end
Session.Duration = duration

--- Human-readable lines, for /sol stats and the tracker tooltip.
function Session:Lines()
    local s = self:Stats()
    local out = {
        string.format("Playing for %s", duration(s.minutes)),
        string.format("XP gained: %s%s", short(s.xp),
            s.xpPerHour and string.format("  (%s / hour)", short(s.xpPerHour)) or ""),
    }
    if s.etaMinutes then
        table.insert(out, string.format("Next level in about %s at this pace", duration(s.etaMinutes)))
    end
    table.insert(out, string.format("Quests handed in: %d%s", s.quests,
        s.questXP > 0 and string.format("  (%s XP)", short(s.questXP)) or ""))
    table.insert(out, string.format("New areas discovered: %d", s.areas))
    if s.levels > 0 then table.insert(out, string.format("Levels gained: %d", s.levels)) end
    return out
end

function Session:OnLogin() self:Reset() end

ns:RegisterEvent("PLAYER_XP_UPDATE", function() Session:NoteXP() end, Session)
ns:RegisterEvent("QUEST_TURNED_IN", function(_, _, xpReward) Session:NoteTurnIn(xpReward) end, Session)

ns:RegisterModule("Session", Session)

return Session
