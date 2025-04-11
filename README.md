# QBX Boosting

A vehicle boosting system for QBX Framework, designed to work with qbx_laptop.

## Features

- Vehicle boosting contracts with different tiers (D, C, B, A, A+, S, S+)
- Contract queue system for receiving new contracts
- Auction system for selling contracts to other players
- VIN scratching system to permanently own boosted vehicles
- Tracker system requiring hacking to remove
- Police alerts and tracking system
- Experience progression system
- Weekly limits for balancing

## Dependencies

- QBX Core
- ox_lib
- ox_inventory
- oxmysql
- qbx_laptop

## Installation

1. Place the `qbx_boosting` folder in your resources directory
2. Add `ensure qbx_boosting` to your server.cfg (after qbx_laptop)
3. The required database tables will be created automatically on first startup

## Integration with Vehicles

For the boosting system to work properly, your vehicles need to have a `class` property in the QBX Shared Vehicles configuration. This property determines the vehicle's boosting class.

Example in your qbx_core/shared/vehicles.lua:

```lua
QBX.Shared.Vehicles = {
    ['adder'] = {
        name = 'Adder',
        brand = 'Truffade',
        model = 'adder',
        price = 1000000,
        category = 'super',
        class = 'S+',  -- This is the boosting class
        dealer = 'luxury'
    },
    -- More vehicles...
}
```

Valid classes are: "D", "C", "B", "A", "A+", "S", "S+"

## Configuration

You can modify the following configurations in `shared/config.lua`:

- Class chances
- Hack speed requirements
- Contract limits
- VIN scratch limits
- Experience requirements for each class
- Buy-in costs and rewards for each tier
- Tracker counts
- Hacking requirements
- Police requirements

## License

This resource is licensed under the MIT License.

## Credits

- Original fw-boosting by Robijn
- Conversion to QBX by QBX Community
- Thanks to the QBX community for their support and contributions 