array proc _randomFirework() {
    array @colors = array("WHITE", "SILVER", "GRAY", "BLACK")
    int @colorSize = array_size(@colors)

    array @firework = array(
        "strength": 0,

        "colors": @colors[rand(0, @colorSize)]
    )
    return(@firework)
}

void proc _RHG_actionMotion(array @targetLoc, string @category, array @bingleHead, string @player, array @viewers, int @paymentCount) {
    array @location = array_deep_clone(@targetLoc)
    @location[0] += 0.5
    @location[1] -= 0.5
    @location[2] += 0.5

    closure @settingStand = closure(string @uuid) {
        string @protectId = bind("player_interact_at_entity", null, array("clicked": "ARMOR_STAND"), @e, @uuid) {
            if(@e["id"] == @uuid, cancel())
        }
        set_entity_spec(@uuid, array(
            "gravity": false,
            "small": true,
            "visible": false,
            "arms": true
        ))
        set_mob_equipment(@uuid, array(
            "HELMET": @bingleHead
        ))
        @poses = array(
            "poseHead": array(
                0, 0, 0
            )
        )
        array @firstLoc = entity_loc(@uuid)

        array @accelerate = array(0.0)
        set_interval(10, closure() {
            @loc = entity_loc(@uuid)
            if(@loc["y"] - @firstLoc["y"] < 1.0) {
                @loc["y"] += 0.05
                set_entity_loc(@uuid, @loc)
            }
            @accelerate[0] += 0.005
            if(@accelerate[0] > 0.02, @accelerate[0] += 0.01)
            @poses["poseHead"][1] += @accelerate[0]
            set_entity_spec(@uuid, array(
                "poses": @poses
            ))

            if(@accelerate[0] > 1) {
                launch_firework(@loc, array(
                    "strength": 0,
                    "colors": "WHITE"
                ))
                launch_firework(@loc, array(
                    "strength": 0,
                    "colors": "GRAY"
                ))

                clear_task()
                entity_remove(@uuid)
                
                array @viewerInfo = @viewers[@player]
                foreach(string @eventId in @viewerInfo["EVENTS"]) {
                    unbind(@eventId)
                }
                array_remove(@viewers, @player)
                unbind(@protectId)

                for(int @i = 1, @i <= @paymentCount, @i++) {
                    runas("~console", "/hdb random"@player @category)
                }
                
            }
            
            
        })

    }
    spawn_entity("ARMOR_STAND", 1, @location, @settingStand)
}
