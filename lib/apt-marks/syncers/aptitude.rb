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
    class Aptitude < Base
      needs_command 'aptitude'

      define_action :read do
        Utils.popen "aptitude search -F '%p# %M' '~i'" do |io|
          io.each do |line|
            pkg, auto = line.split
            if auto
              @automatic << pkg
            else
              @manual    << pkg
            end
          end
        end
      end

      define_action :write do
        # Using xargs in case the parameter list is too long.
        Utils.popen 'xargs -0r aptitude --schedule-only install', 'w' do |io|
          @automatic.each {|pkg| io << "#{pkg}+M\000" }
          @manual.each    {|pkg| io << "#{pkg}+\000" }
        end
      end
    end
  end
end
