-- Client-side laptop handling
-- This file handles any client-side logic related to the laptop application

-- Register callback for the user choosing between scratch and sell
lib.callback.register('qbx_boosting:client:ChooseVehicleOption', function()
    -- Ask the player what they want to do with the vehicle
    local input = lib.showContext('boosting_vehicle_options')
    
    return input
end)

-- Create the menu for choosing what to do with the vehicle
lib.registerContext({
    id = 'boosting_vehicle_options',
    title = 'Vehicle Options',
    options = {
        {
            title = 'VIN Scratch',
            description = 'Keep the vehicle for yourself (requires crypto payment)',
            icon = 'fas fa-car',
            onSelect = function()
                return "scratch"
            end
        },
        {
            title = 'Sell Vehicle',
            description = 'Deliver the vehicle for crypto payment',
            icon = 'fas fa-money-bill',
            onSelect = function()
                return "sell"
            end
        }
    }
})

-- Handle auction events
RegisterNetEvent('qbx_boosting:client:SetAuctions', function(auctions)
    -- This would update the UI with the latest auction data
    -- For now, we'll just cache it for when the laptop is opened
    CurrentAuctions = auctions
end) 