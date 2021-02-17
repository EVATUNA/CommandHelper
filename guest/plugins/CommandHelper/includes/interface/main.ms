console('EvaInterface loaded')

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
  action_msg(@player, @text['space_fonts']['space.5'].@channel.@text['space_fonts']['space.-65'].@text['space_fonts']['space.'.@player_data['setting']['interface']['resolution']])
}
