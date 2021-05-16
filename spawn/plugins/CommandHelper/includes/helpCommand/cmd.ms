register_command('cafe', array(
    'executor': closure(@cmd, @sender, @cArgs){
        msg('\ue4dc §aNaverCafe §r : https://cafe.evatuna.fish')
    }
))

register_command('discord', array(
    'executor': closure(@cmd, @sender, @cArgs){
        msg('\ue4dc §7Discord §r : https://discord.evatuna.fish/')
    }
))

register_command('site', array(
    'executor': closure(@cmd, @sender, @cArgs){
        msg('\ue4dc §9EvatunaOffical §r : https://evatuna.fish/')
    }
))

proc _helpcmdArgs() { return(array('info', 'newbie', 'cmds')); }
unregister_command('help')
register_command('help', array(
    'aliases': array('cmds', 'commands', 'newbie', 'info', '도움말', '헬프', '뉴비', '명령어'),
    'executor': closure(@cmd, @sender, @cArgs){
        @prefix = '\ue4dc'
        if(array_size(@cArgs) > 0) {
            @exactArgs = _getArgsExact(_helpcmdArgs(), @cArgs[0])
            if(array_size(@exactArgs) > 0) {
                switch(@exactArgs[0]) {
                    case 'info':
                        msg('§7  §m            §9 INFO §7§m            ')
                        msg('§7  서버명: §f에바참치 §7(§fEvatuna§7)')
                        msg('§7  서버 장르: 야생')
                        msg('§7  총 관리자: 앨리스(§btele§f: @alicearcade, §7dis§f: AA_2#1787)')
                        msg('§7  공식 이메일: support@evatuna.fish')
                        msg('§7  공식 홈페이지 : §7/site')
                        msg('§7  공식 카페 : §a(네이버)§7/cafe')
                        msg('§7  공식 디스코드: §7/discord')
                        msg('§7  마인리스트: §7/vote')
                        msg('§7  서버오픈일: 2021년 06월 01일') 
                        msg('§7  §m                                ')
                    case 'newbie':
                        msg('')
                        msg('§7  저희서버는 §a야생§7서버입니다.')
                        msg('')
                        // set_timeout(4000, closure(){
                        //     msg('')
                        //     msg('§7  유저분들의 놀거리와 재미를 위해 기초를 탄탄하게 §6계획§7하였고')
                        //     msg('§7  기반으로 §9설계§7, §8개발§7하였습니다.')
                        //     msg('')
                        //     set_timeout(4000, closure(){
                        //         msg('')
                        //         msg('§7  부족한 부분이 있다면 여러 시스템들이 더 잘 어우러질 수 있도록')
                        //         msg('§7  §e보완§7하고, §a업데이트§7해 나갈 것 입니다.')
                        //         msg('')
                        //         set_timeout(4000, closure(){
                        //             msg('')
                        //             msg('§7  여러 시스템이 적용되어 있고 야생 유저분들께는 생소할 수 있다 생각하여')
                        //             msg('§7  Wiki를 자세히 써 두었습니다.')
                        //             msg('')
                        //             set_timeout(3000, closure(){
                        //                 msg('')
                        //                 msg('§7  Wiki : /wiki')
                        //                 msg('§7  그리고 /'.@cmd'info 명령어를 통해 저희 서버의 정보를 받아보세요.')
                        //                 msg('')
                        //             })
                        //         })
                        //     })
                        // })
                    case 'cmds':
                        if(array_size(@cArgs) == 1, array_push(@cArgs, 1))
                        if(is_numeric(@cArgs[1]), @page = @cArgs[1], @page = 1)
                        msg('§7※ () = 별명, <> = 필수인자, [] = 선택인자')
                        msg('§6┌────────□■□§e§l 명령어 §9§l['.@page.'/2] §6□■□────────┒')
                        if (@page == 1) {
                            msg('§7  /spawn - 스폰으로 이동합니다.')
                            msg('§7  /home - 홈으로 이동합니다.')
                            msg('§7  /money - 현재 소지한 돈을 확인합니다.')
                            msg('§7  /pay <닉네임> <수량> - 플레이어에게 돈을 송금합니다.')
                            msg('§7  /whisper(w,m,msg,tell) <닉네임> <메세지> - 귓속말을 합니다.')
                            msg('§7  /ch <??> - 채팅 채널을 ..')
                            msg('§7  /resolution - 해상도를 다시 설정합니다.')
                            msg('§7  /skillbook(skill,abilitybook,ability,masterybook,mastery) - 스킬북을 엽니다.')
                        } else if (@page == 2) {
                            msg('§7  /enko - 영/한 치환모드 사용 토글입니다.')
                            msg('§7  /co i - 로그조사 (토글)')
                        } else {
                            msg('§6존재하지 않는 페이지입니다.')
                        }
                    default:
                        msg('§6잘못된 인자가 전달되었습니다.')
                }
                exit()
            }
        } else {
            msg(@prefix'§7/'.@cmd.' info - 서버 정보')
            msg(@prefix'§7/'.@cmd.' newbie - 에바참치 입문자용 가이드')
            msg(@prefix'§7/'.@cmd.' cmds [page] - 서버 명령어')
        }
    },
    'tabcompleter': closure(@cmd, @sender, @useArgs) {
        if(array_size(@useArgs) <= 1) {
            return(_getArgsExact(_helpcmdArgs(), @useArgs[0]))
        }
        return(array())
    }
))

proc _admincmdArgs() { return(array('hga','event','vote','autoquiz')); }
register_command('admincmd', array(
    permission: 'admin.use',
    noPermMsg: color('RED').'권한이 부족합니다.',
    'executor': closure(@cmd, @sender, @cArgs){
         = '§f[ §3! §f] '
        if(array_size(@cArgs) > 0) {
            @exactArgs = _getArgsExact(_admincmdArgs(), @cArgs[0])
            if(array_size(@exactArgs) > 0) {
                switch(@exactArgs[0]) {
                    case 'hga':
                        @itemArr = pinv(@sender, null)

                        if(array_size(@cArgs) == 1, array_push(@cArgs, 1))
                        if(is_numeric(@cArgs[1]), @itemArr['qty'] = @cArgs[1], @itemArr['qty'] = 1)

                        foreach(@player in all_players()){
                            if(pgive_item(@player, @itemArr) > 0, drop_item(ploc(@player), @itemArr))
                        }
                        broadcast('§e관리자가 모든 플레이어에게 아이템을 선물하였습니다.')
                    case 'event':
                        if(@cArgs[1] == 'hga') {
                            foreach(@player in all_players()) {
                                play_named_sound(ploc(@player), array('sound': 'entity.player.levelup', 'pitch': 0.7), array(@player))
                            }
                            broadcast('§7§m─────────────────────────')
                            broadcast('')
                            broadcast('§f잠시후 §b모든 유저분들§f에게 소정의 §a상품§f을 지급해드립니다!')
                            broadcast('§f반드시 인벤토리를 1-3 칸정도를 §6비워§f두시는걸 §8권장§f드립니다.')
                            broadcast('')
                            broadcast('§7§m─────────────────────────')
                        }
                    case 'vote':
                        if(ponline(@cArgs[1])) {
                            broadcast('§e관리자§6'@sender'§e님이§f'@cArgs[1]'§e님에게 추천보상을 재지급 하였습니다.')
                            runas('~console', '/eco give'@cArgs[1]'250')
                            runas('~console', '/givepercentageexp'@cArgs[1]'2')
                        } else {
                            msg('§6해당 플레이어는 온라인상태가 아닙니다.')
                        }
                    case 'autoquiz':
                        export('evaquiz.settime', 0)
                        msg('§6AutoQuiz 관련 인자가 초기화되었습니다.')
                        msg('§6문제가 조기종료 및 즉시 출제될 수 있습니다.')
                    default:
                        msg('§6잘못된 인자가 전달되었습니다.')
                }
                exit()
            }
        } else {
            msg(.'/'.@cmd.' hga <개수> - HandGiveAll')
            msg(.'/'.@cmd.' event hga - hga 이벤트 공지')
            msg(.'/'.@cmd.' vote <닉네임> - 추천보상지급')
            msg(.'/'.@cmd.' autoquiz - autoquiz 초기화')
        }
    },
    'tabcompleter': closure(@cmd, @sender, @useArgs) {
        if(array_size(@useArgs) <= 1) {
            return(_getArgsExact(_admincmdArgs(), @useArgs[0]))
        }
        return(array())
    }
))