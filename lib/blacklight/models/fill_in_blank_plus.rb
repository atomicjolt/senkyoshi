module Blacklight
  class FillInBlankPlus < Question
    def initialize
      super
    end

    def iterate_xml(data)
      super
      conditionvar = data.search("resprocessing")[0].search("conditionvar")[0]
      conditionvar.children.at("and").children.each do |or_child|
        or_child.children.each do |varequal|
          answer = Answer.new(varequal.text)
          answer.resp_ident = varequal.attributes["respident"].value
          answer.fraction = @max_score
          @answers.push(answer)
        end
      end
      self
    end

    def canvas_conversion(assessment)
      super
    end

    def process_response(resprocessing)
      super
    end
  end
end
