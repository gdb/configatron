# This is the root configatron object, and contains methods which
# operate on the entire configatron hierarchy.
class Configatron::KernelStore
  attr_reader :store

  def self.instance
    @instance ||= self.new
  end

  def initialize
    @locked = false
    reset!
  end

  def method_missing(name, *args, &block)
    store.send(name, *args, &block)
  end

  def reset!
    @store = Configatron::Store.new(self)
  end

  def temp(&block)
    temp_start
    yield
    temp_end
  end

  def temp_start
    @temp = Configatron::DeepClone.deep_clone(@store)
  end

  def temp_end
    @store = @temp
  end

  def locked?
    @locked
  end

  def lock!
    @locked = true
  end

  def unlock!
    @locked = false
  end
end

module Kernel
  def configatron
    Configatron::KernelStore.instance
  end
end
