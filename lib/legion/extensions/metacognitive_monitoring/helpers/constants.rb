# frozen_string_literal: true

module Legion
  module Extensions
    module MetacognitiveMonitoring
      module Helpers
        MAX_JUDGMENTS          = 500
        MAX_CALIBRATION_POINTS = 200
        JUDGMENT_TYPES         = %i[feeling_of_knowing judgment_of_learning confidence_rating effort_estimate
                                    error_detection].freeze

        CALIBRATION_LABELS = {
          (0.8..)      => :well_calibrated,
          (0.6...0.8)  => :slightly_miscalibrated,
          (0.4...0.6)  => :miscalibrated,
          (0.2...0.4)  => :poorly_calibrated,
          (..0.2)      => :uncalibrated
        }.freeze

        CONFIDENCE_LABELS = {
          (0.8..)      => :very_high,
          (0.6...0.8)  => :high,
          (0.4...0.6)  => :moderate,
          (0.2...0.4)  => :low,
          (..0.2)      => :very_low
        }.freeze

        EFFORT_LABELS = {
          (0.8..)      => :extreme,
          (0.6...0.8)  => :high,
          (0.4...0.6)  => :moderate,
          (0.2...0.4)  => :low,
          (..0.2)      => :minimal
        }.freeze

        OVERCONFIDENCE_THRESHOLD  = 0.2  # predicted - actual > this = overconfident
        UNDERCONFIDENCE_THRESHOLD = -0.2
        DEFAULT_CONFIDENCE        = 0.5
        CALIBRATION_WINDOW        = 50   # last N judgments for calibration calculation
      end
    end
  end
end
