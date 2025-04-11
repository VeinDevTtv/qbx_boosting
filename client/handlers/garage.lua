-- Client-side garage handling
-- This file handles client-side logic for VIN scratched vehicle garages

-- Set up VIN scratch garage locations
local garageLocations = {
    {
        name = "Scratch Garage 1",
        coords = vector4(143.62, -3047.85, 7.04, 0.0),
        size = vector3(15.0, 15.0, 5.0)
    },
    {
        name = "Scratch Garage 2",
        coords = vector4(731.32, 4172.52, 40.71, 90.0),
        size = vector3(15.0, 15.0, 5.0)
    }
}

-- Initialize garage zones
CreateThread(function()
    for i = 1, #garageLocations do
        local garage = garageLocations[i]
        
        -- Create a zone for the garage
        local zone = lib.zones.box({
            coords = garage.coords.xyz,
            size = garage.size,
            rotation = garage.coords.w,
            debug = false,
            onEnter = function()
                lib.showTextUI('[E] - Access VIN Scratch Garage')
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                if IsControlJustPressed(0, 38) then -- E key
                    OpenVINGarageMenu(garage.name)
                end
            end
        })
    end
end)

-- Open the VIN garage menu
function OpenVINGarageMenu(garageName)
    -- Get vehicles in garage
    local vehicles = lib.callback.await('qbx_boosting:server:GetVINVehicles', false, garageName)
    
    -- Create menu options
    local options = {}
    
    -- Add an option for each vehicle
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        table.insert(options, {
            title = vehicle.label,
            description = 'Plate: ' .. vehicle.plate,
            icon = 'fas fa-car',
            onSelect = function()
                -- Get spawn point
                local spawn = GetVehicleSpawnPoint(garageName)
                
                -- Retrieve the vehicle
                TriggerServerEvent('qbx_boosting:server:RetrieveVINVehicle', vehicle.plate, garageName, spawn)
            end
        })
    end
    
    -- Add option to store current vehicle
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        table.insert(options, 1, {
            title = 'Store Current Vehicle',
            description = 'Store your current vehicle in the garage',
            icon = 'fas fa-parking',
            onSelect = function()
                -- Get current vehicle
                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                
                -- Get plate
                local plate = GetVehicleNumberPlateText(vehicle)
                
                -- Store vehicle
                TriggerServerEvent('qbx_boosting:server:StoreVINVehicle', NetworkGetNetworkIdFromEntity(vehicle), plate, garageName)
            end
        })
    end
    
    -- Show the menu
    lib.registerContext({
        id = 'vin_garage_menu',
        title = garageName,
        options = options
    })
    
    lib.showContext('vin_garage_menu')
end

-- Get a spawn point for a vehicle
function GetVehicleSpawnPoint(garageName)
    -- Find the garage
    local garage = nil
    for i = 1, #garageLocations do
        if garageLocations[i].name == garageName then
            garage = garageLocations[i]
            break
        end
    end
    
    if not garage then return nil end
    
    -- Return the spawn point
    return garage.coords
end 