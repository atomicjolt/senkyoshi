require "blacklight/models/group"
require "blacklight/models/course"
require "blacklight/models/blog"
require "blacklight/models/announcement"
require "blacklight/models/forum"
require "blacklight/models/file"
require "blacklight/models/content"
require "blacklight/models/scorm_package"
require_relative "exceptions"

module Blacklight
  RESOURCE_TYPE = {
    groups: "Group",
    blog: "Blog",
    # announcement: "Announcement",
    forum: "Forum",
    course: "Course",
    content: "Content"

    # categories: :iterate_categories,
    # itemcategories: :iterate_itemcategories,
    # questestinterop: :iterate_questestinterop,
    # staffinfo: :iterate_staffinfo,
    # coursemodulepages: :iterate_coursemodulepages,
    # content: :iterate_content,
    # groupcontentlist: :iterate_groupcontentlist,
    # learnrubrics: :iterate_learnrubrics,
    # gradebook: :iterate_gradebook,
    # courseassessment: :iterate_courseassessment,
    # collabsessions: :iterate_collabsessions,
    # link: :iterate_link,
    # cms_resource_link_list: :iterate_resource_link_list,
    # courserubricassociations: :iterate_courserubricassociations,
    # partentcontextinfo: :iterate_parentcontextinfo,
    # notificationrules: :iterate_notificationrules,
    # wiki: :iterate_wiki,
    # safeassign: :iterate_safeassign,
  }.freeze

  SCORM_SCHEMA = "adlscorm"

  def self.parse_manifest(zip_file, manifest)
    doc = Nokogiri::XML.parse(manifest)
    resources = doc.xpath("//*[resource]")
    iterate_xml(resources, zip_file)
  end

  def self.iterate_xml(resources, zip_file)
    resources_array = []
    resources[0].children.each do |resource|
      file_name = resource.attributes["file"].value
      data_file = Blacklight.open_file(zip_file, file_name)
      data = Nokogiri::XML.parse(data_file)
      xml_data = data.children.first
      type = xml_data.name.downcase
      if RESOURCE_TYPE[type.to_sym]
        resource_type = "Blacklight::" + RESOURCE_TYPE[type.to_sym]
        res_class = resource_type.split("::").
          reduce(Object) { |o, c| o.const_get c }
        resource = res_class.new
        resources_array.push(resource.iterate_xml(xml_data))
      end
    end
    resources_array - ["", nil]
  end

  def self.add_files(zip_file)
    resources_array = []
    zip_file.entries.each do |entry|
      resources_array.push(BlacklightFile.new(entry))
    end

    resources_array
  end

  def scorm_manifest?(manifest)
    parsed_manifest = Nokogiri::XML(manifest.get_input_stream.read)
    schema_name = parsed_manifest.
      xpath("//xmlns:metadata/xmlns:schema").
      text.delete(" ").downcase
    schema_name == SCORM_SCHEMA
  end

  def self.find_scorm_manifests(zip_file)
    zip_file.
      entries.select do |e|
        File.fnmatch("imsmanifest.xml", e.name) && scorm_manifest?(e)
      end
  end

  def self.add_scorm(zip_file)
    find_scorm_manifests(zip_file).map do |package|
      ScormPackage.new package
    end
  end

  def self.create_random_hex
    SecureRandom.hex
  end

  def self.get_attribute_value(xml_data, type)
    value = ""
    if xml_data.children.at(type).attributes["value"]
      value = xml_data.children.at(type).attributes["value"].value
    end
    value
  end

  def self.get_text(xml_data, type)
    value = ""
    if xml_data.children.at(type)
      value = xml_data.children.at(type).text
    end
    value
  end

  def self.get_description(xml_data)
    value = ""
    if xml_data.children.at("DESCRIPTION")
      value = xml_data.children.at("DESCRIPTION").text
    end
    value
  end
end
