-- Initialize boosting missions
function InitBoost()
    -- Register callback to start a boost mission
    lib.callback.register('qbx_boosting:server:StartContract', function(source, contract)
        local player = QBX.Functions.GetPlayer(source)
        if not player then return { error = "Player not found" } end
        
        -- Check if player has enough crypto
        local cryptoCount = exports.ox_inventory:GetItem(source, contract.Crypto:lower(), nil, true)
        if cryptoCount < contract.BuyIn then
            return { error = "You don't have enough " .. contract.Crypto }
        end
        
        -- Check if enough cops are online
        local cops = CountCops()
        if cops < contract.MinCops then
            return { error = "Not enough cops on duty. Need at least " .. contract.MinCops }
        end
        
        -- Check if weekly limit reached
        local boostData = GetBoostingDataByCid(player.PlayerData.citizenid)
        if boostData.WeeklyContracts >= Config.WeeklyLimit then
            return { error = "You've reached your weekly contract limit" }
        end
        
        -- Remove crypto from player
        exports.ox_inventory:RemoveItem(source, contract.Crypto:lower(), contract.BuyIn)
        
        -- Add contract to active contracts
        table.insert(ActiveContracts, contract.Id)
        
        -- Start the boost mission
        StartBoostMission(source, contract)
        
        return {
            success = true,
            contracts = GetContractsByCid(player.PlayerData.citizenid)
        }
    end)
    
    -- Register callback to cancel a contract
    lib.callback.register('qbx_boosting:server:CancelContract', function(source, contract)
        return CancelContract(source, contract)
    end)
    
    -- Register server event for VIN scratch preparation
    RegisterNetEvent('qbx_boosting:server:PrepareVIN', function(contract)
        local source = source
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        -- Check if contract is active and is a VIN scratch
        if not IsContractActive(contract.Id) or not contract.Vin then
            return
        end
        
        -- Prepare VIN scratch process
        TriggerClientEvent('qbx_boosting:client:StartVINScratch', source, contract)
    end)
    
    -- Register event for completing VIN scratch
    RegisterNetEvent('qbx_boosting:server:CompleteVINScratch', function(contract, plate)
        local source = source
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        -- Record VIN scratch
        RecordVinScratch(player.PlayerData.citizenid)
        
        -- Remove crypto for VIN scratch cost
        exports.ox_inventory:RemoveItem(source, contract.Crypto:lower(), contract.ScratchPrice)
        
        -- Complete the contract
        CompleteContract(player.PlayerData.citizenid, contract.Class)
        
        -- Remove from active contracts
        for i = 1, #ActiveContracts do
            if ActiveContracts[i] == contract.Id then
                table.remove(ActiveContracts, i)
                break
            end
        end
        
        -- Delete contract from database
        MySQL.query.await('DELETE FROM laptop_boosting WHERE id = ?', {contract.Id})
        
        -- Add vehicle to player's garage
        local vehicleProps = {}
        vehicleProps.plate = plate
        
        -- Add to player's garage using the appropriate garage system
        -- This will depend on your garage system implementation
        exports.qbx_garages:AddVehicle(player.PlayerData.citizenid, contract.Vehicle, vehicleProps, 'vin', true)
        
        -- Notify player
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'VIN Scratch Complete',
            description = 'Vehicle added to your garage',
            type = 'success'
        })
    end)
    
    -- Register event for completing a boost
    RegisterNetEvent('qbx_boosting:server:CompleteBoost', function(contract)
        local source = source
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        -- Add crypto reward to player
        exports.ox_inventory:AddItem(source, contract.Crypto:lower(), contract.Reward)
        
        -- Complete the contract
        CompleteContract(player.PlayerData.citizenid, contract.Class)
        
        -- Remove from active contracts
        for i = 1, #ActiveContracts do
            if ActiveContracts[i] == contract.Id then
                table.remove(ActiveContracts, i)
                break
            end
        end
        
        -- Delete contract from database
        MySQL.query.await('DELETE FROM laptop_boosting WHERE id = ?', {contract.Id})
        
        -- Notify player
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Boost Complete',
            description = 'You received ' .. contract.Reward .. ' ' .. contract.Crypto,
            type = 'success'
        })
    end)
end

-- Start a boosting mission for a player
function StartBoostMission(source, contract)
    -- Send event to client to start boost
    TriggerClientEvent('qbx_boosting:client:StartBoost', source, contract)
    
    -- Alert police
    AlertPolice(contract)
end

-- Alert police about a boosting mission
function AlertPolice(contract)
    -- Get all police officers
    local players = QBX.Functions.GetQBPlayers()
    
    for _, player in pairs(players) do
        if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
            -- Send alert to police MDT or other system
            TriggerClientEvent('qbx_boosting:client:PoliceAlert', player.PlayerData.source, {
                coords = contract.Area,
                class = contract.Class
            })
        end
    end
end 