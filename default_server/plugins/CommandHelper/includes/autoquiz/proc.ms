export('evaquiz.answer', '')
export('evaquiz.question_message', '')
export('evaquiz.question_math_message', '')
export('evaquiz.question_type', '')
export('evaquiz.question_answer', '')
export('evaquiz.reward', 0)
export('evaquiz.status', 0)
export('evaquiz.settime', 0)
export('evaquiz.chance', 0)
export('evaquiz.proverb.ko', split('\n', comp_read('proverb_ko.txt')))
export('evaquiz.proverb.en', split('\n', comp_read('proverb_en.txt')))

register_command('quiztest', array(
    permission: 'admin.use',
    'executor': closure(@cmd, @sender, @cArgs){
        
    }
))

export('evaquiz.process_user', array())
proc _getUser() { return(import('evaquiz.process_user')) }
proc _addUser(@value){
    @array = import('evaquiz.process_user')
    array_push(@array, @value)
    export('evaquiz.process_user', @array)
}
proc _initUser() { export('evaquiz.process_user', array()) }

if (import('evaquiz.settime') == 0) { export('evaquiz.settime', time() + 1500000) }

proc _initQuiz(){
    export('evaquiz.status', 0)
    _initUser()
}

set_interval(1000, closure(){
    @prefix = '\ue4db §e§lQUIZ §r::'
    @air = '  '
    @rand = rand(1500000,1800000)
    if (import('evaquiz.status') == 2) {
        if (time() >= import('evaquiz.settime')) {
            broadcast(@prefix'끝! '.array_size(_getUser()).'명이 참여해주셨습니다.')
            export('evaquiz.settime', time() + @rand) // 25분 ~ 30분 (UNIX time with nano second)
            _initQuiz()
        }
    } else {
        if (time() >= import('evaquiz.settime')) {
            if (import('evaquiz.status') == 1) {
                export('evaquiz.settime', time() + @rand - 1000000) // 25분 ~ 30분 (UNIX time with nano second)
                _initQuiz()
                broadcast('')
                @type = import('evaquiz.question_type')
                if (@type == 'math'){
                    broadcast(@prefix.' '.import('evaquiz.question_math_message').' = '.import('evaquiz.question_answer'))
                } else if (@type == 'math2') {
                    broadcast(@prefix.' '.import('evaquiz.question_math_message'))
                } else if (@type == 'kor_hidden_word_match') {
                    broadcast(@prefix.' "§f'.import('evaquiz.question_answer').'§7"')
                }
                broadcast(@prefix'§7정답자가 없어 문제가 취소됩니다.')
                broadcast('')
                exit()
            }

            export('evaquiz.settime', time() + @rand)
            export('evaquiz.status', 1)

            switch(rand(1,9)) {
                case 1..3:
                    @chance = 1
                case 4..5:
                    @chance = 2
                case 6..7:
                    @chance = 3
                case 8..9:
                    @chance = 4
            }
            export('evaquiz.chance', @chance)

            if (@chance == 4) {
                @proverb = import('evaquiz.proverb.en')
                @cur_proverb = @proverb[array_rand(@proverb)[0]]

                @reward = rand(13,18)
                export('evaquiz.question_message', @cur_proverb)
                export('evaquiz.question_type', 'eng_typing_test')
                export('evaquiz.question_answer', @cur_proverb)
                export('evaquiz.reward', @reward)
                broadcast('§7§m----------------------------------')
                broadcast(@air '§o다음의 문장을 채팅창에 빠르게 입력하세요!')
                broadcast(@air '"§f§o'.@cur_proverb.'§7"')
                broadcast('§7§m----------------------------------')
            } else if (@chance == 3) {
                @proverb = import('evaquiz.proverb.ko')
                @cur_proverb = @proverb[array_rand(@proverb)[0]]

                @reward = rand(13,18)
                export('evaquiz.question_message', @cur_proverb)
                export('evaquiz.question_type', 'kor_typing_test')
                export('evaquiz.question_answer', @cur_proverb)
                export('evaquiz.reward', @reward)
                broadcast('§7§m----------------------------------')
                broadcast(@air '§o다음의 문장을 채팅창에 빠르게 입력하세요!')
                broadcast(@air '"§f§o'.@cur_proverb.'§7"')
                broadcast('§7§m----------------------------------')
            } else if (@chance == 2) {
                @proverb = import('evaquiz.proverb.ko')
                @cur_proverb = @proverb[array_rand(@proverb)[0]]
                @array_cur_proverb = split(' ', @cur_proverb)
                @length = ceil(divide(array_size(@array_cur_proverb), 4))
                @indexs = array_rand(@array_cur_proverb, @length)
                @answer = array()
                @length = 1 // 하나 고정
                for (assign(@i, 0), @i < @length, @i++) {
                    @cur = @array_cur_proverb[@indexs[@i]]
                    // @array_cur_proverb[@indexs[@i]] = reg_replace('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]', 'ㅁ', @cur)
                    // if(reg_count('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]', @cur) != length(@cur)) {
                    // }
                    @str = ''
                    @bo = false
                    
                    for (assign(@n, 0), @n < length(@cur), @n++) {
                        @cc = substr(@cur, @n, @n+1)
                        if (@cc != ',') {
                            @str = @str.'＃'
                        } else {
                            @str = @str.','
                            @bo = true
                        }
                    }

                    if (@bo) {
                        array_push(@answer, substr(@cur, 0, length(@cur) - 1))
                    } else {
                        array_push(@answer, @cur)
                    }
                    @array_cur_proverb[@indexs[@i]] = @str
                }

                // for (assign(@i, 0), @i < array_size(@array_cur_proverb), @i++) {
                //     @cur = @array_cur_proverb[@i].','
                //     msg('run' @cur reg_match_all('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]', @cur) reg_count('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]', @cur) length(@cur))
                //     @r_temp[@i] = reg_replace('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]', 'ㅁ', @cur)
                // }

                // msg(_chprefix('a')@array_cur_proverb)
                // msg(_chprefix('a')' 'split('\n', comp_read('proverb_ko.txt')))
                // msg(_chprefix('a')' 'all_materials())

                @message = ''
                foreach(@s in @array_cur_proverb) {
                    if (@s == ' ') {
                        continue();
                    }
                    @message = @message.' '.@s
                }
                // @answer_m = ''
                // foreach(@s in @answer) {
                //     @answer_m = @answer_m.' '.@s
                // }
                if (substr(@message, 0, 1) == ' ') {
                    @message = substr(@message, 1, length(@message))
                }
                @reward = rand(15,20)
                export('evaquiz.question_message', @message)
                export('evaquiz.question_type', 'kor_hidden_word_match')
                export('evaquiz.question_answer', @answer[0])
                export('evaquiz.reward', @reward)
                broadcast('§7§m----------------------------------')
                broadcast(@air '§o다음 중 ＃ 으로 가려진 문장을 채팅에 입력하세요!')
                broadcast(@air '"§f§o'.import('evaquiz.question_message').'§7"')
                broadcast('§7§m----------------------------------')
            } else {
                switch(rand(1,20)) {
                    case 1..2:
                        @math1 = rand(2,99)
                        @math2 = rand(0,99)
                        @reward = rand(3,8)
                        export('evaquiz.question_message', @math1.' + '.@math2.' = §6???')
                        export('evaquiz.question_math_message', @math1.' + '.@math2)
                        export('evaquiz.question_type', 'math')
                        export('evaquiz.question_answer', @math1 + @math2)
                        export('evaquiz.reward', @reward)
                    case 3..4:
                        @math1 = rand(20,99)
                        @math2 = rand(0,80)
                        @reward = rand(3,8)
                        if (@math1 < @math2) {
                            @temp = @math1
                            @math1 = @math2
                            @math2 = @temp
                        }
                        export('evaquiz.question_message', @math1.' - '.@math2.' = §6???')
                        export('evaquiz.question_math_message', @math1.' - '.@math2)
                        export('evaquiz.question_type', 'math')
                        export('evaquiz.question_answer', @math1 - @math2)
                        export('evaquiz.reward', @reward)
                    case 5..6:
                        @math1 = rand(1,12)
                        @math2 = rand(1,13)
                        @reward = rand(4,10)
                        export('evaquiz.question_message', @math1.' X '.@math2.' = §6???')
                        export('evaquiz.question_math_message', @math1.' X '.@math2)
                        export('evaquiz.question_type', 'math')
                        export('evaquiz.question_answer', @math1 * @math2)
                        export('evaquiz.reward', @reward)
                    case 7..8:
                        @math1 = rand(8,99)
                        @math2 = rand(1,9)
                        @reward = rand(5,10)
                        export('evaquiz.question_message', @math1.' ÷ '.@math2.' = §6???§7(자연수)')
                        export('evaquiz.question_math_message', @math1.' ÷ '.@math2)
                        export('evaquiz.question_type', 'math')
                        export('evaquiz.question_answer', integer(@math1 / @math2))
                        export('evaquiz.reward', @reward)
                    case 9..10:
                        @math1 = rand(9,26)
                        @math2 = rand(1,4)
                        @reward = rand(6,12)
                        export('evaquiz.question_message', @math1.' 의 '.@math2.' 제곱 = §6???')
                        export('evaquiz.question_math_message', @math1.' 의 '.@math2.' 제곱')
                        export('evaquiz.question_type', 'math')
                        export('evaquiz.question_answer', integer(pow(@math1,@math2))) // or **
                        export('evaquiz.reward', @reward)
                    case 11..12:
                        @math1 = rand(0,150)
                        @math2 = rand(0,200)
                        @math3 = rand(0,175)
                        @reward = rand(4,11)
                        export('evaquiz.question_message', @math1.' + '.@math2.' - '.@math3.' = §6???')
                        export('evaquiz.question_math_message', @math1.' + '.@math2.' - '.@math3)
                        export('evaquiz.question_type', 'math')
                        export('evaquiz.question_answer', @math1 + @math2 - @math3)
                        export('evaquiz.reward', @reward)
                    case 13..14:
                        @math1 = rand(2,99)
                        @math2 = rand(0,50)
                        @result = @math1 + @math2
                        @reward = rand(4,9)
                        export('evaquiz.question_message', @math1.' + §6??? §f= '.@result)
                        export('evaquiz.question_math_message', @math1.' + '.@math2.' = '.@result)
                        export('evaquiz.question_type', 'math2')
                        export('evaquiz.question_answer', @math2)
                        export('evaquiz.reward', @reward)
                    case 15..16:
                        @math1 = rand(2,99)
                        @math2 = rand(0,50)
                        @result = @math1 + @math2
                        @reward = rand(4,9)
                        export('evaquiz.question_message', '§6??? §f+ '.@math2.' = '.@result)
                        export('evaquiz.question_math_message', @math1.' + '.@math2.' = '.@result)
                        export('evaquiz.question_type', 'math2')
                        export('evaquiz.question_answer', @math1)
                        export('evaquiz.reward', @reward)
                    case 17..18:
                        @math1 = rand(3,13)
                        @math2 = rand(1,@math1)
                        @result = @math1 * @math2
                        @reward = rand(4,9)
                        export('evaquiz.question_message', '§6??? §f* '.@math2.' = '.@result)
                        export('evaquiz.question_math_message', @math1.' * '.@math2.' = '.@result)
                        export('evaquiz.question_type', 'math2')
                        export('evaquiz.question_answer', @math1)
                        export('evaquiz.reward', @reward)
                    case 19..20:
                        @math1 = rand(3,13)
                        @math2 = rand(0,@math1)
                        @result = @math1 * @math2
                        @reward = rand(4,9)
                        export('evaquiz.question_message', @math1.' * §6??? §f= '.@result)
                        export('evaquiz.question_math_message', @math1.' * '.@math2.' = '.@result)
                        export('evaquiz.question_type', 'math2')
                        export('evaquiz.question_answer', @math2)
                        export('evaquiz.reward', @reward)
                }
                broadcast('§7§m----------------------------------')
                broadcast(@air.'§f§o '.import('evaquiz.question_message'))
                broadcast('§7§m----------------------------------')
            }

            foreach(@player in all_players()) {
                play_named_sound(ploc(@player), array('sound': 'block.note_block.pling', 'pitch': 1.2), array(@player))
            }
			console('[AutoQuiz][Info] Answer : '.import('evaquiz.question_answer'))
        }
    }
})