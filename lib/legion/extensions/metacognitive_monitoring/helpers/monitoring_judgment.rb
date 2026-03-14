# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module MetacognitiveMonitoring
      module Helpers
        class MonitoringJudgment
          attr_reader :id, :judgment_type, :domain, :predicted_confidence, :actual_outcome,
                      :effort_level, :resolved, :created_at

          def initialize(judgment_type:, domain:, predicted_confidence: DEFAULT_CONFIDENCE, effort_level: 0.5)
            @id                   = SecureRandom.uuid
            @judgment_type        = judgment_type
            @domain               = domain
            @predicted_confidence = predicted_confidence.clamp(0.0, 1.0)
            @effort_level         = effort_level.clamp(0.0, 1.0)
            @actual_outcome       = nil
            @resolved             = false
            @created_at           = Time.now.utc
          end

          def resolve!(actual:)
            @actual_outcome = actual.clamp(0.0, 1.0)
            @resolved       = true
            self
          end

          def calibration_error
            return nil unless resolved

            (predicted_confidence - actual_outcome).round(10)
          end

          def overconfident?
            return false unless resolved

            calibration_error > OVERCONFIDENCE_THRESHOLD
          end

          def underconfident?
            return false unless resolved

            calibration_error < UNDERCONFIDENCE_THRESHOLD
          end

          def confidence_label
            CONFIDENCE_LABELS.find { |range, _| range === predicted_confidence }&.last
          end

          def effort_label
            EFFORT_LABELS.find { |range, _| range === effort_level }&.last
          end

          def to_h
            {
              id:                   id,
              judgment_type:        judgment_type,
              domain:               domain,
              predicted_confidence: predicted_confidence,
              actual_outcome:       actual_outcome,
              effort_level:         effort_level,
              resolved:             resolved,
              calibration_error:    calibration_error,
              confidence_label:     confidence_label,
              effort_label:         effort_label,
              created_at:           created_at
            }
          end
        end
      end
    end
  end
end
