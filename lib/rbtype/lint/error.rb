# frozen_string_literal: true
module Rbtype
  module Lint
    class Error
      attr_reader :linter, :subject, :message
      def initialize(linter, subject, message)
        @linter = linter
        @subject = subject
        @message = message
      end
    end
  end
end
