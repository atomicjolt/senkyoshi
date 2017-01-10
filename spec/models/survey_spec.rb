require "minitest/autorun"
require "senkyoshi"
require "pry"

require_relative "../helpers.rb"

include Senkyoshi

describe Senkyoshi do
  describe "Survey" do
    before do
      @survey = Survey.new
      @resources = Senkyoshi::Collection.new
    end

    describe "initialize" do
      it "should initialize survey" do
        assert_equal (@survey.is_a? Senkyoshi::Survey), true
      end
    end

    describe "iterate_xml" do
      it "should iterate through xml" do
        xml = get_fixture_xml "survey.xml"
        pre_data = {}
        @survey = @survey.iterate_xml(xml.children.first, pre_data)

        title = "Just a test"
        points_possible = "120.0"
        group_name = "Survey"
        quiz_type = "graded_survey"
        description = "<p>Do this test with honor</p>"
        instructions = "<p>Don't forget your virtue</p>"

        assert_equal (@survey.instance_variable_get :@title), title
        assert_equal quiz_type,
                     (@survey.instance_variable_get :@quiz_type)
        assert_equal (@survey.
          instance_variable_get :@points_possible), points_possible
        assert_equal (@survey.
          instance_variable_get :@group_name), group_name
        assert_equal (@survey.instance_variable_get :@items).count, 12

        actual_description = @survey.instance_variable_get :@description
        assert_includes actual_description, description
        assert_includes actual_description, instructions
      end
    end

    describe "canvas_conversion" do
      it "should create a canvas survey" do
        xml = get_fixture_xml "survey.xml"
        pre_data = {}
        @survey = @survey.iterate_xml(xml.children.first, pre_data)

        course = CanvasCc::CanvasCC::Models::Course.new
        @survey.canvas_conversion(course, @resources)
        assert_equal course.assessments.count, 1
      end
    end

    describe "setup_assessment" do
      it "should return survey with details" do
        xml = get_fixture_xml "survey.xml"
        pre_data = {}
        @survey = @survey.iterate_xml(xml.children.first, pre_data)
        assessment = CanvasCc::CanvasCC::Models::Assessment.new

        title = "Just a test"
        description = "<p>Do this test with honor</p>"
        instructions = "<p>Don't forget your virtue</p>"

        assignment = @survey.create_assignment
        assessment =
          @survey.setup_assessment(assessment, assignment, @resources)
        assert_equal assessment.title, title
        assert_includes assessment.description, description
        assert_includes assessment.description, instructions
      end
    end

    describe "create_items" do
      it "should create items" do
        xml = get_fixture_xml "survey.xml"
        pre_data = {}
        @survey = @survey.iterate_xml(xml.children.first, pre_data)
        course = CanvasCc::CanvasCC::Models::Course.new
        assessment = CanvasCc::CanvasCC::Models::Assessment.new

        assessment = @survey.create_items(course, assessment, @resources)
        assert_equal assessment.items.count, 12
      end
    end

    describe "create_assignment_group" do
      it "should create assignment groups in course" do
        xml = get_fixture_xml "survey.xml"
        pre_data = {}
        @survey = @survey.iterate_xml(xml.children.first, pre_data)
        course = CanvasCc::CanvasCC::Models::Course.new

        course = @survey.create_assignment_group(course, @resources)
        assert_equal course.assignment_groups.count, 1
      end
    end

    describe "create_assignment" do
      it "should create an assignment" do
        xml = get_fixture_xml "survey.xml"
        pre_data = {}
        quiz_type = "graded_survey"
        @survey = @survey.iterate_xml(xml.children.first, pre_data)

        assignment = @survey.create_assignment
        assert_equal assignment.title,
                     (@survey.instance_variable_get :@title)
        assert_equal quiz_type,
                     (@survey.instance_variable_get :@quiz_type)
        assert_equal assignment.assignment_group_identifier_ref,
                     (@survey.instance_variable_get :@group_id)
        assert_equal assignment.workflow_state,
                     (@survey.instance_variable_get :@workflow_state)
        assert_equal assignment.points_possible,
                     (@survey.instance_variable_get :@points_possible)
        assert_equal assignment.position, 1
        assert_equal assignment.grading_type, "points"
        assert_equal assignment.submission_types, ["online_quiz"]
      end
    end
  end
end
