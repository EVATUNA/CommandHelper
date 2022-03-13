proc _getUser() { return(import('evaquiz.process_user')) }

proc _addUser(@value){
  @array = import('evaquiz.process_user')
  array_push(@array, @value)
  export('evaquiz.process_user', @array)
}

proc _initUser() { export('evaquiz.process_user', array()) }

proc _autoquiz_init(@init_time) {

  # 오토퀴즈 데이터
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
  # 참여 유저 관리
  export('evaquiz.process_user', array())

  #시간
  if (import('evaquiz.settime') == 0) { export('evaquiz.settime', time() + @init_time ) }
}
_autoquiz_init(1500000)

# 상태
proc _initQuiz(){
  export('evaquiz.status', 0)
  _initUser()
}

register_command('newquiz', array(
  permission: 'newquiz',
  'executor': closure(@cmd, @player, @args) {
    _autoquiz_init(1000)
  }
))

proc _autoquiz(@server) {
  @prefix = ''
  @air = '  '
  @rand = rand(1500000,1800000)
  if (import('evaquiz.status') == 2) {
    if (time() >= import('evaquiz.settime')) {
      _tunabot_broadcast('끝! '.array_size(_getUser()).'명이 참여해주셨습니다.', @server)
      export('evaquiz.settime', time() + @rand) // 25분 ~ 30분 (UNIX time with nano second)
      _initQuiz()
    }
  } else {
    if (time() >= import('evaquiz.settime')) {
      @is_failed = false
      if (import('evaquiz.status') == 1) {
        export('evaquiz.settime', time() + @rand - 1000000) // 25분 ~ 30분 (UNIX time with nano second)
        _initQuiz()

        @is_failed = true
        
        _tunabot_broadcast('아쉽게도 아무도 성공하지 못했네요.', @server)

        @type = import('evaquiz.question_type')
        if (@type == 'math') {
          @question = import('evaquiz.question_math_message')
          @answer = import('evaquiz.question_answer')
          set_timeout(1000, closure() {
            _tunabot_broadcast("깜짝 수학 퀴즈의 정답은 @question = @answer 이였습니다.", @server)
          })
        } else if (@type == 'math2') {
          @question = import('evaquiz.question_math_message')
          @answer = import('evaquiz.question_answer')
          set_timeout(1000, closure() {
            _tunabot_broadcast("깜짝 수학 퀴즈의 정답은 @question 이였습니다.", @server)
          })
        } else if (@type == 'kor_hidden_word_match') {
          @question = import('evaquiz.question_math_message')
          @answer = import('evaquiz.question_answer')
          set_timeout(1000, closure() {
            _tunabot_broadcast("깜짝 문장 퀴즈의 정답은 \"@answer\" 이였습니다.", @server)
          })
        }
        
        set_timeout(2000, closure() {
          _tunabot_broadcast('다른 문제를 내볼게요!', @server)
        })
        //exit()
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
        
        if(!@is_failed) {
          _tunabot_broadcast('깜짝 문장 입력!! 성공 시 보상을 드려요!!', @server)
        }

        set_timeout(3000, closure() {
          _tunabot_broadcast('다음 문장을 빠르게 입력하세요!', @server)
        })

        set_timeout(5000, closure() {
          _tunabot_broadcast('"'.@cur_proverb.'"', @server)
        })
      } else if (@chance == 3) {
        @proverb = import('evaquiz.proverb.ko')
        @cur_proverb = @proverb[array_rand(@proverb)[0]]

        @reward = rand(13,18)
        export('evaquiz.question_message', @cur_proverb)
        export('evaquiz.question_type', 'kor_typing_test')
        export('evaquiz.question_answer', @cur_proverb)
        export('evaquiz.reward', @reward)

        if(!@is_failed) {
          _tunabot_broadcast('깜짝 문장 입력!! 성공 시 보상을 드려요!!', @server)
        }

        set_timeout(3000, closure() {
          _tunabot_broadcast('다음 문장을 빠르게 입력하세요!', @server)
        })

        set_timeout(5000, closure() {
          _tunabot_broadcast('"'.@cur_proverb.'"', @server)
        })
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
        //   @cur = @array_cur_proverb[@i].','
        //   msg('run' @cur reg_match_all('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]', @cur) reg_count('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]', @cur) length(@cur))
        //   @r_temp[@i] = reg_replace('[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]', 'ㅁ', @cur)
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
        //   @answer_m = @answer_m.' '.@s
        // }
        if (substr(@message, 0, 1) == ' ') {
          @message = substr(@message, 1, length(@message))
        }
        @reward = rand(15,20)
        export('evaquiz.question_message', @message)
        export('evaquiz.question_type', 'kor_hidden_word_match')
        export('evaquiz.question_answer', @answer[0])
        export('evaquiz.reward', @reward)

        if(!@is_failed) {
          _tunabot_broadcast('깜짝 문장 퀴즈!! 성공 시 보상을 드려요!!', @server)
        }

        set_timeout(3000, closure() {
          _tunabot_broadcast('다음 ＃ 으로 가려진 문장을 빠르게 맞추세요!', @server)
        })

        set_timeout(5000, closure() {
          _tunabot_broadcast('"'.import('evaquiz.question_message').'"', @server)
        })
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

        if(!@is_failed) {
          _tunabot_broadcast('깜짝 수학 퀴즈!! 성공 시 보상을 드려요!!', @server)
        }

        set_timeout(3000, closure() {
          _tunabot_broadcast('다음 수식의 §6???§f를 빠르게 맞추세요!', @server)
        })

        set_timeout(5000, closure() {
          _tunabot_broadcast(import('evaquiz.question_message'), @server)
        })
      }

      //foreach(@player in all_players()) {
      //  play_named_sound(ploc(@player), array('sound': 'block.note_block.pling', 'pitch': 1.2), array(@player))
      //}
			//console('[AutoQuiz][Info] Answer : '.import('evaquiz.question_answer'))
    }
  }
}