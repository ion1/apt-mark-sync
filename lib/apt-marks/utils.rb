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

require 'tempfile'
require 'fileutils'

require 'apt-marks/error'

module AptMarks
  module Utils
    def self.installed_packages
      unless @installed_packages
        @installed_packages = []

        popen 'dpkg --get-selections' do |io|
          io.each do |line|
            pkg, status = line.split
            @installed_packages << pkg if status == 'install'
          end
        end

        @installed_packages.sort!
      end

      @installed_packages
    end

    def self.verify_exit_status cmd
      ret = nil
      ret = yield if block_given?

      if $?.nil?
        raise AptMarkSyncError, "No exit status for command '#{cmd}'", caller

      elsif $?.exitstatus != 0
        msg =  "Command '#{cmd}' failed"
        msg << " with status #{$?.exitstatus}" unless $?.exitstatus.nil?
        raise AptMarkSyncError, msg, caller
      end

      ret
    end

    # Wrapper for IO.popen that verifies the exit status. Note that it requires
    # the use of a block.
    def self.popen cmd, mode='r'
      raise ArgumentError, "No block given", caller unless block_given?

      ret = IO.popen cmd, mode do |io|
        yield io
      end
      verify_exit_status cmd
      ret
    end

    # Wrapper for Kernel.system that verifies the exit status.
    def self.system *cmd
      ret = Kernel.system *cmd
      verify_exit_status cmd.join(' ')
      ret
    end

  end
end

class << Tempfile
  # open_auto_rename opens a temporary file for writing, executes the block,
  # and on success renames the temporary file as the intended file.
  def open_auto_rename filename
    path = File.expand_path filename
    stat = File.stat path rescue nil
    ret  = nil

    self.open path, '' do |io|
      ret = yield io
      if stat
        io.chmod stat.mode rescue nil
        io.chown stat.uid, stat.gid rescue nil
      end
      io.close
      FileUtils.mv io.path, path
    end

    ret
  end
end
