string @RHG_guiId = "RHG.gui"
execute(closure() { # GUI 생성 ( 서버 시작시 )
    array @guiInv = array()
    foreach(string @category : array @item in @RHG_config["CATEGORYS"]) {
        double @payment = @item["payment"]
        @itemMeta = @item["meta"]

        @itemMeta["modifiers"] = array(array(
            "attribute": "HORSE_JUMP_STRENGTH",
            "operation": "ADD_NUMBER",
            "amount": @payment,
            "name": @category
        ))
        @itemMeta["flags"] = array("HIDE_ATTRIBUTES")
        @itemMeta["lore"] = array(
            "§e왼 클릭 시 §f1개 구매됩니다. (".@payment")",
            "§eSHIFT 왼 클릭 시 §f16개 구매됩니다. (".@payment * 16")",
        )

        @guiInv[@item["slot"]] = @item
    }
    export("RHG.inventory", @guiInv)
})
void proc _RHG_openGui(string @player, array @viewers, string @guiId = @RHG_guiId, array @RHG_config = @RHG_config) {
    _show_gui(@player, @guiId, 45, "", "랜덤 머리 뽑기", import("RHG.inventory"), closure() {
        array @events = array(
            bind("inventory_click", null, array("virtual": true, "player": @player), @e, @viewers, @RHG_config) {
                cancel()

                if(@e["rawslot"] > 45, exit())
                array @clickItem = @e["slotitem"]
                if(!@clickItem || !array_index_exists(@clickItem, "meta"), exit())

                array @modifiers = @clickItem["meta"]["modifiers"][0]
                string @category = @modifiers["name"]
                double @payment = @modifiers["amount"]

                double @balance = acc_balance(@e["player"])
                
                
                int @paymentCount = 1
                if(@e["clicktype"] == "SHIFT_LEFT", @paymentCount = 16)

                array @inventory = pinv(@e["player"])
                int @space = 0
                foreach(@slot : @item in @inventory) {
                    if(!@item, @space++)
                }
                if(@paymentCount >= @space, die(" 인벤토리 공간이 부족합니다"))

                double @loggingPayment = @payment
                @payment *= @paymentCount
                if(@balance < @payment, die(" 금액이 부족합니다."))
                acc_subtract(@e["player"], @payment)

                @viewers[@e["player"]]["CONFIRM"] = true
                _RHG_actionMotion(@viewers[@e["player"]]["USE_LOCATION"], @category, @clickItem, @e["player"], @viewers, @paymentCount)
                close_pinv(@e["player"])
                
                _logging("shop", time(), "main", "head", @e["player"], puuid(@e["player"]), array("name": "PLAYER_HEAD"), "buy", @paymentCount, @loggingPayment)
                /* TODO
                구매, 모션 마무리 하기
                아머스탠드에서 머리 빼지는거 확인하기
                */
                
            },
            bind("inventory_close", null, array("virtual": true), @e, @viewers) {
                if(!array_index_exists(@viewers, @e["player"]), exit())

                array @viewerInfo = @viewers[@e["player"]]
                foreach(string @eventId in @viewerInfo["EVENTS"]) {
                    unbind(@eventId)
                    #broadcast("UNBIND"@eventId)
                }
                if(!@viewerInfo["CONFIRM"], array_remove(@viewers, @e["player"]))
                

                #array_remove(@viewers, @e["player"]) 삭제는 모션 이후에
            }
        )
        @viewers[@player]["EVENTS"] = @events
    })
}