module OptStruct
  module ClassMethods
    def inherited(subclass)
      instance_variables.each do |v|
        ivar = instance_variable_get(v)
        subclass.send(:instance_variable_set, v, ivar.dup) if ivar
      end
    end

    def required_keys
      @required_keys ||= []
    end

    def required(*keys)
      required_keys.concat keys
      option_accessor *keys
    end

    def option_reader(*keys)
      keys.each do |key|
        define_method(key) { options[key] }
      end
    end

    def option_writer(*keys)
      keys.each do |key|
        define_method("#{key}=") { |value| options[key] = value }
      end
    end

    def option_accessor(*keys)
      check_reserved_words(keys)
      option_reader *keys
      option_writer *keys
    end

    def option(key, default = nil, **options)
      default = options[:default] if options.key?(:default)
      defaults[key] = default
      required_keys << key if options[:required]
      option_accessor key
    end

    def options(*keys, **keys_defaults)
      option_accessor *keys if keys.any?
      if keys_defaults.any?
        defaults.merge!(keys_defaults)
        option_accessor *(keys_defaults.keys - expected_arguments)
      end
    end

    def defaults
      @defaults ||= {}
    end

    def expect_arguments(*arguments)
      required(*arguments)
      expected_arguments.concat(arguments)
    end
    alias_method :expect_argument, :expect_arguments

    def expected_arguments
      @expected_arguments ||= []
    end

    def init(meth = nil, &blk)
      add_callback(:init, meth || blk)
    end
    alias_method :after_init, :init

    def before_init(meth = nil, &blk)
      add_callback(:before_init, meth || blk)
    end

    def around_init(meth = nil, &blk)
      add_callback(:around_init, meth || blk)
    end

    def add_callback(name, callback)
      @_callbacks ||= {}
      @_callbacks[name] ||= []
      @_callbacks[name] << callback
    end

    def all_callbacks
      @_callbacks
    end

    private

    RESERVED_WORDS = %i(class defaults options fetch check_required_args check_required_keys)

    def check_reserved_words(words)
      Array(words).each do |word|
        if RESERVED_WORDS.member?(word)
          raise ArgumentError, "Use of reserved word is not permitted: #{word.inspect}"
        end
      end
    end
  end
end
