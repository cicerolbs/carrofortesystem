local panelVisible = false
local routes = {}
local selectedRoute = nil

local screenW, screenH = guiGetScreenSize()
local panelW, panelH = 400, 300
local panelX, panelY = (screenW-panelW)/2, (screenH-panelH)/2
local startBtn = {x = panelX + 100, y = panelY + panelH - 50, w = 200, h = 40}

addEvent("carroforte:openPanel", true)
addEventHandler("carroforte:openPanel", resourceRoot, function(serverRoutes)
    routes = serverRoutes
    panelVisible = true
    selectedRoute = nil
    showCursor(true)
end)

addEventHandler("onClientRender", root, function()
    if not panelVisible then return end
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(0,0,0,180))
    dxDrawText("Rotas Carro Forte", panelX, panelY, panelX+panelW, panelY+30, tocolor(255,255,255), 1, "default", "center", "center")
    local y = panelY + 40
    for i,route in ipairs(routes) do
        local color = selectedRoute == i and tocolor(255,255,0) or tocolor(255,255,255)
        local text = i..". "..route.name.." - $"..route.reward
        dxDrawText(text, panelX+10, y, panelX+panelW-10, y+20, color, 1, "default", "left", "center")
        y = y + 25
    end
    dxDrawRectangle(startBtn.x, startBtn.y, startBtn.w, startBtn.h, tocolor(0,100,0,200))
    dxDrawText("Iniciar", startBtn.x, startBtn.y, startBtn.x+startBtn.w, startBtn.y+startBtn.h, tocolor(255,255,255), 1, "default", "center", "center")
end)

addEventHandler("onClientClick", root, function(button, state, x, y)
    if not panelVisible or button ~= "left" or state ~= "up" then return end
    local ry = panelY + 40
    for i,_ in ipairs(routes) do
        if x >= panelX+10 and x <= panelX+panelW-10 and y >= ry and y <= ry+20 then
            selectedRoute = i
            return
        end
        ry = ry + 25
    end
    if x >= startBtn.x and x <= startBtn.x+startBtn.w and y >= startBtn.y and y <= startBtn.y+startBtn.h then
        if selectedRoute then
            triggerServerEvent("carroforte:startRoute", localPlayer, selectedRoute)
            panelVisible = false
            showCursor(false)
        else
            outputChatBox("Selecione uma rota primeiro", 255, 0, 0)
        end
    end
end)

addCommandHandler("fechar", function()
    if panelVisible then
        panelVisible = false
        showCursor(false)
    end
end)
