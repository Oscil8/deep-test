module DeepTest
  class TestTask
    attr_accessor :requires

    def initialize(name = :deep_test)
      @requires = []
      @name = name
      @options = Options.new({})
      self.pattern = "test/**/*_test.rb"
      yield self if block_given?
      define
    end
    
    def define
      desc "Run '#{@name}' suite using DeepTest"
      task @name do
        require_options = requires.map {|f| "-r#{f}"}.join(" ")
        ruby "#{require_options} #{runner} '#{@options.to_command_line}'"
      end
    end

    Options::VALID_OPTIONS.each do |option|
      eval <<-end_src
        def #{option.name}
          @options.#{option.name}
        end

        def #{option.name}=(value)
          @options.#{option.name} = value
        end
      end_src
    end

    def pattern=(pattern)
      @options.pattern = Dir.pwd + "/" + pattern
    end

  private

    def runner
      File.expand_path(File.dirname(__FILE__) + "/../../script/internal/run_test_suite.rb")
    end    
  end
end
