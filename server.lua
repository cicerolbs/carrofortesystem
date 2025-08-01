local jobMarker = createMarker(1552, -1675, 16, "cylinder", 2.0, 255, 255, 0, 150)

local routes = {
    {name = "Los Santos para Las Venturas", reward = 5000, dest = {2320, 1289, 10}, vehicleSpawn = {1540, -1685, 13, 0}},
    {name = "San Fierro para Los Santos", reward = 6000, dest = {-2032, 500, 35}, vehicleSpawn = {1540, -1685, 13, 0}}
}

addEventHandler("onMarkerHit", jobMarker, function(hitElement)
    if getElementType(hitElement) == "player" then
        outputChatBox("Digite /iniciar para escolher uma rota do Carro Forte", hitElement, 255, 255, 0)
    end
end)

addCommandHandler("iniciar", function(player)
    triggerClientEvent(player, "carroforte:openPanel", resourceRoot, routes)
end)

addEvent("carroforte:startRoute", true)
addEventHandler("carroforte:startRoute", root, function(index)
    local player = client
    local route = routes[index]
    if not route then return end

    if isElement(getElementData(player, "carroforteVehicle")) then
        destroyElement(getElementData(player, "carroforteVehicle"))
    end

    local spawn = route.vehicleSpawn
    local veh = createVehicle(427, spawn[1], spawn[2], spawn[3], 0, 0, spawn[4] or 0)
    warpPedIntoVehicle(player, veh)

    setElementData(player, "Emprego", "CarroForte")
    setElementData(player, "carroforteVehicle", veh)

    local dest = route.dest
    local mark = createMarker(dest[1], dest[2], dest[3], "checkpoint", 5, 255, 0, 0, 150)
    local blip = createBlipAttachedTo(mark, 41, 2, 255, 0, 0, 255, 0, 99999)
    setElementData(mark, "owner", player)

    addEventHandler("onMarkerHit", mark, function(hit)
        if hit == player or hit == veh then
            givePlayerMoney(player, route.reward)
            outputChatBox("Entrega completa! Você recebeu $" .. route.reward, player, 0, 255, 0)
            if isElement(veh) then destroyElement(veh) end
            destroyElement(source)
            if isElement(blip) then destroyElement(blip) end
        end
    end)
end)
