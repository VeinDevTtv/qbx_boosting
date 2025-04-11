-- Initialize auction handling
function InitAuction()
    -- Register callback to get all auction contracts
    lib.callback.register('qbx_boosting:server:GetAuctions', function(source)
        local auctions = GetAuctionContracts()
        return auctions
    end)
    
    -- Register callback to place bid on a contract
    lib.callback.register('qbx_boosting:server:PlaceBid', function(source, data)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return { error = "Player not found" } end
        
        -- Check if auction is still active
        local auction = MySQL.query.await('SELECT * FROM laptop_boosting WHERE id = ? AND auction = 1', {data.contract.Id})
        if not auction or #auction == 0 then
            return { error = "Auction no longer exists" }
        end
        
        -- Check if auction has ended
        if auction[1].auction_end < os.time() then
            return { error = "Auction has ended" }
        end
        
        -- Check if bid is higher than current bid
        if data.bid <= auction[1].bid then
            return { error = "Bid must be higher than current bid" }
        end
        
        -- Check if bid is higher than minimum bid
        if data.bid < auction[1].start_bid then
            return { error = "Bid must be at least the starting bid" }
        end
        
        -- Check if player has enough crypto
        local cryptoCount = exports.ox_inventory:GetItem(source, data.contract.Crypto:lower(), nil, true)
        if cryptoCount < data.bid then
            return { error = "You don't have enough " .. data.contract.Crypto }
        end
        
        -- If there was a previous bidder, refund them
        if auction[1].bidder ~= "1001" then
            local previousBidder = QBX.Functions.GetPlayerByCitizenId(auction[1].bidder)
            if previousBidder then
                exports.ox_inventory:AddItem(previousBidder.PlayerData.source, data.contract.Crypto:lower(), auction[1].bid)
                TriggerClientEvent('ox_lib:notify', previousBidder.PlayerData.source, {
                    title = 'Outbid',
                    description = 'You were outbid on a contract auction',
                    type = 'error'
                })
            end
        end
        
        -- Remove crypto from player
        exports.ox_inventory:RemoveItem(source, data.contract.Crypto:lower(), data.bid)
        
        -- Update auction
        local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        MySQL.update.await('UPDATE laptop_boosting SET bid = ?, bidder = ? WHERE id = ?', {
            data.bid,
            player.PlayerData.citizenid,
            data.contract.Id
        })
        
        -- Notify all players about the new auction
        TriggerClientEvent('qbx_boosting:client:SetAuctions', -1, GetAuctionContracts())
        
        return {
            success = true,
            auctions = GetAuctionContracts()
        }
    end)
end

-- Get all active auction contracts
function GetAuctionContracts()
    local result = MySQL.query.await('SELECT * FROM laptop_boosting WHERE auction = 1 AND auction_end > ?', {os.time()})
    
    if not result or #result == 0 then
        return {}
    end
    
    return ParseContracts(result)
end 