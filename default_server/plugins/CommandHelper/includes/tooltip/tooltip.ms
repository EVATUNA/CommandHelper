  /*
    0 오류 메시지 (주로 일회성) 점유 할수 없는 청크 점유 할려 할시 뜨는 오류 (주로 명령어를 쓰지 않았는데 오류 메시지가 나는 경우)
      또는 안내 메시지 or 맞춤형 팁 (주로 일회성) 호박이나 수박 줄기를 캐지 않고 열매를 캘시, 돌곡으로 철 캘려고 할시 메시지
    
    1 어드민 공지 (주로 짧은 시간 유지) 
    2 시스템 공지 (주로 짧은 시간 유지) 최상급 광물 채굴, 전설적인 도구, 방어구 조합 공지

    3 발전과제 툴팁 (주로 긴 시간 유지) 발전과제 조건 설명해주는 메시지

    4 주기적으로 올라오는 팁 (주로 일회성) 딱히 뭐 메시지 보여줄거 없을때, 그냥 주기적으로 팁 알려주는 용도
  */
  
  
proc _add_tooltip(@player, @uuid, @priority, @continuation, @time, @notification_time, @message, @default_color_index, @color_index) {
  @players_data = import('players_data')
  if(array_index_exists(@players_data, @uuid)) {
    @player_data = @players_data[@uuid]
    @tooltips = @player_data['tooltip']

    # 알림 시간이 툴팁 시간보다 길 경우 조정
    if(@time != -1 && @notification_time > @time) { @notification_time = @time }
    @new_tooltip = array(
      'message': @message,
      'max_time': @time,
      'time': 0,
      'notification_time': @notification_time,
      'priority': @priority,
      'continuation': @continuation,
      'default_color_index': @default_color_index,
      'color_index': @color_index
    )

    if(array_size(@tooltips) > 0) {
      foreach(@index: @tooltip in @tooltips) {
        if(@priority <= @tooltip['priority'] ) {
          if(!@tooltip['continuation']) {
            array_remove(@tooltips, @index)
          }
          array_insert(@tooltips, @new_tooltip, @index)
          break()
        }
      }
    } else {
      @tooltips[] = @new_tooltip
    }
  }
}

proc _remove_tooltip(@player, @uuid, @priority) {
  @players_data = import('players_data')
  if(array_index_exists(@players_data, @uuid)) {
    @player_data = @players_data[@uuid]
    @tooltips = @player_data['tooltip']
    foreach(@index: @tooltip in @tooltips) {
      if(@tooltip['priority'] == @priority) {
        array_remove(@tooltips, @index)
      }
    }
  }
}

proc _set_tooltip(@player, @uuid) {
  @text = import('text')

  @players_data = import('players_data')
  if(array_index_exists(@players_data, @uuid)) {
    @player_data = @players_data[@uuid]
    @tooltips = @player_data['tooltip']
    if(array_size(@tooltips) > 0) {
      @now_tooltip = @tooltips[0]
      # countdown
      if(@now_tooltip['max_time'] > 0) {
        if(@now_tooltip['time'] < @now_tooltip['max_time']) {
          @now_tooltip['time'] += 1
        } else {
          array_remove(@tooltips, 0)
          if(array_size(@tooltips) > 0) {
            @now_tooltip = @tooltips[0]
          } else {
            @now_tooltip = null
          }
        }
      } else {
        @now_tooltip['time'] += 1
      }
      # show tooltip
      if(is_array(@now_tooltip)) {
        # message
        _set_sidebar(@uuid, 10, @text['space_fonts']['space.-1'].color('#fefe00') @now_tooltip['message'], @text)
        # background
        @backgrounds = array('\ueb10', '\ueb11', '\ueb12', '\ueb13', '\ueb14', '\ueb15', '\ueb16', '\ueb17', '\ueb18', '\ueb19', '\ueb1a', '\ueb1b', '\ueb1c', '\ueb1d', '\ueb1e', '\ueb1f')
        @default_background = string_multiply(@text['space_fonts']['space.-1'].@backgrounds[@now_tooltip['default_color_index']], 4)
        @colored_background = string_multiply(@text['space_fonts']['space.-1'].@backgrounds[@now_tooltip['color_index']], 4)
        # show background
        _set_sidebar(@uuid, 11, color('#fefc00').@default_background, @text)
        if(@now_tooltip['time'] <= @now_tooltip['notification_time'] || @now_tooltip['notification_time'] < 0) {
          set_timeout(200, closure() {
            _set_sidebar(@uuid, 11, color('#fefc00').@colored_background, @text)
          })
          set_timeout(400, closure() {
            _set_sidebar(@uuid, 11, color('#fefc00').@default_background, @text)
          })
          set_timeout(600, closure() {
            _set_sidebar(@uuid, 11, color('#fefc00').@colored_background, @text)
          })
          set_timeout(800, closure() {
            _set_sidebar(@uuid, 11, color('#fefc00').@default_background, @text)
          })
        }
      } else {
        _set_sidebar(@uuid, 10, '', @text)
        _set_sidebar(@uuid, 11, '', @text)
      }
    }
    //broadcast(@tooltips)
  }
}

proc _send_instance_tooltip_msg(@player, @uuid, @message) {
  _add_tooltip(@player, @uuid, 0, false, 3, 1, @message, 0, 4)
}

proc _send_instance_tooltip_system_broadcast(@player, @uuid, @prefix, @message, @time, @color) {
  @data = array(
    'prefix': @prefix,
    'message': @message,
    'time': @time,
    'color': @color
  )
  kafka_send('ch.tooltip_broadcast', json_encode(@data))
}

proc _set_tutorial_msg(@player, @uuid, @message) {
  _remove_tooltip(@player, @uuid, 3)
  @text = import('text')
  @prefix = @text['prefix']['tutorial']
  _add_tooltip(@player, @uuid, 3, true, -1, 3, @prefix @message, 0, 10)
}

proc _reset_tutorial_msg(@player, @uuid) {
  _remove_tooltip(@player, @uuid, 3)
}