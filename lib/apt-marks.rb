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
require 'apt-marks/error'
require 'apt-marks/logger'

module AptMarks
  MODULES = {}
  READERS = {}
  WRITERS = {}

  def self.load_modules
    marks_path = File.join File.dirname(__FILE__), 'apt-marks', 'syncers'
    Dir.foreach marks_path do |entry|
      path = File.join marks_path, entry

      if entry !~ /^\./ and File.stat(path).file? and entry =~ /\.rb$/
        require_path = path.sub %r{.*/(apt-marks/syncers/.*)\.rb$}, '\1'
        Logger.instance.debug "Loading module #{require_path}"
        require require_path
      end
    end

    Syncers.constants.map {|str| Syncers.const_get str } .
      find_all {|const| const.respond_to? :superclass } .
      find_all {|klass| klass.superclass == Syncers::Base } .
      each {|klass| MODULES[klass.label] = klass }

    MODULES.each_pair do |label, klass|
      READERS[label] = klass if klass.supports? :read
      WRITERS[label] = klass if klass.supports? :write
    end
  end

  def self.sync from, to
    reader_class = READERS[from]
    raise ArgumentError, "Not a reader: #{from}", caller unless reader_class

    writer_classes = to.map do |name|
      klass = WRITERS[name]
      raise ArgumentError, "Not a writer: #{name}", caller unless klass
      klass
    end

    reader = reader_class.new
    reader.read

    # Do not continue if the reader reported no automatic or manual packages.
    which = [:automatic, :manual].find {|m| reader.send(m).empty? }
    raise AptMarkSyncError, "#{from} reported no #{which} packages" if which

    writer_classes.each do |writer_class|
      writer = writer_class.new
      writer.automatic = reader.automatic
      writer.manual    = reader.manual
      writer.write
    end
  end
end

AptMarks.load_modules
