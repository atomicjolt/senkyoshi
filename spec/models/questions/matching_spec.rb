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

require "minitest/autorun"
require "senkyoshi"
require "pry"

include Senkyoshi

describe Senkyoshi do
  describe "Matching" do
    before do
      @matching = Matching.new
    end

    describe "initialize" do
      it "should initialize matching" do
        assert_equal (@matching.is_a? Object), true
      end
    end

    describe "iterate_xml" do
      it "should iterate through xml and have one answer" do
        xml = get_fixture_xml "matching.xml"
        @matching = @matching.iterate_xml(xml.children.first)
        matches = @matching.instance_variable_get :@matches

        assert_equal matches.count, 4
      end

      it "should iterate through xml and write content to question text" do
        xml = get_fixture_xml "matching.xml"
        @matching = @matching.iterate_xml(xml.children.first)
        matches = @matching.instance_variable_get :@matches

        assert_equal matches.first[:question_text], "<p>To be or not to be</p>"
      end

      it "should iterate through xml, empty answer text and strip some HTML" do
        xml = get_fixture_xml "matching.xml"
        @matching = @matching.iterate_xml(xml.children.first)
        matches = @matching.instance_variable_get :@matches

        # Original HTML: <p>that <em>is</em> not <a style='color: green>a</a>
        #               question. I <span>dislike</span> it.</p>
        assert_equal(
          matches.first[:answer_text],
          "that is not <a>a</a> question. I dislike it.",
        )
      end

      it "should iterate through xml and set matching_answers" do
        xml = get_fixture_xml "matching.xml"
        @matching = @matching.iterate_xml(xml.children.first)
        matches = @matching.instance_variable_get :@matching_answers

        assert_equal matches.count, 4
      end
    end

    describe "set_matching_answers" do
      it "should return the matching answers" do
        xml = get_fixture_xml "matching.xml"
        resprocessing = xml.search("resprocessing")
        matching_answers = @matching.set_matching_answers(resprocessing)

        assert_equal matching_answers.count, 4
      end

      it "should return the matching answers" do
        xml = get_fixture_xml "matching.xml"
        resprocessing = xml.search("resprocessing")
        matching_answers = @matching.set_matching_answers(resprocessing)

        assert_equal matching_answers.first,
                     ["6d0161a74fec47128b7b4d30ef4be242",
                      "cba423e04f974f12921829f18a4a5f28"]
      end
    end
  end
end
