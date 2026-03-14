# frozen_string_literal: true

module Legion
  module Extensions
    module MetacognitiveMonitoring
      module Helpers
        class MonitoringEngine
          attr_reader :judgments, :calibration, :domain_calibrations

          def initialize
            @judgments           = {}
            @calibration         = CalibrationTracker.new
            @domain_calibrations = {}
          end

          def record_judgment(type:, domain:, predicted_confidence: DEFAULT_CONFIDENCE, effort: 0.5)
            judgment = MonitoringJudgment.new(
              judgment_type:        type,
              domain:               domain,
              predicted_confidence: predicted_confidence,
              effort_level:         effort
            )

            @judgments[judgment.id] = judgment
            prune_judgments
            judgment
          end

          def resolve_judgment(judgment_id:, actual_outcome:)
            judgment = @judgments[judgment_id]
            return nil unless judgment

            judgment.resolve!(actual: actual_outcome)

            @calibration.add_point(predicted: judgment.predicted_confidence, actual: actual_outcome)

            domain_calibration_for(judgment.domain).add_point(
              predicted: judgment.predicted_confidence,
              actual:    actual_outcome
            )

            judgment
          end

          def feeling_of_knowing(domain:, query: nil)
            domain_cal   = domain_calibration_for(domain)
            base_conf    = domain_cal.empty? ? DEFAULT_CONFIDENCE : domain_cal.calibration_score
            richness_mod = query.to_s.split.size * 0.02
            confidence   = [(base_conf + richness_mod).clamp(0.0, 1.0), 1.0].min

            record_judgment(
              type:                 :feeling_of_knowing,
              domain:               domain,
              predicted_confidence: confidence,
              effort:               0.3
            )
          end

          def judgment_of_learning(domain:, content: nil)
            domain_cal  = domain_calibration_for(domain)
            base_conf   = domain_cal.empty? ? DEFAULT_CONFIDENCE : domain_cal.calibration_score
            length_mod  = [(content.to_s.length * 0.001), 0.1].min
            confidence  = (base_conf + length_mod).clamp(0.0, 1.0)

            record_judgment(
              type:                 :judgment_of_learning,
              domain:               domain,
              predicted_confidence: confidence,
              effort:               0.4
            )
          end

          def detect_overconfidence
            @judgments.values.select(&:overconfident?)
          end

          def detect_underconfidence
            @judgments.values.select(&:underconfident?)
          end

          def average_effort(window: CALIBRATION_WINDOW)
            recent = @judgments.values.last(window)
            return 0.0 if recent.empty?

            (recent.sum(&:effort_level) / recent.size).round(10)
          end

          def calibration_report
            domain_reports = @domain_calibrations.transform_values(&:to_h)
            {
              overall:        @calibration.to_h,
              by_domain:      domain_reports,
              total_resolved: @judgments.values.count(&:resolved)
            }
          end

          def monitoring_report
            resolved, unresolved = @judgments.values.partition(&:resolved)

            {
              total_judgments:      @judgments.size,
              resolved_count:       resolved.size,
              unresolved_count:     unresolved.size,
              overconfident_count:  detect_overconfidence.size,
              underconfident_count: detect_underconfidence.size,
              average_effort:       average_effort,
              calibration:          @calibration.to_h,
              domain_count:         @domain_calibrations.size
            }
          end

          def to_h
            {
              judgment_count: @judgments.size,
              calibration:    @calibration.to_h,
              domain_count:   @domain_calibrations.size,
              average_effort: average_effort
            }
          end

          private

          def domain_calibration_for(domain)
            @domain_calibrations[domain] ||= CalibrationTracker.new
          end

          def prune_judgments
            return unless @judgments.size > MAX_JUDGMENTS

            oldest_keys = @judgments.keys.first(@judgments.size - MAX_JUDGMENTS)
            oldest_keys.each { |k| @judgments.delete(k) }
          end
        end
      end
    end
  end
end
