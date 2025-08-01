-- Global configuration accessible by other scripts
CONFIG = {
    startPositions = {
        {pos = {1552, -1675, 16}, size = 2.0, rgb = {255, 255, 0, 150}},
    },
    -- Local where the player must go after finishing all deliveries to
    -- finalize the route. A red marker will be created on these
    -- coordinates and the player will need to type /finalrota inside it
    -- to finish the job.
    finalPosition = {1552, -1675, 16},
    routes = {
        {
            name = "Los Santos para Las Venturas",
            vehicleSpawn = {1540, -1685, 13, 0},
            markers = {
                {pos = {2320, 1289, 10}, dropPos = {2322, 1289, 10}, recompensa = {5000, 6000}},
                {pos = {2335, 1300, 10}, dropPos = {2337, 1300, 10}, recompensa = {5000, 6000}},
            }
        },
        {
            name = "San Fierro para Los Santos",
            vehicleSpawn = {1540, -1685, 13, 0},
            markers = {
                {pos = {-2032, 500, 35}, dropPos = {-2030, 500, 35}, recompensa = {6000, 7000}},
                {pos = {-2020, 470, 35}, dropPos = {-2018, 470, 35}, recompensa = {6000, 7000}},
            }
        }
    }
}
