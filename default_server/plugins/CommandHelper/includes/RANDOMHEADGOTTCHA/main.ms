
if(@server != "main", exit())

array @RHG_config = yml_decode(read("config.yml"))
array @RHG_viewers = array()
array @RHGlocs = json_decode(read("SETTINGBLOCK\\locations.json"))

include("SETTINGBLOCK\\main.ms")

include("motion.ms")
include("gui_handler.ms")

execute(closure() {
    string @canUsingWorld = @RHG_config["TARGET_WORLD"]
    bind("player_interact", array("id": "rhg.opengui"), array("hand": "main_hand", "button": "right"), @e, @canUsingWorld, @RHGlocs, @RHG_viewers) {
        if(!array_index_exists(@e, "location") || @e["location"][3] != @canUsingWorld, exit())
        array @formLoc = _locForm(@e["location"])
        if(_RHG_containLocInALL(@e["location"], @RHGlocs)) {
            cancel()
            
            foreach(string @player : array @inData in @RHG_viewers) {
                if(_compareLoc(@inData["USE_LOCATION"], @formLoc)) {
                    msg(" 이미 다른 플레이어가 사용중입니다.")
                    exit()
                }
            }
            @RHG_viewers[@e["player"]] = array(
                "USE_LOCATION": _locForm(@e["location"]),
                "EVENTS": null,
                "CONFIRM": false
            )
            _RHG_openGui(@e["player"], @RHG_viewers)
        }
    }
})


