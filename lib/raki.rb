# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module Raki
  class << self

    class RakiError < StandardError
    end

    attr_reader :controller
    
    def init(controller)
      @controller = controller
    end

    def config(*keys)
      @config = YAML.load(File.read("#{Rails.root}/config/raki.yml")) if @config.nil?
      @requested_config = @config
      keys.each do |key,value|
        return nil if @requested_config[key].nil?
        @requested_config = @requested_config[key]
      end
      @requested_config
    end

    def frontpage
      return config[:frontpage] unless config[:frontpage].nil?
      'Main'
    end

    def app_name
      return config[:app_name] unless config[:app_name].nil?
      'Raki'
    end

    def version
      '0.1pre'
    end

    def register_provider(id, clazz)
      @providers = {} if @providers.nil?
      @providers[id] = clazz
    end

    def providers
      @providers
    end

    def provider(type)
      @initialized_providers = {} if @initialized_providers.nil?
      if @initialized_providers.key?(type)
        return @initialized_providers[type]
      elsif !config('providers', type.to_s).nil?
        id = config('providers', type.to_s)['provider']
        @initialized_providers[type] = @providers[id.to_sym].new(provider_params(type))
      elsif !config('providers', 'default').nil?
        id = config('providers', 'default')['provider']
        @initialized_providers[type] = @providers[id.to_sym].new(provider_params(:default))
      else
        raise RakiError.new("No Provider")
      end
      @initialized_providers[type]
    end

    def register_parser(id, clazz)
      @parsers = {} if @parsers.nil?
      @parsers[id] = clazz
    end

    def parsers
      @parsers
    end

    def parser(type)
      @initialized_parsers = {} if @initialized_parsers.nil?
      if @initialized_parsers.key?(type)
        return @initialized_parsers[type]
      elsif !config('parsers', type.to_s).nil?
        id = config('parsers', type.to_s)['parser']
        @initialized_parsers[type] = @parsers[id.to_sym].new(parser_params(type))
      elsif !config('parsers', 'default').nil?
        id = config('parsers', 'default')['parser']
        @initialized_parsers[type] = @parsers[id.to_sym].new(parser_params(:default))
      else
        raise RakiError.new("No Parser")
      end
      @initialized_parsers[type]
    end

    def register_authenticator(id, clazz)
      @authenticators = {} if @authenticators.nil?
      @authenticators[id] = clazz
    end

    def authenticators
      @authenticators
    end

    def authenticator
      if @authenticator.nil?
        id = config('authenticator')
        raise RakiError.new("No Authenticator") if id.nil?
        @authenticator = @authenticators[id.to_sym].new
      end
      @authenticator
    end

    private

    def provider_params(type)
      c = config('providers', type.to_s)
      c.delete('provider')
      c
    end

    def parser_params(type)
      c = config('parsers', type.to_s)
      c.delete('parser')
      c
    end

  end
end
