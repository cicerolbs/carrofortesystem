-- Configuration table is loaded as a global from config.lua
local CONFIG = _G.CONFIG

local function outputMessage(player, mess, tipo)
    return exports['[HS]Notify_System']:notify(player, mess, tipo)
end

function set_gps(player, x, y, z, element, id)
    local blip = createBlipAttachedTo(element, id or 41)
    setElementVisibleTo(blip, root, false)
    setElementVisibleTo(blip, player, true)
    return blip
end

local jobMarkers = {}
for _, start in ipairs(CONFIG.startPositions) do
    local m = createMarker(start.pos[1], start.pos[2], start.pos[3], "cylinder", start.size or 2.0, start.rgb[1], start.rgb[2], start.rgb[3], start.rgb[4] or 150)
    addEventHandler("onMarkerHit", m, function(hitElement)
        if getElementType(hitElement) == "player" then
            outputMessage(hitElement, "Digite /iniciar para escolher uma rota do Carro Forte", "info")
        end
    end)
    table.insert(jobMarkers, m)
end

local routes = CONFIG.routes

local function buildClientRoutes()
    local list = {}
    for _, route in ipairs(routes) do
        local total = 0
        for _, m in ipairs(route.markers) do
            if m.recompensa then
                total = total + (m.recompensa[2] or 0)
            end
        end
        table.insert(list, {name = route.name, reward = total})
    end
    return list
end

addCommandHandler("iniciar", function(player)
    triggerClientEvent(player, "carroforte:openPanel", resourceRoot, buildClientRoutes())
end)

local playerData = {}

local function freezeVehicleAndPlayer(veh, player, ms)
    if isElement(veh) then setElementFrozen(veh, true) end
    if isElement(player) then setElementFrozen(player, true) end
    setTimer(function()
        if isElement(veh) then setElementFrozen(veh, false) end
        if isElement(player) then setElementFrozen(player, false) end
    end, ms, 1)
end

local function createNextMarker(player)
    local data = playerData[player]
    local route = data.route
    local step = data.step
    local markerData = route.markers[step]
    if not markerData then
        outputMessage(player, "Todas as entregas foram concluídas! Volte ao ponto inicial e digite /finalrota", "info")
        if isElement(data.blip) then destroyElement(data.blip) end
        local startPos = data.startPos or CONFIG.startPositions[1].pos
        local blip = createBlip(startPos[1], startPos[2], startPos[3], 41)
        setElementVisibleTo(blip, root, false)
        setElementVisibleTo(blip, player, true)
        data.finalBlip = blip
        data.finished = true
        return
    end

    local mark = createMarker(markerData.pos[1], markerData.pos[2], markerData.pos[3], "checkpoint", 5, 255, 0, 0, 150)
    local blip = set_gps(player, markerData.pos[1], markerData.pos[2], markerData.pos[3], mark, 41)
    data.marker = mark
    data.blip = blip

    data.handler = function(hitElement)
        if hitElement == player or hitElement == data.vehicle then
            removeEventHandler("onMarkerHit", mark, data.handler)
            destroyElement(mark)
            if isElement(blip) then destroyElement(blip) end
            local recompensa = markerData.recompensa or {0,0}
            local valor = math.random(recompensa[1] or 0, recompensa[2] or 0)
            givePlayerMoney(player, valor)
            outputMessage(player, "Entrega completa! Você recebeu $" .. valor, "success")
            freezeVehicleAndPlayer(data.vehicle, player, 10000)
            data.step = data.step + 1
            setTimer(function()
                if playerData[player] then
                    if route.markers[data.step] then
                        outputMessage(player, "Vá pegar o próximo malote!", "info")
                    end
                    createNextMarker(player)
                end
            end, 10000, 1)
        end
    end
    addEventHandler("onMarkerHit", mark, data.handler)
end

addEvent("carroforte:startRoute", true)
addEventHandler("carroforte:startRoute", root, function(index)
    local player = client
    local route = routes[index]
    if not route then return end

    local veh = getElementData(player, "carroforteVehicle")
    if isElement(veh) then destroyElement(veh) end

    local spawn = route.vehicleSpawn
    veh = createVehicle(427, spawn[1], spawn[2], spawn[3], 0, 0, spawn[4] or 0)
    warpPedIntoVehicle(player, veh)

    setElementData(player, "Emprego", "CarroForte")
    setElementData(player, "carroforteVehicle", veh)

    -- Save nearest start position to require returning later
    local px, py, pz = getElementPosition(player)
    local nearest = CONFIG.startPositions[1].pos
    local minDist = getDistanceBetweenPoints3D(px, py, pz, nearest[1], nearest[2], nearest[3])
    for _, start in ipairs(CONFIG.startPositions) do
        local dist = getDistanceBetweenPoints3D(px, py, pz, start.pos[1], start.pos[2], start.pos[3])
        if dist < minDist then
            minDist = dist
            nearest = start.pos
        end
    end

    playerData[player] = {route = route, step = 1, vehicle = veh, startPos = nearest}
    createNextMarker(player)
end)

addCommandHandler("finalrota", function(player)
    local data = playerData[player]
    if not data or not data.finished then
        outputMessage(player, "Você ainda não concluiu todas as entregas.", "error")
        return
    end
    local startPos = data.startPos or CONFIG.startPositions[1].pos
    local x, y, z = getElementPosition(player)
    if getDistanceBetweenPoints3D(x, y, z, startPos[1], startPos[2], startPos[3]) > 5 then
        outputMessage(player, "Vá até o ponto inicial para finalizar a rota.", "error")
        return
    end
    if isElement(data.vehicle) then destroyElement(data.vehicle) end
    if isElement(data.finalBlip) then destroyElement(data.finalBlip) end
    playerData[player] = nil
    setElementData(player, "Emprego", nil)
    outputMessage(player, "Rota finalizada!", "success")
end)
