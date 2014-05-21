require 'pp'
require 'readline'

module Shiritori
  class Main
    attr_reader :current_object, :chain_count
    include SearchMethod
    include View

    RED = 31
    GREEN = 32

    EXIT_PATTERN = /\A(exit|quit)\Z/.freeze
    METHOD_PATTERN = /[\w|\?|\>|\<|\=|\!|\[|\[|\]|\*|\/|\+|\-|\^|\~|\@|\%|\&|]+/.freeze

    def start(option = [])
      init
      run
    end

    def update(result = nil)
      if result
        @all_method.delete(result.first)
        @current_object = result.last
        @chain_count += 1
      end

      begin
        @current_class = @current_object.class
      rescue Exception => ex
        @current_class = "Undefined"
      end

      @success = true
    end

    def init
      @all_method = get_all_method
      @current_object = nil
      @current_class = Object
      @current_chain = []
      @chain_count = 0
      @success = false

      loop do

        command = get_command

        begin 
          @current_object = eval(command.chomp)
          @current_chain << @current_object.to_ss
          @success = true
          break
        rescue Exception => ex
          new_line
          puts "\e[#{RED}mUndefined object error\e[m"
          redo
        end
      end

      update
    end

    def success?
      @success
    end

    def get_command
      if Shiritori.env == :development
        print "Please input first object > "
        $stdin.gets
      else
        Readline.readline("Please input first object > ", true)
      end
    end

    def run

      loop do
        show_status

        if success?
          puts "\e[#{GREEN}mSuccess!\e[m"
          @success = false
        else
          puts "\e[#{RED}mFailed!\e[m"
        end

        new_line

        command = get_command

        break if command.nil?
        redo if command.blank?

        command = command.chomp.sub(/^\./,"")

        puts "Exec command #{[@current_object.to_ss, command].join('.')}"

        begin
          if result = exec_method_chain(command, @current_object)
            if @all_method.include?(result.first)
              update(result)
              @current_chain << command
            elsif result.first == :exit
              break
            else
              puts "Already used method."
            end
          end
        rescue Exception => ex
          puts "\e[#{RED}m#{ex.message}\e[m"
        end
      end
    end

    def exec_method_chain(command, object)
      method_name = command.scan(METHOD_PATTERN).first.to_sym
      result = [ method_name ]

      # puts debug
      # Bignumがエラーが出る
      # puts "Exec command #{[object.to_ss, command].join('.')}"
      # p method_name
      # history 機能
      # 時間制限はつける
      # メモリ制限もつける
      # hard modeの追加

      case command
      when EXIT_PATTERN
        return [:exit]
      else
        begin
          Thread.new do
            raise NoMethodError unless object.respond_to?(method_name)

            #result << object.instance_eval{ eval("self."+command) }
            result << eval("object."+command)
          end.join
        rescue Exception => ex
          puts ex.message
          return false
        end
      end

      result
    end
  end
end
