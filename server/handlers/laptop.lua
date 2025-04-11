local QBX = exports['qbx_core']:GetCoreObject()

function InitLaptop()
    -- Callback to get boosting data for a player
    lib.callback.register('qbx_boosting:server:GetData', function(source)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        local boostData = GetBoostingDataByCid(player.PlayerData.citizenid)
        local currentClass, previousClass = GetClassesFromExperience(boostData.Experience)
        
        local currentIndex = 0
        for i = 1, #Config.ExperienceClasses do
            if Config.ExperienceClasses[i].Class == currentClass then
                currentIndex = i
                break
            end
        end
        
        local currentExperience = Config.ExperienceClasses[currentIndex].Experience
        local nextClass = Config.ExperienceClasses[currentIndex + 1] or Config.ExperienceClasses[currentIndex]
        local progressPercentage = (boostData.Experience - currentExperience) / (nextClass.Experience - currentExperience) * 100
        
        boostData.Progress = {
            Current = currentClass,
            Previous = previousClass,
            Next = nextClass.Class,
            Progress = progressPercentage
        }
        
        boostData.IsQueued = IsPlayerQueued(player.PlayerData.citizenid)
        boostData.Cid = player.PlayerData.citizenid
        
        return boostData
    end)
    
    -- Callback to set queue status
    lib.callback.register('qbx_boosting:server:SetQueue', function(source, state)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        if state then
            AddCidToQueue(source, player.PlayerData.citizenid)
            return "Ok"
        else
            RemoveCidFromQueue(source, player.PlayerData.citizenid)
            return "Ok"
        end
    end)
    
    -- Callback to get contracts for a player
    lib.callback.register('qbx_boosting:server:GetContracts', function(source)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        local contracts = GetContractsByCid(player.PlayerData.citizenid)
        return contracts
    end)
    
    -- Callback to transfer a contract to another player
    lib.callback.register('qbx_boosting:server:TransferContract', function(source, data)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        local result = TransferContract(source, data.target, data.contract)
        
        return {
            data = result,
            contracts = GetContractsByCid(player.PlayerData.citizenid)
        }
    end)
    
    -- Callback to decline a contract
    lib.callback.register('qbx_boosting:server:DeclineContract', function(source, contract)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        MySQL.query.await('DELETE FROM laptop_boosting WHERE id = ?', {contract.Id})
        
        return {
            contracts = GetContractsByCid(player.PlayerData.citizenid)
        }
    end)
    
    -- Callback to auction a contract
    lib.callback.register('qbx_boosting:server:AuctionContract', function(source, data)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        local auctionEnd = os.time() + (30 * 60) -- 30 minutes
        
        MySQL.update.await('UPDATE `laptop_boosting` SET `auction` = 1, `seller` = ?, `start_bid` = ?, `bid` = 0, `bidder` = "1001", `auction_end` = ? WHERE `id` = ?', {
            name,
            data.bid,
            auctionEnd,
            data.contract.Id
        })
        
        TriggerClientEvent('qbx_boosting:client:SetAuctions', -1, GetAuctionContracts())
        
        return {
            contracts = GetContractsByCid(player.PlayerData.citizenid)
        }
    end)
    
    -- Callback to place a bid on a contract
    lib.callback.register('qbx_boosting:server:PlaceBid', function(source, data)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        
        MySQL.update.await('UPDATE `laptop_boosting` SET `bid` = ?, `bidder` = ? WHERE `id` = ?', {
            data.bid,
            name,
            data.contract.Id
        })
        
        TriggerClientEvent('qbx_boosting:client:SetAuctions', -1, GetAuctionContracts())
        
        return {
            auctions = GetAuctionContracts()
        }
    end)
    
    -- Callback to start a contract
    lib.callback.register('qbx_boosting:server:StartContract', function(source, contract)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        -- Check if player has enough crypto
        local cryptoCount = exports.ox_inventory:GetItem(source, contract.Crypto:lower(), nil, true)
        if cryptoCount < contract.BuyIn then
            return {
                error = "You don't have enough " .. contract.Crypto
            }
        end
        
        -- Check if enough cops are online
        local cops = CountCops()
        if cops < contract.MinCops then
            return {
                error = "Not enough cops on duty"
            }
        end
        
        -- Remove crypto
        exports.ox_inventory:RemoveItem(source, contract.Crypto:lower(), contract.BuyIn)
        
        -- Add contract to active contracts
        table.insert(ActiveContracts, contract.Id)
        
        -- Start the boost mission
        StartBoostMission(source, contract)
        
        return {
            contracts = GetContractsByCid(player.PlayerData.citizenid)
        }
    end)
end

-- Helper function to count cops online
function CountCops()
    local players = QBX.Functions.GetQBPlayers()
    local cops = 0
    
    for _, player in pairs(players) do
        if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
            cops = cops + 1
        end
    end
    
    return cops
end 