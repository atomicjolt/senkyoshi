require "senkyoshi/models/content"
require "senkyoshi/models/module_item"

module Senkyoshi
  class Attachment < Content
    def iterate_xml(xml, pre_data)
      super
      @module_item = ModuleItem.new(
        @title,
        @module_type,
        @files.first.name,
        @url,
        @indent,
        @file_name,
      ).canvas_conversion
      self
    end

    def canvas_conversion(course, _resource)
      create_module(course)
    end
  end
end
