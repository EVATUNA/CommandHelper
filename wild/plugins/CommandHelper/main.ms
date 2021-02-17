## Data Setting
@players_state = array()
@players_data = array()
@players_item = array()
@hp_blocks = array()

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
# 공용 프로시저 등록
include('includes/interface/main.ms')

## Includes
# 데이터 처리 프로시저 등록
include('includes/chat/main.ms')
include('includes/gameplay/main.ms')

## Final Include
# 최종 Include (이벤트 바인드, 테스크 바인드, 데이터 불러오기)
include('includes/data/main.ms')