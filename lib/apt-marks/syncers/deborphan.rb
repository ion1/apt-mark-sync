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

require 'apt-marks/syncers/base'
require 'apt-marks/utils'

module AptMarks
  module Syncers
    class Deborphan < Base
      needs_command 'deborphan'

      define_action :read do
        installed = Utils.installed_packages

        Utils.popen('deborphan -L') do |io|
          io.each do |pkg|
            pkg.chomp!
            @manual << pkg if installed.include? pkg
          end
        end

        @automatic = installed - @manual
      end

      define_action :write do
        Utils.popen('deborphan -Z -A -', 'w') do |io|
          @manual.each {|pkg| io.puts pkg }
        end
      end
    end
  end
end
