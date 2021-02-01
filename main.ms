## Data Setting
@players_state = array()
@players_data = array()
@players_item = array()

@text = array()
async_read('files/font_space.json', closure(@value) {
  @text['space_fonts'] = json_decode(@value)
})
async_read('files/general_emoji.json', closure(@value) {
  @text['general_emoji'] = json_decode(@value)
})

## POGU UseTable
pogu_use_table('setting_data')
pogu_use_table('chating_data')
pogu_use_table('skill_data')

## Initial Include
# 가장 상위 Include EX) 채팅이나 스킬에 따른 인터페이스 보여주기위한 세팅
include('includes/interface/main.ms')

## Includes
include('includes/chat/main.ms')
include('includes/gameplay/main.ms')

## Final Include
# 최종 Include (채팅, 스킬, 숙련도 포함, 위 Includes에서 다뤘던 데이터들을 저장 및 불러오기)
include('includes/data/main.ms')