--
-- Author: Tang
-- Date: 2016-12-13 09:46:23
--
local RoomLayerModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameRoomLayerModel")
local GameRoomLayer = class("GameRoomLayer", RoomLayerModel)

--获取桌子参数(背景、椅子布局)
function GameRoomLayer:getTableParam()
    local table_bg = cc.Sprite:create("game/yule/gobang/res/roomlist/roomtable.png")
    local bgSize 
    if nil ~= table_bg then
        bgSize = table_bg:getContentSize()
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
            :move(bgSize.width * 0.5,48)
    end    

    return table_bg, {cc.p(bgSize.width * 0.5,-27),cc.p(bgSize.width * 0.5,217)}
end

return GameRoomLayer