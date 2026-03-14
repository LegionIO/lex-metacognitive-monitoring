# frozen_string_literal: true

RSpec.describe Legion::Extensions::MetacognitiveMonitoring::Helpers::MonitoringEngine do
  subject(:engine) { described_class.new }

  describe '#initialize' do
    it 'starts with empty judgments' do
      expect(engine.judgments).to be_empty
    end

    it 'starts with a CalibrationTracker' do
      expect(engine.calibration).to be_a(
        Legion::Extensions::MetacognitiveMonitoring::Helpers::CalibrationTracker
      )
    end

    it 'starts with no domain calibrations' do
      expect(engine.domain_calibrations).to be_empty
    end
  end

  describe '#record_judgment' do
    it 'creates and stores a MonitoringJudgment' do
      judgment = engine.record_judgment(type: :feeling_of_knowing, domain: :episodic)
      expect(engine.judgments[judgment.id]).to eq(judgment)
    end

    it 'returns a MonitoringJudgment' do
      result = engine.record_judgment(type: :confidence_rating, domain: :semantic)
      expect(result).to be_a(Legion::Extensions::MetacognitiveMonitoring::Helpers::MonitoringJudgment)
    end

    it 'stores predicted_confidence on the judgment' do
      j = engine.record_judgment(type: :effort_estimate, domain: :test, predicted_confidence: 0.8)
      expect(j.predicted_confidence).to eq(0.8)
    end

    it 'stores effort on the judgment' do
      j = engine.record_judgment(type: :effort_estimate, domain: :test, effort: 0.9)
      expect(j.effort_level).to eq(0.9)
    end
  end

  describe '#resolve_judgment' do
    let!(:judgment) { engine.record_judgment(type: :feeling_of_knowing, domain: :episodic, predicted_confidence: 0.7) }

    it 'resolves the judgment' do
      engine.resolve_judgment(judgment_id: judgment.id, actual_outcome: 0.6)
      expect(judgment.resolved).to be true
    end

    it 'updates overall calibration tracker' do
      engine.resolve_judgment(judgment_id: judgment.id, actual_outcome: 0.6)
      expect(engine.calibration.count).to eq(1)
    end

    it 'updates domain calibration tracker' do
      engine.resolve_judgment(judgment_id: judgment.id, actual_outcome: 0.6)
      expect(engine.domain_calibrations[:episodic]).not_to be_nil
      expect(engine.domain_calibrations[:episodic].count).to eq(1)
    end

    it 'returns nil for unknown judgment_id' do
      result = engine.resolve_judgment(judgment_id: 'nonexistent', actual_outcome: 0.5)
      expect(result).to be_nil
    end

    it 'returns the resolved judgment' do
      result = engine.resolve_judgment(judgment_id: judgment.id, actual_outcome: 0.5)
      expect(result).to eq(judgment)
    end
  end

  describe '#feeling_of_knowing' do
    it 'returns a MonitoringJudgment with type :feeling_of_knowing' do
      j = engine.feeling_of_knowing(domain: :semantic)
      expect(j.judgment_type).to eq(:feeling_of_knowing)
    end

    it 'uses query richness to influence confidence' do
      short  = engine.feeling_of_knowing(domain: :test, query: 'x')
      long   = engine.feeling_of_knowing(domain: :test, query: 'one two three four five six seven')
      expect(long.predicted_confidence).to be >= short.predicted_confidence
    end

    it 'records the judgment in the engine' do
      j = engine.feeling_of_knowing(domain: :test)
      expect(engine.judgments[j.id]).to eq(j)
    end
  end

  describe '#judgment_of_learning' do
    it 'returns a MonitoringJudgment with type :judgment_of_learning' do
      j = engine.judgment_of_learning(domain: :procedural)
      expect(j.judgment_type).to eq(:judgment_of_learning)
    end

    it 'uses content length to influence confidence' do
      short_j = engine.judgment_of_learning(domain: :test, content: 'hi')
      long_j  = engine.judgment_of_learning(domain: :test, content: 'x' * 200)
      expect(long_j.predicted_confidence).to be >= short_j.predicted_confidence
    end
  end

  describe '#detect_overconfidence' do
    it 'returns empty when no resolved judgments' do
      engine.record_judgment(type: :confidence_rating, domain: :test)
      expect(engine.detect_overconfidence).to be_empty
    end

    it 'returns overconfident judgments' do
      j = engine.record_judgment(type: :confidence_rating, domain: :test, predicted_confidence: 0.9)
      engine.resolve_judgment(judgment_id: j.id, actual_outcome: 0.1)
      expect(engine.detect_overconfidence).to include(j)
    end

    it 'does not include well-calibrated judgments' do
      j = engine.record_judgment(type: :confidence_rating, domain: :test, predicted_confidence: 0.7)
      engine.resolve_judgment(judgment_id: j.id, actual_outcome: 0.65)
      expect(engine.detect_overconfidence).not_to include(j)
    end
  end

  describe '#detect_underconfidence' do
    it 'returns underconfident judgments' do
      j = engine.record_judgment(type: :confidence_rating, domain: :test, predicted_confidence: 0.2)
      engine.resolve_judgment(judgment_id: j.id, actual_outcome: 0.9)
      expect(engine.detect_underconfidence).to include(j)
    end
  end

  describe '#average_effort' do
    it 'returns 0.0 when no judgments' do
      expect(engine.average_effort).to eq(0.0)
    end

    it 'computes mean effort across judgments' do
      engine.record_judgment(type: :effort_estimate, domain: :test, effort: 0.4)
      engine.record_judgment(type: :effort_estimate, domain: :test, effort: 0.6)
      expect(engine.average_effort).to eq(0.5)
    end
  end

  describe '#calibration_report' do
    it 'includes overall calibration' do
      report = engine.calibration_report
      expect(report).to have_key(:overall)
    end

    it 'includes by_domain breakdown' do
      j = engine.record_judgment(type: :feeling_of_knowing, domain: :episodic, predicted_confidence: 0.7)
      engine.resolve_judgment(judgment_id: j.id, actual_outcome: 0.6)
      report = engine.calibration_report
      expect(report[:by_domain]).to have_key(:episodic)
    end

    it 'reports total_resolved count' do
      j = engine.record_judgment(type: :feeling_of_knowing, domain: :test, predicted_confidence: 0.7)
      engine.resolve_judgment(judgment_id: j.id, actual_outcome: 0.6)
      expect(engine.calibration_report[:total_resolved]).to eq(1)
    end
  end

  describe '#monitoring_report' do
    before do
      j1 = engine.record_judgment(type: :feeling_of_knowing, domain: :test, predicted_confidence: 0.7)
      engine.resolve_judgment(judgment_id: j1.id, actual_outcome: 0.3)
      engine.record_judgment(type: :confidence_rating, domain: :test)
    end

    it 'includes total_judgments' do
      expect(engine.monitoring_report[:total_judgments]).to eq(2)
    end

    it 'includes resolved_count' do
      expect(engine.monitoring_report[:resolved_count]).to eq(1)
    end

    it 'includes unresolved_count' do
      expect(engine.monitoring_report[:unresolved_count]).to eq(1)
    end

    it 'includes overconfident_count' do
      expect(engine.monitoring_report).to have_key(:overconfident_count)
    end

    it 'includes domain_count' do
      expect(engine.monitoring_report[:domain_count]).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns a summary hash' do
      h = engine.to_h
      expect(h).to include(:judgment_count, :calibration, :domain_count, :average_effort)
    end
  end
end
