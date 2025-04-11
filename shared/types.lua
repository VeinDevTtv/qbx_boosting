--[[ 
    This file defines the structure of objects used throughout the boosting system
    Used for documentation purposes as Lua doesn't have types
]]

--[[
BoostingContract = {
    Id = number,
    Cid = string,
    Started = boolean,
    Class = string, -- "D", "C", "B", "A", "A+", "S", "S+"
    Xp = number,
    Contractor = string,
    Vehicle = string,
    VehicleLabel = string,
    Location = table, -- { Vehicle = Vector4, NPCs = Vector3[] }
    Area = Vector3,
    Crypto = string,
    BuyIn = number,
    Reward = number,
    ScratchAllowed = boolean,
    ScratchPrice = number,
    Trackers = number,
    HackTypes = table, -- string[]
    AlwaysPeds = boolean,
    MinCops = number,
    Expire = number,
    Auction = boolean,
    Seller = string,
    StartBid = number,
    Bid = number,
    Bidder = string,
    AuctionEnd = number
}

Queuer = {
    Source = number,
    Cid = string,
    QueuedAt = number
}

VehicleClass = "D" | "C" | "B" | "A" | "A+" | "S" | "S+"

BoostingData = {
    Cid = string,
    Experience = number,
    ContractsCompleted = number,
    ContractsFailed = number,
    WeeklyContracts = number,
    WeeklyVins = number,
    LastVin = number,
    LastSpecialContract = number,
    IsQueued = boolean,
    Contracts = table, -- BoostingContract[]
    Progress = {
        Current = string,
        Previous = string,
        Next = string,
        Progress = number
    }
}
]] 