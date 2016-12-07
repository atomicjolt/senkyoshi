module Blacklight
  class Ordering < Question
    def initialize
      super
      @matches = []
      @order_answers = {}
    end

    def iterate_xml(data)
      super
      resprocessing = data.children.at("resprocessing")
      @order_answers = set_order_answers(resprocessing)
      if response_block = data.children.search("flow[@class=RESPONSE_BLOCK]")
        response_block.children.at("render_choice").children.each do |choice|
          id = choice.children.at("response_label").attributes["ident"].value
          question = @order_answers[id].to_s
          answer = convert_html(choice.children.at("mat_formattedtext").text)
          @matches << { id: id, question_text: question, answer_text: answer }
        end
        @matches = @matches.sort_by { |hsh| hsh[:question_text] }
      end
      self
    end

    def canvas_conversion(assessment)
      super
      @question.matches = @matches
      assessment
    end

    def set_order_answers(resprocessing)
      order_answers = {}
      correct = resprocessing.css("respcondition[title=correct]")
      correct.search("and")[0].children.each_with_index do |varequal, index|
        id = varequal.text
        order_answers[id] = index + 1
      end
      order_answers
    end
  end
end
