# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module MetacognitiveMonitoring
      module Runners
        module MetacognitiveMonitoring
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def record_judgment(type:, domain:, predicted_confidence: Helpers::DEFAULT_CONFIDENCE,
                              effort: 0.5, engine: nil, **)
            eng       = engine || monitoring_engine
            type_sym  = type.to_sym

            return { success: false, error: :invalid_judgment_type, valid_types: Helpers::JUDGMENT_TYPES } unless Helpers::JUDGMENT_TYPES.include?(type_sym)

            judgment = eng.record_judgment(
              type:                 type_sym,
              domain:               domain,
              predicted_confidence: predicted_confidence,
              effort:               effort
            )

            Legion::Logging.debug "[metacognitive] record_judgment type=#{type_sym} domain=#{domain} " \
                                  "confidence=#{judgment.predicted_confidence.round(2)} id=#{judgment.id[0..7]}"

            { success: true, judgment_id: judgment.id, judgment: judgment.to_h }
          end

          def resolve_judgment(judgment_id:, actual_outcome:, engine: nil, **)
            eng      = engine || monitoring_engine
            judgment = eng.resolve_judgment(judgment_id: judgment_id, actual_outcome: actual_outcome)

            unless judgment
              Legion::Logging.debug "[metacognitive] resolve_judgment not_found id=#{judgment_id[0..7]}"
              return { success: false, error: :not_found }
            end

            Legion::Logging.info "[metacognitive] resolved judgment=#{judgment_id[0..7]} " \
                                 "error=#{judgment.calibration_error&.round(3)}"

            { success: true, judgment_id: judgment_id, judgment: judgment.to_h }
          end

          def feeling_of_knowing(domain:, query: nil, engine: nil, **)
            eng      = engine || monitoring_engine
            judgment = eng.feeling_of_knowing(domain: domain, query: query)

            Legion::Logging.debug "[metacognitive] fok domain=#{domain} confidence=#{judgment.predicted_confidence.round(2)}"

            {
              success:              true,
              judgment_id:          judgment.id,
              domain:               domain,
              predicted_confidence: judgment.predicted_confidence,
              confidence_label:     judgment.confidence_label
            }
          end

          def judgment_of_learning(domain:, content: nil, engine: nil, **)
            eng      = engine || monitoring_engine
            judgment = eng.judgment_of_learning(domain: domain, content: content)

            Legion::Logging.debug "[metacognitive] jol domain=#{domain} confidence=#{judgment.predicted_confidence.round(2)}"

            {
              success:              true,
              judgment_id:          judgment.id,
              domain:               domain,
              predicted_confidence: judgment.predicted_confidence,
              confidence_label:     judgment.confidence_label
            }
          end

          def detect_overconfidence(engine: nil, **)
            eng      = engine || monitoring_engine
            findings = eng.detect_overconfidence

            Legion::Logging.debug "[metacognitive] overconfidence_scan count=#{findings.size}"

            {
              success:  true,
              count:    findings.size,
              findings: findings.map(&:to_h)
            }
          end

          def detect_underconfidence(engine: nil, **)
            eng      = engine || monitoring_engine
            findings = eng.detect_underconfidence

            Legion::Logging.debug "[metacognitive] underconfidence_scan count=#{findings.size}"

            {
              success:  true,
              count:    findings.size,
              findings: findings.map(&:to_h)
            }
          end

          def calibration_report(engine: nil, **)
            eng    = engine || monitoring_engine
            report = eng.calibration_report

            Legion::Logging.debug "[metacognitive] calibration_report domains=#{report[:by_domain].size}"

            { success: true, report: report }
          end

          def monitoring_report(engine: nil, **)
            eng    = engine || monitoring_engine
            report = eng.monitoring_report

            Legion::Logging.debug "[metacognitive] monitoring_report total=#{report[:total_judgments]}"

            { success: true, report: report }
          end

          def average_effort(window: Helpers::CALIBRATION_WINDOW, engine: nil, **)
            eng    = engine || monitoring_engine
            effort = eng.average_effort(window: window)

            label = Helpers::EFFORT_LABELS.find { |range, _| range.cover?(effort) }&.last

            { success: true, average_effort: effort, effort_label: label, window: window }
          end

          def calibration_curve(bins: 5, engine: nil, **)
            eng   = engine || monitoring_engine
            curve = eng.calibration.calibration_curve(bins: bins)

            { success: true, bins: bins, curve: curve }
          end

          private

          def monitoring_engine
            @monitoring_engine ||= Helpers::MonitoringEngine.new
          end
        end
      end
    end
  end
end
