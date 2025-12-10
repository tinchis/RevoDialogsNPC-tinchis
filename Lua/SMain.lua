local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('removemoney:rental', function(source, cb, type, price)
    local pdata = QBCore.Functions.GetPlayer(source)
    if (type == 'bici') then 
        price = 10
        pdata.Functions.RemoveMoney('bank', price)
    elseif (type == 'barco') then 
        pdata.Functions.RemoveMoney('bank', price)
    end
end)

QBCore.Functions.CreateCallback('getPlayersJob', function(source, cb)
    local players = QBCore.Functions.GetQBPlayers()
    cb(players)
end)