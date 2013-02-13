base = File.join(File.dirname(__FILE__), 'configatron')
require 'yamler'
require 'fileutils'
require File.join(base, 'configatron')
require File.join(base, 'store')
require File.join(base, 'errors')
require File.join(base, 'rails')
require File.join(base, 'proc')

class Configatron
  # Call if you want to monkey-patch the language with some
  # convenience methods.
  def self.monkey_patch!
    base = File.join(File.dirname(__FILE__), 'configatron')

    require File.join(base, 'core_ext', 'object')
    require File.join(base, 'core_ext', 'string')
    require File.join(base, 'core_ext', 'class')
  end
end

# Provides access to the Configatron storage system.
def configatron
  Configatron.instance
end
