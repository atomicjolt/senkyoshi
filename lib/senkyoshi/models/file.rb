# Copyright (C) 2016, 2017 Atomic Jolt

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "senkyoshi/models/resource"
require "senkyoshi/exceptions"

module Senkyoshi
  class SenkyoshiFile < Resource
    attr_accessor(:xid, :location, :path)

    FILE_BLACKLIST = [
      "*.dat",
    ].freeze

    def initialize(zip_entry)
      begin
        entry_name = zip_entry.name.encode("UTF-8")
      rescue Encoding::UndefinedConversionError
        entry_name = zip_entry.name.force_encoding("UTF-8")
      end

      @path = strip_xid entry_name
      @location = extract_file(zip_entry) # Location of file on local filesystem

      base_name = File.basename(entry_name)
      @xid = base_name[/__(xid-[0-9]+_[0-9]+)/, 1] ||
        Senkyoshi.create_random_hex
    end

    def matches_xid?(xid)
      @xid == xid
    end

    def extract_file(entry)
      @dir ||= Dir.mktmpdir

      name = "#{@dir}/#{entry.name}"
      path = File.dirname(name)
      FileUtils.mkdir_p path unless Dir.exist? path
      entry.extract(name)
      name
    end

    def canvas_conversion(course, _resources = nil)
      file = CanvasCc::CanvasCC::Models::CanvasFile.new
      file.identifier = @xid
      file.file_location = @location
      file.file_path = @path
      file.hidden = false

      course.files << file
      course
    end

    ##
    # Remove temporary files
    ##
    def cleanup
      FileUtils.rm_r @dir unless @dir.nil?
    end

    ##
    # Determine if a file is on the blacklist
    ##
    def self.blacklisted?(file)
      FILE_BLACKLIST.any? { |list_item| File.fnmatch?(list_item, file.name) }
    end

    ##
    # Determine whether or not a file is a metadata file or not
    ##
    def self.metadata_file?(entry_names, file)
      if File.extname(file.name) == ".xml"
        # Detect and skip metadata files.
        non_meta_file = File.join(
          File.dirname(file.name),
          File.basename(file.name, ".xml"),
        )

        entry_names.include?(non_meta_file)
      else
        false
      end
    end

    ##
    # Determine whether or not a file is a part of a scorm package
    ##
    def self.belongs_to_scorm_package?(package_paths, file)
      package_paths.any? do |path|
        File.dirname(file.name).start_with? path
      end
    end

    ##
    # Determine if a file should be included in course files or not
    ##
    def self.valid_file?(entry_names, scorm_paths, file)
      return false if SenkyoshiFile.blacklisted? file
      return false if SenkyoshiFile.metadata_file? entry_names, file
      return false if SenkyoshiFile.belongs_to_scorm_package? scorm_paths, file
      true
    end
  end
end
