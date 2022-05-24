
@tutorials_data = array()
export('tutorials_data', @tutorials_data)

@tutorials = list_files('tutorials')
foreach(@tutorial in @tutorials) {
  @tutorial_path = "tutorials/@tutorial"
  @files = list_files(@tutorial_path)
  foreach(@file in @files) {
    @file_path = "@tutorial_path/@file"
    switch(@file) {
    case 'data.json':
      async_read_file(@file_path, closure(@content) {
        @tutorials_data[@tutorial] = json_decode(@content)
      })
    case 'condition.ms':
      include(@file_path)
      break()
    }
  }
}

set_timeout(100, closure() {
  foreach(@tutorial: @tutorial_data in @tutorials_data) {
    if(array_index_exists(@tutorial_data, 'parent')) {
      @parent_tutorial = @tutorial_data['parent']
      if(array_index_exists(@tutorials_data, @parent_tutorial)) {
        @parent_tutorial_data = @tutorials_data[@parent_tutorial]
        if(!array_index_exists(@parent_tutorial_data, 'children')) { @parent_tutorial_data['children'] = array() }
        @parent_tutorial_data['children'][] = @tutorial
      } else {
        @tutorial_data['parent'] = 'root'
      }
    } else {
      @tutorial_data['parent'] = 'root'
    }
  }
})

proc _load_tutorials(@player, @uuid) {
  @achieved_tutorials = _get_advancements(@uuid)
  @tutorials_data = import('tutorials_data')

  @analyzed_tutorials = array()

  foreach(@achieved_tutorial in @achieved_tutorials) {
    @tutorial_data = @tutorials_data[@achieved_tutorial]
    if(@tutorial_data['parent'] == 'root') {
      
    }
  }


  foreach(@tutorial: @tutorial_data in @tutorials_data) {
    if(@tutorial_data['parent'] == 'root') {

    }
  }

  @loading_tutorials = array()

}

proc _load_tutorial(@player, @uuid) {

  
}








string proc _convertMessage(string @message, array @info) { # 주석 쓰기 귀찮음 수정 할 일 없겠지
    string @result = ""
    @splitMessage = split("", @message)
    for(int @i = 0, @i < array_size(@splitMessage), @i++) {
        @l = 0
        @letter = @splitMessage[@i]
        if(@letter == "%") { # 시작점
            @l = 1
            @keyword = "" # switch 할 때 필요한 키워드
            @convertKeyword = "" # 변형된 키워드
            while(@l < 46) { # 끝나는 %을 찾아냄
                @lPoint = (@i + @l)
                if(@splitMessage[@lPoint] == "%") {
                    switch(@keyword) {
                        case "PLAYER":
                        @convertKeyword = @info["player"]
                    }
                    @result = concat(@result, @convertKeyword)

                    @i = @lPoint
                    break()
                } else {
                    @keyword = concat(@keyword, @splitMessage[@lPoint])
                }
                @l++
            }
        }
        if(@l < 1, @result = concat(@result, @splitMessage[@i]))
        
    }
    
    return(@result)


}



/*
execute(closure() {
    array @configLoader = yml_decode(read("config.yml"))
    array @Tcategories = @configLoader["CATEGORIES"]
    array @advancements = array_keys(@Tcategories)

    array @tutorialEventList = array()
    #하위 폴더 categories에서도 사용 할 변수는 위에서 지정

    void proc _sendTutorialMsg(string @target, string @advancement, int @second = 6, array @categories = @Tcategories) {
        string @uuid = puuid(@target)
        mixed @messages = @categories[@advancement]["MESSAGES"]
        if(!is_array(@messages)) {
            _set_tutorial_msg(@target, @uuid, @messages)
        } else {
            array @point = array(0)
            set_interval((@second * 1000), 100, closure() {
                if(!array_index_exists(@messages, @point[0])) {
                    clear_task()
                    exit()
                }
                @message = _convertMessage(@messages[@point[0]], array(
                    "player": @target
                ))
                _set_tutorial_msg(@target, @uuid, @message)

                @point[0]++
            })
        }
    }
    void proc _tutoRewardProvide(string @player, string @category, string @type = "START", array @categories = @Tcategories) {
        array @categoryInfo = @categories[@category]
        string @type = (@type."_ITEM")
        if(!array_index_exists(@categoryInfo, @type), return())
        array @rewardItem = @categories[@category][@type]
        int @remainCount = pgive_item(@player, @rewardItem)

        if(@remainCount > 0) { # 인벤에 안들어간 템 drop
            @rewardItem["qty"] = @remainCount

            array @location = ploc(@player)
            @location["y"] += 1
            drop_item(@location, @rewardItem)
        }
    }

    include_dir("CATEGORIES\\")
    include("admin.ms")

    void proc _playerDataExport(string @player, array @Tcategories = @Tcategories, array @tutorialEventList = @tutorialEventList) {
        string @uuid = puuid(@player)
        array @categories = array_keys(@Tcategories)
        foreach(int @index : string @attain in _get_advancements(@uuid)) {
            foreach(string @category in @categories) {
                if(@attain == @category) { # 마지막 튜토리얼 과제 찾기
                    int @Iindex = array_keys(@categories)[@index]
                    string @ongoingAdvancement = @categories[@Iindex]
                    break(1)
                }
            }
        }
        _sendTutorialMsg(@player, @ongoingAdvancement)
        string @functionName = ("_TUTO_".@ongoingAdvancement)
        if(!array_index_exists(@tutorialEventList, @player) || !is_array(@tutorialEventList[@player])) {
            @tutorialEventList[@player] = array()
        }
        @tutorialEventList[@player] = call_proc(@functionName, @player)
    }
    foreach(string @player in all_players()) { # 들어와 있는 유저들 데이터 적용
        set_timeout(3000, closure() {
            _playerDataExport(@player)
        })
    }
    bind("resource_pack_status", null, array("status": "SUCCESSFULLY_LOADED"), @e, @Tcategories, @tutorialEventList) {
        set_timeout(200, closure() {
            _playerDataExport(@e["player"])
        })
    }
    bind("player_quit", null, null, @e, @tutorialEventList) {
        foreach(string @eventID in @tutorialEventList[@e["player"]]) {
            unbind(@eventID)
        }
    }
    d
    bind("player_join", array("priority": "LOWEST", "id": "NOOB__JOIN"), null, @e, @Tcategories) {
        string @uuid = puuid(@e["player"])
        set_timeout(200, closure() {
            if(!_has_grant_advancement(@e["player"], "UNEXECUTED_TUTORIAL")) {
                _set_tutorial_msg(@e["player"], @uuid, @Tcategories["UNEXECUTED_TUTORIAL"]["MESSAGES"][0])
            }
        })
    }
})


 */