# apt-mark-sync – synchronize ‘automatically installed’ field between programs
# Copyright © 2007  Johan Kiviniemi
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

require 'apt-marks/error'
require 'apt-marks/logger'

module AptMarks
  module Syncers
    class Base
      VALID_ACTIONS = [:read, :write].freeze

      attr_accessor :automatic, :manual

      private

      def self.actions
        @actions ||= { }
      end

      def self.define_action action, &block
        unless VALID_ACTIONS.include? action
          raise ArgumentError, "Invalid action #{arg.inspect}", caller
        end

        actions[action] = block
      end

      def self.needs_command cmd
        path = ENV['PATH'].split ':'
        unless path.find {|dir| File.exists? File.join(dir, cmd) }
          @deps_fulfilled = false
        end
      end

      def self.needs_file file
        @deps_fulfilled = false unless File.exists? file
      end

      public

      def self.supports? action
        @deps_fulfilled != false and actions.has_key? action
      end

      def self.label
        to_s .                          # 'AptMarks::Syncers::FooBar'
          sub(/.*\::/, '') .            # 'FooBar'
          split(/(?=[A-Z])/) .          # ['Foo', 'Bar']
          map {|part| part.downcase } . # ['foo', 'bar']
          join('-')                     # 'foo-bar'
      end

      def initialize
        @automatic = nil
        @manual    = nil
      end

      def read
        if self.class.supports? :read
          Logger.instance.info "Reading: #{self.class.label}"

          @automatic = []
          @manual    = []

          instance_eval &self.class.actions[:read]

          @automatic.sort!
          @manual.sort!

        else
          raise NotImplementedError,
            "#{self.class} does not implement read",
            caller
        end

        self
      end

      def write
        if self.class.supports? :write
          Logger.instance.info "Writing: #{self.class.label}"

          if @automatic and @manual
            instance_eval &self.class.actions[:write]
          else
            raise AptMarkSyncError, "Package lists not defined", caller
          end

        else
          raise NotImplementedError,
            "#{self.class} does not implement write",
            caller
        end

        self
      end

    end
  end
end
