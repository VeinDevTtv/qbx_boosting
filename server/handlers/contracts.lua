-- Get all contracts for a specific player
function GetContractsByCid(citizenid)
    -- Get contracts from database
    local result = MySQL.query.await('SELECT * FROM laptop_boosting WHERE cid = ?', {citizenid})
    
    -- If no contracts, return empty array
    if not result or #result == 0 then
        return {}
    end
    
    -- Parse contracts into usable format
    return ParseContracts(result)
end

-- Get player's classes based on experience
function GetClassesFromExperience(experience)
    local currentClass = "D"
    local previousClass = "D"
    
    for i = #Config.ExperienceClasses, 1, -1 do
        local data = Config.ExperienceClasses[i]
        
        if experience >= data.Experience then
            currentClass = data.Class
            break
        end
    end
    
    -- Find the previous class
    for i = 1, #Config.ExperienceClasses do
        local data = Config.ExperienceClasses[i]
        
        if data.Class == currentClass then
            if i > 1 then
                previousClass = Config.ExperienceClasses[i-1].Class
            end
            break
        end
    end
    
    return currentClass, previousClass
end

-- Transfer a contract to another player
function TransferContract(source, targetCid, contract)
    local player = QBX.Functions.GetPlayer(source)
    if not player then return { error = "Player not found" } end
    
    -- Check if target player exists
    local targetPlayer = QBX.Functions.GetPlayerByCitizenId(targetCid)
    if not targetPlayer then return { error = "Target player not found" } end
    
    -- Check if target player has reached max contracts
    local targetContracts = GetContractsByCid(targetCid)
    if #targetContracts >= Config.MaxContractsAllowed then
        return { error = "Target player has too many contracts" }
    end
    
    -- Update contract in database
    MySQL.update.await('UPDATE laptop_boosting SET cid = ? WHERE id = ?', {targetCid, contract.Id})
    
    -- Get target player's name
    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    
    -- Notify target player
    TriggerClientEvent('ox_lib:notify', targetPlayer.PlayerData.source, {
        title = 'New Boosting Contract',
        description = 'You received a contract from ' .. player.PlayerData.charinfo.firstname,
        type = 'inform'
    })
    
    return { success = true, target = targetName }
end

-- Cancel an active contract
function CancelContract(source, contract)
    local player = QBX.Functions.GetPlayer(source)
    if not player then return { error = "Player not found" } end
    
    -- Check if contract is active
    if not IsContractActive(contract.Id) then
        return { error = "Contract is not active" }
    end
    
    -- Remove contract from active contracts
    for i = 1, #ActiveContracts do
        if ActiveContracts[i] == contract.Id then
            table.remove(ActiveContracts, i)
            break
        end
    end
    
    -- Delete contract from database
    MySQL.query.await('DELETE FROM laptop_boosting WHERE id = ?', {contract.Id})
    
    -- Record failed contract
    FailContract(player.PlayerData.citizenid)
    
    return {
        success = true,
        contracts = GetContractsByCid(player.PlayerData.citizenid)
    }
end

-- Clean up expired contracts
function CleanupExpiredContracts()
    local now = os.time()
    
    -- Add proper error handling for table creation
    local success, _ = pcall(function()
        -- Delete expired contracts
        MySQL.query.await('DELETE FROM laptop_boosting WHERE expire < ? AND auction = 0', {now})
        
        -- Process ended auctions
        local endedAuctions = MySQL.query.await('SELECT * FROM laptop_boosting WHERE auction_end < ? AND auction = 1', {now})
        
        if endedAuctions and #endedAuctions > 0 then
            for i = 1, #endedAuctions do
                local auction = endedAuctions[i]
                
                -- If someone bid on the auction
                if auction.bidder ~= "1001" then
                    -- Transfer contract to the highest bidder
                    MySQL.update.await('UPDATE laptop_boosting SET cid = ?, auction = 0 WHERE id = ?', {auction.bidder, auction.id})
                    
                    -- Notify seller (if online)
                    local seller = QBX.Functions.GetPlayerByCitizenId(auction.cid)
                    if seller then
                        exports.ox_inventory:AddItem(seller.PlayerData.source, auction.crypto:lower(), auction.bid)
                        TriggerClientEvent('ox_lib:notify', seller.PlayerData.source, {
                            title = 'Auction Complete',
                            description = 'Your contract was sold for ' .. auction.bid .. ' ' .. auction.crypto,
                            type = 'success'
                        })
                    end
                else
                    -- No bids, return to seller
                    MySQL.update.await('UPDATE laptop_boosting SET auction = 0 WHERE id = ?', {auction.id})
                end
            end
        end
    end)
    
    if not success then
        -- This will prevent the resource from crashing if the tables don't exist yet
        print("[QBX-Boosting] Tables not initialized yet. Skipping cleanup.")
    end
end

-- Create a scheduled task to clean up expired contracts every hour
CreateThread(function()
    while true do
        CleanupExpiredContracts()
        Wait(3600000) -- Run every hour
    end
end) 