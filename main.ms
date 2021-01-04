## Data Setting
@players_data = array()
@players_item = array()
@players_verifing_count = array()

@text = array()
async_read('files/font_space.json', closure(@value) {
  @text['space_fonts'] = json_decode(@value)
})
async_read('files/general_emoji.json', closure(@value) {
  @text['general_emoji'] = json_decode(@value)
})

## Channel Register
if(!is_channel_registered('BungeeCord')) {
register_channel('BungeeCord')
}

## POGU UseTable
pogu_use_table('state')
pogu_use_table('seeting_data')
pogu_use_table('chating_data')

proc _send_action_msg(@player, @player_data, @text) {
  switch(@player_data['chating']['en_ko']) {
  case true:
    switch(@player_data['chating']['channel']) {
    case 'general':
      @channel = '\ue3fd'
    case 'guild':
      @channel = '\ue3ff'
    case 'local':
      @channel = '\ue401'
    case 'admin':
      @channel = '\ue403'
    default:
      @channel = '\ue3fd'
    }
  case false:
  switch(@player_data['chating']['channel']) {
    case 'general':
      @channel = '\ue3fe'
    case 'guild':
      @channel = '\ue400'
    case 'local':
      @channel = '\ue402'
    case 'admin':
      @channel = '\ue404'
    default:
      @channel = '\ue3fe'
    }
  }
  action_msg(@player, @text['space_fonts']['space.5'].@channel.@text['space_fonts']['space.-65'].@text['space_fonts']['space.'.@player_data['setting']['resolution']])
}
## Include
foreach(@file in list_files('includes')) {
  if(@file != 'data') {
    include('includes/'.@file.'/main.ms')
  }
}

proc _load_data(@uuid, @players_verifing_count, @players_data) {
  pogu_get('setting_data:'.@uuid, closure(@connected, @value) { @players_data[@uuid]['setting'] = json_decode(_json_unescape(@value)) })
  pogu_get('chating_data:'.@uuid, closure(@connected, @value) { @players_data[@uuid]['chating'] = json_decode(_json_unescape(@value)) })
}
proc _save_data(@uuid, @players_verifing_count, @players_data, @clear) {
  pogu_set('setting_data:'.@uuid, _json_escape(json_encode(@players_data[@uuid]['setting'])), closure(@connected, @value) {})
  pogu_set('chating_data:'.@uuid, _json_escape(json_encode(@players_data[@uuid]['chating'])), closure(@connected, @value) {})
  if(@clear) {
    array_remove(@players_data, @uuid)
  }
}
proc _new_data(@uuid, @players_verifing_count, @players_data) {
  @players_data[@uuid]['chating'] = array(
    'channel': 'general',
    'en_ko': false,
    'selected_badge': '',
    'is_premium': false
  )
  @players_data[@uuid]['setting'] = array(
    'resolution': 427
  )
  _save_data(@uuid, @players_verifing_count, @players_data, false)
}

proc _verify_request(@uuid, @players_verifing_count, @players_data) {
  pogu_has('state:'.@uuid, closure(@connected, @has) {
    if(@has) {
      pogu_get('state:'.@uuid, closure(@connected, @value) {
        if(@value == 'shifting') {
          pogu_set('state:'.@uuid, 'none', closure(@connected, @result) {
            export('state.'@uuid, 'none')
            _load_data(@uuid, @players_verifing_count, @players_data)
          })
        } else {
          pogu_set('state:'.@uuid, 'verifing', closure(@connected, @result) {
            export('state.'@uuid, 'verifing')
            @players_verifing_count[@uuid] = 60
          })
        }
      })
    } else {
      pogu_set('state:'.@uuid, 'verifing', closure(@connected, @result) {
        export('state.'@uuid, 'verifing')
        @players_verifing_count[@uuid] = 60
      })
    }
  })
}
proc _verify_accept(@uuid, @players_verifing_count, @players_data) {
  pogu_set('state:'.@uuid, 'none', closure(@connected, @result) {
    export('state.'@uuid, 'none')
    pogu_has('setting_data:'.@uuid, closure(@connected, @has) {
      if(@has && false) { ## 수정해야함 무조건 new로 되어있음
        _load_data(@uuid, @players_verifing_count, @players_data)
      } else {
        _new_data(@uuid, @players_verifing_count, @players_data)
      }
      array_remove(@players_verifing_count, @uuid)
      @player = player(@uuid)
      tellraw(@player, array(string_multiply('\n', 100).'인증이 완료되었습니다.'))
    })
  })
}

## Bind Event
bind('player_join', null, null, @event, @players_verifing_count, @players_data, @players_item) {
  @player = @event['player']
  @uuid = puuid(@player)
  _verify_request(@uuid, @players_verifing_count, @players_data)
  @players_item[@uuid] = array(
    'hand': get_inventory_item(@uuid, pheld_slot(@player)),
    'armor': get_inventory_item(@uuid, 37),
    'enchantments': array()
  )
}

foreach(@player in all_players()) {
  @uuid = puuid(@player)
  _verify_request(@uuid, @players_verifing_count, @players_data)
  @players_item[@uuid] = array(
    'hand': get_inventory_item(@uuid, pheld_slot(@player)),
    'armor': get_inventory_item(@uuid, 37),
    'enchantments': array()
  )
}

bind('player_quit', null, null, @event, @players_verifing_count, @players_data) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_verifing_count, @uuid)) {
    array_remove(@players_verifing_count, @uuid)
  }
  if(array_index_exists(@players_data, @uuid)) {
    _save_data(@uuid, @players_verifing_count, @players_data, true)
    #if(has_bind('mastery.dash.sneak_down.'.@player)) { unbind('mastery.dash.sneak_down.'.@player) }
    #if(has_bind('mastery.dash.stand_up.'.@player)) { unbind('mastery.dash.stand_up.'.@player) }
    #if(has_bind('mastery.dash.jump.'.@player)) { unbind('mastery.dash.jump.'.@player) }
    #if(has_bind('mastery.dash.fly.'.@player)) { unbind('mastery.dash.fly.'.@player) }
  }
  if(array_index_exists(@players_item, @uuid)) {
    array_remove(@players_item, @uuid)
  }
}

bind('player_command', null, null, @event, @players_verifing_count, @players_data, @text) {
  @player = @event['player']
  @uuid = puuid(@player)
  if(array_index_exists(@players_verifing_count, @uuid)) {
    cancel()
    if(@event['command'] == '/resourcepackverify') {
      _verify_accept(@uuid, @players_verifing_count, @players_data)
    }
  }
}

proc _send_request_msg(@player, @players_verifing_count) {
  @uuid = puuid(@player)
  @message = array(
    'translate': '%1$s%3$s',
    'with': array(
      array(
        array(
          'text': string_multiply('\n', 100)
        ),
        array(
          'text': '설정된 에바참치 리소스팩을 찾을 수 없습니다!\n\n',
          'color': 'red'
        ),
        array(
          'translate': '인증을 완료하기 전까지 일부 시스템 사용이 제한되며\n%s초 후, 서버와 연결이 자동으로 종료됩니다.\n\n',
          'with': array(
            array(
              'text': @players_verifing_count[@uuid],
              'color': 'yellow'
            )
          ),
          'color': 'white'
        ),
        array(
          'text': '리소스팩을 설정한 후, 채팅메시지를 클릭해주세요.\n'
        ),
        array(
          'text': '리소스팩을 다운로드하려면 이 채팅메시지를 클릭해주세요.',
          'underlined': true,
          'color': 'gray',
          'clickEvent': array(
            'action': 'open_url',
            'value': 'https://evatuna.fish/'
          )
        ),
      ),
      array(
        'translate': '%1$s%4$s',
        'with': array(
          array(
            array(
              'text': string_multiply('\n', 100)
            ),
            array(
              'text': '에바참치 리소스팩의 업데이트가 필요합니다!\n\n',
              'color': 'red'
            ),
            array(
              'translate': '인증을 완료하기 전까지 일부 시스템 사용이 제한되며\n%s초 후, 서버와 연결이 자동으로 종료됩니다.\n\n',
              'with': array(
                array(
                  'text': @players_verifing_count[@uuid],
                  'color': 'yellow'
                )
              ),
              'color': 'white'
            ),
            array(
              'text': '최신 버전으로 리소스팩을 설정한 후, 채팅메시지를 클릭해주세요.\n'
            ),
            array(
              'text': '최신 버전의 리소스팩을 다운로드하려면 이 채팅메시지를 클릭해주세요.',
              'underlined': true,
              'color': 'gray',
              'clickEvent': array(
                'action': 'open_url',
                'value': 'https://evatuna.fish/'
              )
            )
          ),
          array(
            array(
              'text': string_multiply('\n', 100)
            ),
            array(
              'text': '최신 버전의 에바참치 리소스팩이 확인되었습니다\n\n',
              'color': 'green'
            ),
            array(
              'translate': '인증을 완료하기 전까지 일부 시스템 사용이 제한되며\n%s초 후, 서버와 연결이 자동으로 종료됩니다.\n\n',
              'with': array(
                array(
                  'text': @players_verifing_count[@uuid],
                  'color': 'yellow'
                )
              ),
              'color': 'white'
            ),
            array(
              'text': '이 채팅메시지를 클릭할 시, 인증이 완료됩니다.',
              'underlined': true,
              'color': 'gray',
              'clickEvent': array(
                'action': 'run_command',
                'value': '/resourcepackverify'
              )
            )
          )
        )
      )
    ),
  )
  tellraw(@player, @message)
}

## Task
@interval_task = set_interval(1000, closure() {
  #broadcast(@players_data)
  foreach(@player in all_players()) {
    @uuid = puuid(@player)
    if(array_index_exists(@players_data, @uuid)) {
      #데이터가 설정됨
      _send_action_msg(@player, @players_data[@uuid], @text)
    } else {
      #인증 받는 중
      if(array_index_exists(@players_verifing_count, @uuid)) {
        if(@players_verifing_count[@uuid] > 0) {
          _send_request_msg(@player, @players_verifing_count)
          @players_verifing_count[@uuid] -= 1
        } else {
          array_remove(@players_verifing_count, @uuid)
          pkick(@player, '리소스팩 설정 후, 다시 접속하여 인증해 주세요!')
        }
      }
    }
  }
})

@cron_task = set_cron('*/1 * * * *', closure() {
  foreach(@player in all_players()) {
    @uuid = @player
    if(import('state.'@uuid) == 'none') {
      if(array_index_exists(@players_data, @uuid)) {
        _save_data(@uuid, @players_verifing_count, @players_data, false)
      }
    }
  }
})