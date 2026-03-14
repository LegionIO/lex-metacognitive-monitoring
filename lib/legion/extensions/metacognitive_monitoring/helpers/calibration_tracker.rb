# frozen_string_literal: true

module Legion
  module Extensions
    module MetacognitiveMonitoring
      module Helpers
        class CalibrationTracker
          attr_reader :points

          def initialize
            @points = []
          end

          def add_point(predicted:, actual:)
            @points << { predicted: predicted.clamp(0.0, 1.0), actual: actual.clamp(0.0, 1.0) }
            @points.shift while @points.size > MAX_CALIBRATION_POINTS
            self
          end

          def mean_calibration_error
            return 0.0 if @points.empty?

            errors = @points.map { |p| p[:predicted] - p[:actual] }
            (errors.sum / errors.size).round(10)
          end

          def calibration_score
            score = (1.0 - mean_calibration_error.abs).clamp(0.0, 1.0)
            score.round(10)
          end

          def overconfident?
            mean_calibration_error > OVERCONFIDENCE_THRESHOLD
          end

          def underconfident?
            mean_calibration_error < UNDERCONFIDENCE_THRESHOLD
          end

          def calibration_label
            score = calibration_score
            CALIBRATION_LABELS.find { |range, _| range.cover?(score) }&.last
          end

          def calibration_curve(bins: 5)
            return [] if @points.empty?

            bin_size  = 1.0 / bins
            bin_edges = bins.times.map { |i| (i * bin_size).round(10) }

            bin_edges.map do |edge|
              upper = (edge + bin_size).round(10)
              range = (edge...upper)
              in_bin = @points.select { |p| range.cover?(p[:predicted]) }

              actual_mean = if in_bin.empty?
                              nil
                            else
                              (in_bin.sum { |p| p[:actual] } / in_bin.size).round(10)
                            end

              {
                predicted_range: range,
                sample_count:    in_bin.size,
                actual_accuracy: actual_mean
              }
            end
          end

          def count
            @points.size
          end

          def empty?
            @points.empty?
          end

          def to_h
            {
              count:                  count,
              mean_calibration_error: mean_calibration_error,
              calibration_score:      calibration_score,
              calibration_label:      calibration_label,
              overconfident:          overconfident?,
              underconfident:         underconfident?
            }
          end
        end
      end
    end
  end
end
