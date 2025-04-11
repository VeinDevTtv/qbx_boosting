local QBX = exports['qbx_core']:GetSharedObject()
ActiveContracts = {}

-- Function to initialize database tables
function InitializeDatabase()
    print("[QBX-Boosting] Initializing database tables...")
    
    -- Ensure the database table exists
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `laptop_boosting` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `cid` varchar(50) DEFAULT NULL,
            `class` varchar(5) DEFAULT NULL,
            `xp` int(11) DEFAULT 0,
            `contractor` varchar(50) DEFAULT NULL,
            `vehicle` varchar(50) DEFAULT NULL,
            `expire` bigint(20) DEFAULT NULL,
            `auction` tinyint(1) DEFAULT 0,
            `seller` varchar(50) DEFAULT NULL,
            `start_bid` int(11) DEFAULT 0,
            `bid` int(11) DEFAULT 0,
            `bidder` varchar(50) DEFAULT NULL,
            `auction_end` bigint(20) DEFAULT NULL,
            PRIMARY KEY (`id`) USING BTREE
        )
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `laptop_boosting_data` (
            `cid` varchar(50) NOT NULL,
            `experience` int(11) DEFAULT 0,
            `contracts_completed` int(11) DEFAULT 0,
            `contracts_failed` int(11) DEFAULT 0,
            `weekly_contracts` int(11) DEFAULT 0,
            `weekly_vins` int(11) DEFAULT 0,
            `last_vin` bigint(20) DEFAULT 0,
            `last_special_contract` bigint(20) DEFAULT 0,
            PRIMARY KEY (`cid`) USING BTREE
        )
    ]])

    -- Add columns to the player_vehicles table if they don't exist
    MySQL.query.await([[
        ALTER TABLE `player_vehicles` 
        ADD COLUMN IF NOT EXISTS `vin` tinyint(1) DEFAULT 0,
        ADD COLUMN IF NOT EXISTS `isvin` tinyint(1) DEFAULT 0
    ]])
    
    print("[QBX-Boosting] Database tables initialized successfully!")
end

-- Initialize all handlers when resource starts
CreateThread(function()
    -- Initialize the database first
    InitializeDatabase()

    -- Start all the handler threads and initialize modules
    InitLaptop()
    InitAuction()
    InitBoost()
    InitGarage()
    StartQueueThread()

    -- Reset weekly stats every Monday at midnight
    CreateThread(function()
        while true do
            local now = os.time()
            local date = os.date("*t", now)
            
            -- If it's Monday and midnight (start of the week)
            if date.wday == 2 and date.hour == 0 and date.min == 0 then
                MySQL.update.await('UPDATE `laptop_boosting_data` SET `weekly_contracts` = 0, `weekly_vins` = 0')
                print("[QBX-Boosting] Weekly stats reset")
            end
            
            Wait(60000) -- Check every minute
        end
    end)
    
    -- Cleanup expired contracts every hour
    CreateThread(function()
        while true do
            Wait(10000) -- Initial delay to ensure tables are created
            CleanupExpiredContracts()
            Wait(3600000) -- Check every hour
        end
    end)
    
    print("[QBX-Boosting] Resource initialized successfully!")
end)

-- Register a server event handler for when resources start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print('[QBX-Boosting] Resource started: ' .. resourceName)
    end
end)

-- Register a server event handler for when resources stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print('[QBX-Boosting] Resource stopped: ' .. resourceName)
    end
end)

-- Helper function to parse contracts from database to usable format
function ParseContracts(contracts)
    local result = {}
    
    for i = 1, #contracts do
        local data = contracts[i]
        
        local vehicleData = QBX.Shared.Vehicles[data.vehicle:lower()]
        if not vehicleData then goto continue end
        
        local classData = Config.TierConfigs[data.class]
        local location, offset = GetRandomLocation(data.class)
        local vehiclePrice = math.floor((vehicleData.price or 10000) / 1800)
        
        table.insert(result, {
            Id = data.id,
            Cid = data.cid,
            Started = IsContractActive(data.id),
            Class = data.class,
            Xp = data.xp,
            Contractor = data.contractor,
            Vehicle = data.vehicle,
            VehicleLabel = vehicleData.name,
            Location = location,
            Area = offset,
            Crypto = classData.Crypto,
            BuyIn = classData.BuyIn,
            Reward = math.random(classData.Reward[1], classData.Reward[2]),
            ScratchAllowed = IsContractScratchable(data.cid, data.vehicle),
            ScratchPrice = math.max(vehiclePrice - (vehiclePrice % 5), 5),
            Trackers = classData.Trackers,
            HackTypes = classData.HackTypes,
            AlwaysPeds = classData.AlwaysPeds,
            MinCops = classData.MinCops,
            Expire = data.expire,
            Auction = data.auction == 1,
            Seller = data.seller,
            StartBid = data.start_bid,
            Bid = data.bid,
            Bidder = data.bidder,
            AuctionEnd = data.auction_end
        })
        
        ::continue::
    end
    
    return result
end

-- Helper function to get a random location for a boost
function GetRandomLocation(class)
    local locations = {}
    
    -- Filter locations by class
    for i = 1, #BoostLocations do
        if BoostLocations[i].Class == class then
            table.insert(locations, BoostLocations[i])
        end
    end
    
    local randomIndex = math.random(#locations)
    local selected = locations[randomIndex]
    
    local offset = {
        x = selected.Vehicle.x + math.random(-100, 100),
        y = selected.Vehicle.y + math.random(-100, 100),
        z = selected.Vehicle.z
    }
    
    return selected, offset
end

-- Helper function to check if a contract is currently active
function IsContractActive(id)
    for i = 1, #ActiveContracts do
        if ActiveContracts[i] == id then
            return true
        end
    end
    return false
end 