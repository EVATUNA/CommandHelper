
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

proc _load_tutorials(@player_data, @player, @uuid) {
  @achieved_tutorials = _get_advancements(@uuid)
  @tutorials_data = import('tutorials_data')

  @tutorials_in_progress = array()
  foreach(@achieved_tutorial in @achieved_tutorials) {
    @tutorial_data = @tutorials_data[@achieved_tutorial]
    foreach(@child_tutorial in @tutorial_data['children']) {
      if(!array_contains(@achieved_tutorials, @child_tutorial)) {
        @tutorials_in_progress[] = @child_tutorial
      }
    }
  }

  foreach(@tutorial_in_progress in @tutorials_in_progress) {
    @tutorial_data = @tutorials_data[@tutorial_in_progress]
    _load_tutorial(@player, @uuid, @tutorial_in_progress, @tutorial_data)
  }

  @player_data['tutorials_in_progress'] = @tutorials_in_progress
}

proc _load_tutorial(@player, @uuid, @tutorial, @tutorial_data) {
  # 툴팁 띄우기
  if(array_index_exists(@tutorial_data, 'tooltip') && @tutorial_data['tooltip'] != "") {

  }
  
  # 이벤트 바인드
  @proc_name = "_bind_tutorial_@tutorial"
  if(is_proc(@proc_name)) {
    //@players_data = import('players_data')
    call_proc(@proc_name, @player, @uuid, @tutorial, @tutorial_data)
  }
}

proc _unload_tutorial(@player, @uuid, @tutorial) {
  @tutorials_data = import('tutorials_data')
  foreach(@tutorial_event in @tutorials_data['events']) {
    @event_name = "tutorial.@tutorial.@uuid.@tutorial_event"
    if(has_bind(@event_name)) {
      unbind(@event_name)
    }
  }
}