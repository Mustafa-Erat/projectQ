local conn = exports.mysql:getConn()
local cache = exports.cache

local factions = {}
local factions_rank = {}
local factions_members = {}

dbQuery(function(qh)
    local results = dbPoll(qh, -1)
    if results then
        Async:foreach(results, function(row)
        local fact_id = tonumber(row.faction_id)
        if factions[fact_id] == nil then
            factions[fact_id] = {
                name = row.faction_name,
                type = tonumber(row.faction_type),
                balance = tonumber(row.faction_balance),
                note = tostring(row.note),
                level = tonumber(row.level)
            }
            factions_rank[fact_id] = {}
        end
        table.insert(factions_rank[fact_id], {
            id = tonumber(row.id),
            faction_id = tonumber(fact_id),
            name = row.rank_name
        })
        end, function()
            for k, faction in pairs(factions) do
                dbQuery(function(qh)
                    local results = dbPoll(qh, -1)
                    if results then
                        factions_members[k] = results
                    end
                end, conn, "SELECT id, name FROM characters WHERE faction = " .. k)
            end
            print("! LOADED "..#factions.." FACTİON")
        end)
    end
end, conn, "SELECT f.id as faction_id, f.name as faction_name, f.type as faction_type, f.balance as faction_balance, f.level as level, r.id, r.name as rank_name FROM factions f LEFT JOIN factions_rank r ON f.id = r.faction_id")

addEvent("factions.get.server", true)
addEventHandler("factions.get.server", root, function()
    local fact_id = tonumber(cache:getCharacterData(source, "faction")) or 0
    local fact_info = {}
    local rank_info = {}
    if fact_id > 0 then
        local res = factions[fact_id]
        fact_info = {id = fact_id, name = res.name, type = res.type, balance = res.balance, level = res.level}
        rank_info=factions_rank[fact_id]
        triggerClientEvent(source, "factions.load.client", source, fact_info, rank_info, factions_members[fact_id])
    end
end)