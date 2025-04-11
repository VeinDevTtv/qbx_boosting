-- Try different methods to load QBX Core
local QBX = nil
local loadAttempts = 0
local maxAttempts = 10

local function LoadQBXCore()
    loadAttempts = loadAttempts + 1
    
    -- Try different methods to load QBX Core
    local success, result = pcall(function()
        -- Method 1: Try require
        return require('qbx_core')
    end)
    
    if success and result then
        print('[QBX-Boosting] Successfully loaded QBX Core via require')
        return result
    end
    
    -- Method 2: Try direct export
    success, result = pcall(function()
        return exports['qbx_core']:GetCoreObject()
    end)
    
    if success and result then
        print('[QBX-Boosting] Successfully loaded QBX Core via GetCoreObject export')
        return result
    end
    
    -- Method 3: Try GetSharedObject export
    success, result = pcall(function()
        return exports['qbx_core']:GetSharedObject()
    end)
    
    if success and result then
        print('[QBX-Boosting] Successfully loaded QBX Core via GetSharedObject export')
        return result
    end
    
    print('[QBX-Boosting] Failed to load QBX Core. Attempt ' .. loadAttempts .. ' of ' .. maxAttempts)
    return nil
end

-- Try to load QBX Core
CreateThread(function()
    while not QBX and loadAttempts < maxAttempts do
        QBX = LoadQBXCore()
        
        if not QBX then
            Wait(1000)
        end
    end
    
    if not QBX then
        print('[QBX-Boosting] Failed to load QBX Core after ' .. maxAttempts .. ' attempts. Resource may not function correctly.')
        return
    end
    
    print('[QBX-Boosting] QBX Core loaded successfully. Initializing resource...')
    
    -- Initialize the resource
    InitializeResource()
end)

CurrentContract = nil
CurrentTaskId = 0

-- Initialize the resource
function InitializeResource()
    -- Set up scratch laptop zones for each location in ScratchLocations
    for i = 1, #ScratchLocations do
        local data = ScratchLocations[i]
        exports.ox_target:addBoxZone({
            coords = vec3(data.Laptop.Coords.x, data.Laptop.Coords.y, data.Laptop.Coords.z),
            size = vec3(0.3, 0.3, 0.4),
            rotation = data.Laptop.Coords.w,
            debug = false,
            options = {
                {
                    name = "boosting-vin-laptop-" .. i,
                    icon = "fas fa-laptop",
                    label = "Prepare VIN Scratch",
                    distance = 2.5,
                    onSelect = function()
                        TriggerEvent("qbx_boosting:client:PrepareVIN")
                    end,
                    canInteract = function()
                        return CurrentContract ~= nil and CurrentContract.Vin and CurrentTaskId == 4
                    end
                }
            }
        })

        -- Create the laptop object if needed
        if data.Laptop.Create then
            lib.requestModel(data.Laptop.Create)
            local object = CreateObject(data.Laptop.Create, data.Laptop.Coords.x, data.Laptop.Coords.y, data.Laptop.Coords.z, true, false, false)
            FreezeEntityPosition(object, true)
            SetEntityHeading(object, data.Laptop.Coords.w)
            SetEntityCollision(object, false, false)
        end
    end
end

-- The following exports will be used by qbx_laptop

exports('GetData', function(data)
    local result = lib.callback.await('qbx_boosting:server:GetData', false)
    return result
end)

exports('GetContracts', function(data)
    local result = lib.callback.await('qbx_boosting:server:GetContracts', false)
    return result
end)

exports('GetAuctions', function(data)
    local result = lib.callback.await('qbx_boosting:server:GetAuctions', false)
    return result
end)

exports('SetQueue', function(data)
    local result = lib.callback.await('qbx_boosting:server:SetQueue', false, data.state)
    return result
end)

exports('StartContract', function(data)
    local result = lib.callback.await('qbx_boosting:server:StartContract', false, data.contract)
    return result
end)

exports('DeclineContract', function(data)
    local result = lib.callback.await('qbx_boosting:server:DeclineContract', false, data.contract)
    return result
end)

exports('CancelContract', function(data)
    local result = lib.callback.await('qbx_boosting:server:CancelContract', false, data.contract)
    return result
end)

exports('AuctionContract', function(data)
    local result = lib.callback.await('qbx_boosting:server:AuctionContract', false, data)
    return result
end)

exports('TransferContract', function(data)
    local result = lib.callback.await('qbx_boosting:server:TransferContract', false, data)
    return result
end)

exports('PlaceBid', function(data)
    local result = lib.callback.await('qbx_boosting:server:PlaceBid', false, data)
    return result
end)

-- Create group event handler
RegisterNetEvent('qbx_boosting:client:CreateGroup', function()
    local myJob = lib.callback.await('qbx_jobmanager:server:GetMyJob', false)
    if not myJob or not myJob.CurrentJob then return end
    if myJob.CurrentJob ~= "boosting" then return end

    lib.callback.await('qbx_jobmanager:server:CreateGroup', false, "boosting")
    Wait(100)
    lib.callback.await('qbx_jobmanager:server:Ready', false, "boosting", myJob.CurrentGroup.Id)
end)

-- Prepare VIN scratch event handler
RegisterNetEvent('qbx_boosting:client:PrepareVIN', function()
    -- This would be implemented in the handlers/boost.lua file
    -- Just a placeholder for now
    if CurrentContract and CurrentContract.Vin and CurrentTaskId == 4 then
        TriggerServerEvent('qbx_boosting:server:PrepareVIN', CurrentContract)
    end
end) 