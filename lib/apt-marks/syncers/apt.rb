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

require 'apt-marks/logger'
require 'apt-marks/syncers/base'
require 'apt-marks/utils'

module AptMarks
  module Syncers
    class Apt < Base
      STATE_FILE = '/var/lib/apt/extended_states'

      needs_file STATE_FILE

      define_action :read do
        installed = Utils.installed_packages

        open STATE_FILE do |io|
          cur = { }

          io.each do |line|
            line.chomp!
            if line == ''
              if cur['Package'] and cur['Auto-Installed'] == '1'
                if installed.include? cur['Package']
                  @automatic << cur['Package']
                end
              end

              cur = { }

            else
              key, val = line.split /: /, 2
              cur[key] = val
            end
          end
        end

        @manual = installed - @automatic
      end

      define_action :write do
        Tempfile.open_auto_rename STATE_FILE do |io|
          @automatic.each do |pkg|
            io.puts "Package: #{pkg}",
              "Auto-Installed: 1",
              ""
          end
          # Listing the @manual packages with Auto-Installed: 0 is redundant,
          # since apt considers Auto-Installed: 0 to be the default for all
          # packages, but it doesn't hurt.
          @manual.each do |pkg|
            io.puts "Package: #{pkg}",
              "Auto-Installed: 0",
              ""
          end
        end
      end
    end
  end
end
