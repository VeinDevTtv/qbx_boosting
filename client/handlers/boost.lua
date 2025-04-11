local QBX = exports['qbx_core']:GetCoreObject()
CurrentContract = nil
CurrentTaskId = 0
CurrentVehicle = nil
CurrentBlip = nil
CurrentDropBlip = nil
CurrentTrackers = {}
CurrentHackCooldown = 0
DestinationReached = false

-- Start a boosting mission
RegisterNetEvent('qbx_boosting:client:StartBoost', function(contract)
    CurrentContract = contract
    CurrentTaskId = 1
    
    -- Create a blip in the approximate area
    if CurrentBlip then RemoveBlip(CurrentBlip) end
    CurrentBlip = AddBlipForRadius(contract.Area.x, contract.Area.y, contract.Area.z, 150.0)
    SetBlipHighDetail(CurrentBlip, true)
    SetBlipColour(CurrentBlip, 1)
    SetBlipAlpha(CurrentBlip, 128)
    
    -- Add blip route
    local blip = AddBlipForCoord(contract.Area.x, contract.Area.y, contract.Area.z)
    SetBlipSprite(blip, 225)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipAsShortRange(blip, false)
    SetBlipColour(blip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Boosting Vehicle")
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 1)
    
    -- Notify player
    lib.notify({
        title = 'Boosting Contract Started',
        description = 'Head to the marked area',
        type = 'inform'
    })
    
    -- Create a thread to handle the boosting mission
    CreateThread(function()
        local taskCompleted = false
        
        -- Wait for player to arrive at the area
        while CurrentTaskId == 1 do
            local playerPos = GetEntityCoords(PlayerPedId())
            local distance = #(vector3(contract.Area.x, contract.Area.y, contract.Area.z) - playerPos)
            
            if distance < 150.0 then
                -- Remove the radius blip
                RemoveBlip(CurrentBlip)
                CurrentBlip = nil
                
                -- Spawn vehicle and NPCs
                SpawnBoostingVehicle(contract)
                
                -- Update task
                CurrentTaskId = 2
                break
            end
            
            Wait(1000)
        end
        
        -- Task 2: Wait for player to steal the vehicle
        while CurrentTaskId == 2 do
            local playerPed = PlayerPedId()
            
            if IsPedInVehicle(playerPed, CurrentVehicle, false) then
                -- Add trackers to the vehicle
                AddTrackers(contract)
                
                -- Notify player
                lib.notify({
                    title = 'Vehicle Acquired',
                    description = 'Deliver the vehicle to the dropoff point',
                    type = 'success'
                })
                
                -- Set destination
                local dropLocation = DropoffLocations[math.random(#DropoffLocations)]
                SetDropoffPoint(dropLocation)
                
                -- Update task
                CurrentTaskId = 3
                break
            end
            
            Wait(1000)
        end
        
        -- Task 3: Drive to dropoff point
        while CurrentTaskId == 3 do
            local playerPed = PlayerPedId()
            
            -- Check if player is still in the vehicle
            if not IsPedInVehicle(playerPed, CurrentVehicle, false) then
                -- Notify player to get back in vehicle
                lib.notify({
                    title = 'Return to Vehicle',
                    description = 'You need to stay in the vehicle',
                    type = 'error'
                })
                
                Wait(5000)
                goto continue
            end
            
            -- Process tracker removal (hacking)
            if #CurrentTrackers > 0 and CurrentHackCooldown <= 0 then
                ProcessHacking()
            end
            
            -- Update cooldown
            if CurrentHackCooldown > 0 then
                CurrentHackCooldown = CurrentHackCooldown - 1
            end
            
            -- Check if destination reached
            if DestinationReached then
                -- Handle delivery
                if #CurrentTrackers > 0 then
                    -- Ask if player wants to scratch or sell
                    if contract.ScratchAllowed then
                        local choice = lib.callback.await('qbx_boosting:client:ChooseVehicleOption', false)
                        
                        if choice == "scratch" then
                            -- Set up for VIN scratch
                            CurrentContract.Vin = true
                            CurrentTaskId = 4
                            
                            -- Notify player
                            lib.notify({
                                title = 'VIN Scratch Selected',
                                description = 'Go to a VIN Scratch location to proceed',
                                type = 'inform'
                            })
                            
                            -- Set VIN scratch locations
                            SetVINScratchLocations()
                            
                            break
                        else
                            -- Complete boost (sell)
                            CompleteBoosting(contract)
                            break
                        end
                    else
                        -- Complete boost (only sell option)
                        CompleteBoosting(contract)
                        break
                    end
                else
                    -- Trackers still present, can't complete
                    lib.notify({
                        title = 'Trackers Active',
                        description = 'Remove all trackers before delivery',
                        type = 'error'
                    })
                end
            end
            
            ::continue::
            Wait(1000)
        end
        
        -- Task 4: VIN Scratch
        while CurrentTaskId == 4 and CurrentContract.Vin do
            -- Just wait for player to interact with VIN scratch laptop
            -- That interaction is handled by target zones in main.lua
            Wait(1000)
        end
    end)
end)

-- Spawn the boosting vehicle and surrounding NPCs
function SpawnBoostingVehicle(contract)
    -- Get the vehicle spawn location
    local vehicleCoords = contract.Location.Vehicle
    
    -- Request the vehicle model
    local model = GetHashKey(contract.Vehicle)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    -- Create the vehicle
    CurrentVehicle = CreateVehicle(model, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleCoords.w, true, false)
    SetEntityAsMissionEntity(CurrentVehicle, true, true)
    
    -- Generate a random plate
    local plate = GenerateRandomPlate()
    SetVehicleNumberPlateText(CurrentVehicle, plate)
    
    -- Lock the vehicle
    SetVehicleDoorsLocked(CurrentVehicle, 2)
    
    -- Spawn NPCs if needed
    if #contract.Location.NPCs > 0 then
        SpawnNPCs(contract.Location.NPCs)
    end
    
    -- Update the blip to the exact location
    if CurrentBlip then RemoveBlip(CurrentBlip) end
    CurrentBlip = AddBlipForEntity(CurrentVehicle)
    SetBlipSprite(CurrentBlip, 225)
    SetBlipColour(CurrentBlip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Boosting Vehicle")
    EndTextCommandSetBlipName(CurrentBlip)
end

-- Spawn NPCs around the vehicle
function SpawnNPCs(locations)
    local pedModels = {
        "a_m_m_bevhills_01",
        "a_m_m_bevhills_02",
        "a_m_m_business_01",
        "a_m_m_eastsa_01",
        "a_m_m_eastsa_02",
        "a_m_m_farmer_01",
        "a_m_m_fatlatin_01",
        "a_m_m_genfat_01",
        "a_m_m_genfat_02"
    }
    
    for i = 1, #locations do
        local pedModel = pedModels[math.random(#pedModels)]
        local loc = locations[i]
        
        RequestModel(GetHashKey(pedModel))
        while not HasModelLoaded(GetHashKey(pedModel)) do
            Wait(10)
        end
        
        local ped = CreatePed(4, GetHashKey(pedModel), loc.x, loc.y, loc.z, 0.0, true, false)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        -- Give ped a random task
        local randomTask = math.random(1, 3)
        if randomTask == 1 then
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
        elseif randomTask == 2 then
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_SMOKING", 0, true)
        else
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HANG_OUT_STREET", 0, true)
        end
    end
end

-- Generate a random license plate
function GenerateRandomPlate()
    local charset = {}
    for i = 48, 57 do table.insert(charset, string.char(i)) end -- 0-9
    for i = 65, 90 do table.insert(charset, string.char(i)) end -- A-Z
    
    local plate = ""
    for i = 1, 8 do
        local randomChar = charset[math.random(1, #charset)]
        plate = plate .. randomChar
    end
    
    return plate
end

-- Add trackers to the vehicle
function AddTrackers(contract)
    CurrentTrackers = {}
    
    for i = 1, contract.Trackers do
        table.insert(CurrentTrackers, {
            id = i,
            removed = false
        })
    end
    
    -- Reset hack cooldown
    CurrentHackCooldown = 0
end

-- Set the dropoff point for the boost
function SetDropoffPoint(location)
    DestinationReached = false
    
    -- Create blip
    if CurrentDropBlip then RemoveBlip(CurrentDropBlip) end
    CurrentDropBlip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(CurrentDropBlip, 227)
    SetBlipColour(CurrentDropBlip, 2)
    SetBlipDisplay(CurrentDropBlip, 4)
    SetBlipAsShortRange(CurrentDropBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Dropoff Point")
    EndTextCommandSetBlipName(CurrentDropBlip)
    SetBlipRoute(CurrentDropBlip, true)
    SetBlipRouteColour(CurrentDropBlip, 2)
    
    -- Create thread to check distance to dropoff
    CreateThread(function()
        while CurrentTaskId == 3 and not DestinationReached do
            local playerPos = GetEntityCoords(PlayerPedId())
            local distance = #(vector3(location.x, location.y, location.z) - playerPos)
            
            if distance < 5.0 then
                DestinationReached = true
                
                -- Remove blip
                RemoveBlip(CurrentDropBlip)
                CurrentDropBlip = nil
                
                -- Notify player
                lib.notify({
                    title = 'Destination Reached',
                    description = 'You have reached the dropoff point',
                    type = 'success'
                })
            end
            
            Wait(1000)
        end
    end)
end

-- Process tracker hacking
function ProcessHacking()
    -- Check if player speed is high enough
    local speed = GetEntitySpeed(CurrentVehicle) * 3.6 -- Convert to KMH
    
    if speed < Config.HackSpeed then
        return
    end
    
    -- Find a non-removed tracker
    local trackerIndex = nil
    for i = 1, #CurrentTrackers do
        if not CurrentTrackers[i].removed then
            trackerIndex = i
            break
        end
    end
    
    if not trackerIndex then return end
    
    -- Start hacking minigame
    local hackType = CurrentContract.HackTypes[math.random(#CurrentContract.HackTypes)]
    
    -- Different minigames depending on contract class and hack type
    local success = false
    
    if hackType == "numeric" then
        -- Use appropriate hacking minigame (example with ox_lib)
        success = lib.skillCheck({'easy', 'easy', 'medium'})
    else
        -- Use more difficult hacking minigame for other types
        success = lib.skillCheck({'medium', 'medium', 'hard'})
    end
    
    if success then
        -- Remove tracker
        CurrentTrackers[trackerIndex].removed = true
        
        -- Notify player
        lib.notify({
            title = 'Tracker Removed',
            description = 'You removed tracker #' .. trackerIndex,
            type = 'success'
        })
    else
        -- Failed hack
        lib.notify({
            title = 'Hack Failed',
            description = 'Failed to remove tracker',
            type = 'error'
        })
    end
    
    -- Set cooldown
    CurrentHackCooldown = Config.HackCooldown
end

-- Set VIN scratch locations
function SetVINScratchLocations()
    -- Remove previous blips
    if CurrentBlip then RemoveBlip(CurrentBlip) end
    if CurrentDropBlip then RemoveBlip(CurrentDropBlip) end
    
    -- Create blips for all scratch locations
    for i = 1, #ScratchLocations do
        local loc = ScratchLocations[i].Laptop.Coords
        local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(blip, 227)
        SetBlipColour(blip, 5)
        SetBlipDisplay(blip, 4)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("VIN Scratch Location")
        EndTextCommandSetBlipName(blip)
    end
end

-- Process VIN scratch
RegisterNetEvent('qbx_boosting:client:StartVINScratch', function(contract)
    -- Start VIN scratch minigame
    local success = lib.skillCheck({'hard', 'hard', 'hard', 'hard'})
    
    if success then
        -- Generate a new plate for the vehicle
        local newPlate = GenerateRandomPlate()
        SetVehicleNumberPlateText(CurrentVehicle, newPlate)
        
        -- Complete VIN scratch
        TriggerServerEvent('qbx_boosting:server:CompleteVINScratch', contract, newPlate)
        
        -- Clear current contract
        ResetBoostingMission()
        
        -- Notify player
        lib.notify({
            title = 'VIN Scratch Complete',
            description = 'Vehicle is now yours',
            type = 'success'
        })
    else
        -- Failed VIN scratch
        lib.notify({
            title = 'VIN Scratch Failed',
            description = 'You failed to scratch the VIN',
            type = 'error'
        })
    end
end)

-- Complete boosting (sell)
function CompleteBoosting(contract)
    -- Complete the boost on the server
    TriggerServerEvent('qbx_boosting:server:CompleteBoost', contract)
    
    -- Delete the vehicle
    if DoesEntityExist(CurrentVehicle) then
        DeleteEntity(CurrentVehicle)
    end
    
    -- Reset mission
    ResetBoostingMission()
end

-- Reset all boosting mission variables
function ResetBoostingMission()
    CurrentContract = nil
    CurrentTaskId = 0
    CurrentVehicle = nil
    
    if CurrentBlip then RemoveBlip(CurrentBlip) end
    if CurrentDropBlip then RemoveBlip(CurrentDropBlip) end
    
    CurrentBlip = nil
    CurrentDropBlip = nil
    CurrentTrackers = {}
    CurrentHackCooldown = 0
    DestinationReached = false
end

-- Handle police alerts
RegisterNetEvent('qbx_boosting:client:PoliceAlert', function(data)
    -- Only process if player is police
    local playerData = QBX.Functions.GetPlayerData()
    if playerData.job.name ~= "police" or not playerData.job.onduty then
        return
    end
    
    -- Create a blip for the alert
    local blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, 300.0)
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, 128)
    
    -- Send notification
    lib.notify({
        title = 'Vehicle Theft Alert',
        description = 'Class ' .. data.class .. ' vehicle theft in progress',
        type = 'inform'
    })
    
    -- Remove blip after 60 seconds
    SetTimeout(60000, function()
        RemoveBlip(blip)
    end)
end) 