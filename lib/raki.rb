# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab & Martin Sigloch
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

    def config(*keys)
      @config = YAML.load(File.read("#{Rails.root}/config/raki.yml")) if @config.nil?
      requested_config = @config
      keys.each do |key,value|
        key = key.to_s
        return nil if requested_config[key].nil?
        requested_config = requested_config[key]
      end
      requested_config
    end

    def frontpage
      return config(:frontpage) unless config(:frontpage).nil?
      'Main'
    end

    def app_name
      return config(:app_name) unless config(:frontpage).nil?
      'Raki'
    end

    def userpage_type
      return config(:userpage_type) unless config(:userpage_type).nil?
      'user'
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
        @initialized_providers[type] = @providers[id.to_sym].new(config('providers', type.to_s))
      elsif !config('providers', 'default').nil?
        id = config('providers', 'default')['provider']
        @initialized_providers[type] = @providers[id.to_sym].new(config('providers', 'default'))
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
        @initialized_parsers[type] = @parsers[id.to_sym].new(config('parsers', type.to_s))
      elsif !config('parsers', 'default').nil?
        id = config('parsers', 'default')['parser']
        @initialized_parsers[type] = @parsers[id.to_sym].new(config('parsers', 'default'))
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
    
    def permissions
      if @permissions.nil?
        @permissions = YAML.load(File.read("#{Rails.root}/config/permissions.yml"))
        unless @permissions.key?(:OVERWRITE)
          @permissions[:OVERWRITE] = []
        end
      end
      @permissions
    end
    
    def permission?(type, page, action, user)
      perms = permissions[:ALL]
      if user.is_a?(AnonymousUser)
        perms = perms + permissions[:ANONYMOUS]
      elsif user.is_a?(User)
        perms = perms + permissions[:AUTHENTICATED]
      end
      perms = perms + permissions[:OVERWRITE]
      
      permissions.each do |u_key, rights|
        next if u_key.is_a?(Symbol)
        next if user.id.match("^#{u_key}$").nil?
        perms += rights
      end
      
      perm = false
      perms.each do |right|
        right = right.first
        next if "#{type.to_s}/#{page.to_s}".match("^#{right[0].gsub('*', '.*')}$").nil?
        rights = right[1].split(',')
        rights.map {|r| r.to_s.strip}
        perm = false if rights.include?("!#{action.to_s}")
        perm = true if rights.include?(action.to_s)
      end
      
      perm
    end
    
    def add_permission_overwrite(type, page, rights)
      rights = [rights] unless rights.is_a?(Array)
      rights.map {|r| r.to_s.strip}
      permissions[:OVERWRITE] << {"#{type.to_s}/#{page.to_s}" => rights.join(',')}
    end

  end
end
