
include("location_functions.ms")
include("select_block.ms")

register_command("evarhg", array( # 설정 명령어
    "permission": "RHG.SET",
    "executor": closure(string @alias, string @sender, array @args) {
        _RHG_selBlockMode(@sender)
        msg(" 원하는 블럭을 우클릭 해주세요")
    },
    "tabcompleter": closure(string @alias, string @sender, array @args) {
        return(array())
    }
))