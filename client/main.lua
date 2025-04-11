local QBX = exports['qbx_core']:GetCoreObject()
CurrentContract = nil
CurrentTaskId = 0

-- Initialize the resource when it starts
CreateThread(function()
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
end)

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