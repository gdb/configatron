require 'forwardable'

class Configatron
  class Store
    extend ::Forwardable

    def initialize(root_store, name='configatron')
      @root_store = root_store
      @name = name

      @attributes = {}
    end

    def [](key)
      val = fetch(key.to_sym) do
        if @root_store.locked?
          raise Configatron::UndefinedKeyError.new("Key not found: #{key} (for locked #{self})")
        end
        Configatron::Store.new(@root_store, "#{@name}.#{key}")
      end
      return val
    end

    def store(key, value)
      if @root_store.locked?
        raise Configatron::LockedError.new("Cannot set key #{key} for locked #{self}")
      end
      @attributes[key.to_sym] = value
    end

    def fetch(key, default_value = nil, &block)
      val = @attributes[key.to_sym]
      if val.nil?
        if block_given?
          val = block.call
        elsif default_value
          val = default_value
        end
        store(key, val)
      end
      if val.is_a?(Configatron::Proc)
        val = val.call
      end
      return val
    end

    def key?(key)
      @attributes.key?(key.to_sym)
    end

    def configure_from_hash(hash)
      hash.each do |key, value|
        if value.is_a?(Hash)
          self[key].configure_from_hash(value)
        else
          store(key, value)
        end
      end
    end

    def to_s
      @name
    end

    def inspect
      f_out = []
      @attributes.each do |k, v|
        if v.is_a?(Configatron::Store)
          v.inspect.each_line do |line|
            if line.match(/\n/)
              line.each_line do |l|
                l.strip!
                f_out << l
              end
            else
              line.strip!
              f_out << line
            end
          end
        else
          f_out << "#{@name}.#{k} = #{v.inspect}"
        end
      end
      f_out.compact.sort.join("\n")
    end

    def method_missing(name, *args, &block)
      # Needed to allow 'puts'ing of a configatron.
      if name == :to_ary
        raise NoMethodError.new("Called :to_ary")
      end

      # In case of Configatron bugs, prevent method_missing infinite
      # loops.
      if @method_missing
        raise NoMethodError.new("Bug in configatron; ended up in method_missing while running: #{name.inspect}")
      end
      @method_missing = true
      do_lookup(name, *args, &block)
    ensure
      @method_missing = false
    end

    private

    def do_lookup(name, *args, &block)
      if block
        yield self[name]
      else
        name = name.to_s
        if /(.+)=$/.match(name)
          return store($1, args[0])
        elsif /(.+)!/.match(name)
          key = $1
          if self.has_key?(key)
            return self[key]
          else
            raise Configatron::UndefinedKeyError.new($1)
          end
        else
          return self[name]
        end
      end
    end

    alias :[]= :store
    alias :has_key? :key?

    def_delegator :@attributes, :values
    def_delegator :@attributes, :keys
    def_delegator :@attributes, :each
    def_delegator :@attributes, :to_h
    def_delegator :@attributes, :to_hash
    def_delegator :@attributes, :delete
    # def_delegator :@attributes, :fetch
    # def_delegator :@attributes, :has_key?
    # def_delegator :$stdout, :puts

  end
end
