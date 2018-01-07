--
-- Author: Tang
-- Date: 2016-10-31 15:45:27
--
local RoomLayerModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameRoomLayerModel")
local GameRoomLayer = class("GameRoomLayer", RoomLayerModel)

--获取桌子参数(背景、椅子布局)
function GameRoomLayer:getTableParam()
    local table_bg = cc.Sprite:create("game/yule/fishyqs/res/roomlist/roomtable.png")

    if nil ~= table_bg then
        local bgSize = table_bg:getContentSize()
        --桌号背景
        display.newSprite("Room/bg_tablenum.png")
            :addTo(table_bg)
            :move(bgSize.width * 0.5,10)
        ccui.Text:create("", "fonts/round_body.ttf", 16)
            :addTo(table_bg)
            :setColor(cc.c4b(255,193,200,255))
            :setTag(1)
            :move(bgSize.width * 0.5,12)
        --状态
        display.newSprite("Room/flag_waitstatus.png")
            :addTo(table_bg)
            :setTag(2)
            :move(bgSize.width * 0.5,68)
    end    

    return table_bg, {cc.p(30,185),cc.p(140,185),cc.p(250,185),cc.p(30,-25),cc.p(140,-25),cc.p(250,-25),cc.p(-20,85),cc.p(294,85)}
end

return GameRoomLayer