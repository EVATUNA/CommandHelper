
void proc _RHG_selBlockMode(string @player, array @RHGlocs = @RHGlocs) {
    bind("player_interact", null, array("player": @player, "hand": "main_hand", "button": "right"), @e, @RHGlocs) {
        cancel()
        unbind()

        array @selLoc = _locForm(@e["location"])
        if(_RHG_containLocInALL(@selLoc, @RHGlocs)) {
            msg(" 이미 저장된 장소입니다")
            exit()
        }

        @RHGlocs[] = @selLoc
        async_write_file("locations.json", json_encode(@RHGlocs), "OVERWRITE")
        msg(' 해당 블럭이 설정되었습니다')
    }
}

