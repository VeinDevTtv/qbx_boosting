-- Initialize garage handling
function InitGarage()
    -- This handler manages the VIN scratch garages and their interactions
    
    -- Register event for storing a VIN scratched vehicle
    RegisterNetEvent('qbx_boosting:server:StoreVINVehicle', function(netId, plate, garage)
        local source = source
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        -- Get the vehicle entity
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if not vehicle or not DoesEntityExist(vehicle) then return end
        
        -- Get vehicle properties
        local model = GetEntityModel(vehicle)
        local modelName = GetDisplayNameFromVehicleModel(model):lower()
        
        -- Store vehicle in garage
        -- This will depend on your garage system implementation
        local success = exports.qbx_garages:StoreVehicle(player.PlayerData.citizenid, plate, modelName, garage, 'vin')
        
        if success then
            -- Delete the vehicle entity
            DeleteEntity(vehicle)
            
            -- Notify player
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Vehicle Stored',
                description = 'Your vehicle was stored in the garage',
                type = 'success'
            })
        else
            -- Notify player of failure
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Storage Failed',
                description = 'Failed to store vehicle in garage',
                type = 'error'
            })
        end
    end)
    
    -- Register event for retrieving a VIN scratched vehicle
    RegisterNetEvent('qbx_boosting:server:RetrieveVINVehicle', function(plate, garage, spawnPoint)
        local source = source
        local player = QBX.Functions.GetPlayer(source)
        if not player then return end
        
        -- Get vehicle details from garage
        local vehicleData = exports.qbx_garages:GetVehicleByPlate(player.PlayerData.citizenid, plate)
        if not vehicleData then return end
        
        -- Check if vehicle is in the specified garage
        if vehicleData.garage ~= garage then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Vehicle Not Found',
                description = 'Vehicle is not in this garage',
                type = 'error'
            })
            return
        end
        
        -- Create the vehicle
        local modelHash = GetHashKey(vehicleData.model)
        
        -- Check if model exists
        if not IsModelInCdimage(modelHash) then return end
        
        -- Load the model
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
        
        -- Spawn the vehicle
        local veh = CreateVehicle(modelHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, true)
        SetEntityAsMissionEntity(veh, true, true)
        
        -- Set plate
        SetVehicleNumberPlateText(veh, plate)
        
        -- Set ownership
        TriggerClientEvent('qbx_vehiclekeys:client:AddKeys', source, plate)
        
        -- Mark as taken from garage
        exports.qbx_garages:SetVehicleState(player.PlayerData.citizenid, plate, 0)
        
        -- Notify player
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Vehicle Retrieved',
            description = 'Your vehicle has been retrieved',
            type = 'success'
        })
        
        -- Set player in driver seat
        TaskWarpPedIntoVehicle(GetPlayerPed(source), veh, -1)
    end)
end 