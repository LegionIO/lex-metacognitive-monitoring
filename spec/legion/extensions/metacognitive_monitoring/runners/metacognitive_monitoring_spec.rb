# frozen_string_literal: true

require 'legion/extensions/metacognitive_monitoring/client'

RSpec.describe Legion::Extensions::MetacognitiveMonitoring::Runners::MetacognitiveMonitoring do
  let(:engine) { Legion::Extensions::MetacognitiveMonitoring::Helpers::MonitoringEngine.new }
  let(:client) { Legion::Extensions::MetacognitiveMonitoring::Client.new(engine: engine) }

  describe '#record_judgment' do
    it 'succeeds with valid type' do
      result = client.record_judgment(type: :feeling_of_knowing, domain: :episodic)
      expect(result[:success]).to be true
    end

    it 'returns a judgment_id' do
      result = client.record_judgment(type: :feeling_of_knowing, domain: :episodic)
      expect(result[:judgment_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns the judgment hash' do
      result = client.record_judgment(type: :feeling_of_knowing, domain: :episodic)
      expect(result[:judgment]).to include(:id, :judgment_type, :domain)
    end

    it 'rejects invalid judgment type' do
      result = client.record_judgment(type: :nonexistent, domain: :test)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_judgment_type)
    end

    it 'includes valid_types in error response' do
      result = client.record_judgment(type: :bad_type, domain: :test)
      expect(result[:valid_types]).to include(:feeling_of_knowing)
    end

    it 'accepts string type and converts to symbol' do
      result = client.record_judgment(type: 'confidence_rating', domain: :test)
      expect(result[:success]).to be true
    end

    it 'records judgment in engine' do
      result = client.record_judgment(type: :effort_estimate, domain: :test)
      expect(engine.judgments[result[:judgment_id]]).not_to be_nil
    end

    it 'uses provided predicted_confidence' do
      result = client.record_judgment(type: :confidence_rating, domain: :test, predicted_confidence: 0.85)
      expect(result[:judgment][:predicted_confidence]).to eq(0.85)
    end
  end

  describe '#resolve_judgment' do
    let!(:recorded) { client.record_judgment(type: :feeling_of_knowing, domain: :episodic, predicted_confidence: 0.7) }

    it 'succeeds for existing judgment' do
      result = client.resolve_judgment(judgment_id: recorded[:judgment_id], actual_outcome: 0.6)
      expect(result[:success]).to be true
    end

    it 'returns the judgment_id' do
      result = client.resolve_judgment(judgment_id: recorded[:judgment_id], actual_outcome: 0.6)
      expect(result[:judgment_id]).to eq(recorded[:judgment_id])
    end

    it 'returns the resolved judgment hash' do
      result = client.resolve_judgment(judgment_id: recorded[:judgment_id], actual_outcome: 0.6)
      expect(result[:judgment][:resolved]).to be true
    end

    it 'returns failure for unknown id' do
      result = client.resolve_judgment(judgment_id: 'no-such-id', actual_outcome: 0.5)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#feeling_of_knowing' do
    it 'succeeds' do
      result = client.feeling_of_knowing(domain: :episodic)
      expect(result[:success]).to be true
    end

    it 'returns judgment_id' do
      result = client.feeling_of_knowing(domain: :episodic)
      expect(result[:judgment_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns predicted_confidence' do
      result = client.feeling_of_knowing(domain: :episodic)
      expect(result[:predicted_confidence]).to be_between(0.0, 1.0)
    end

    it 'returns a confidence_label' do
      result = client.feeling_of_knowing(domain: :episodic)
      expect(result[:confidence_label]).to be_a(Symbol)
    end

    it 'reflects query in domain' do
      result = client.feeling_of_knowing(domain: :semantic, query: 'what is ruby')
      expect(result[:domain]).to eq(:semantic)
    end
  end

  describe '#judgment_of_learning' do
    it 'succeeds' do
      result = client.judgment_of_learning(domain: :procedural)
      expect(result[:success]).to be true
    end

    it 'returns judgment_id' do
      result = client.judgment_of_learning(domain: :procedural)
      expect(result[:judgment_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns confidence_label' do
      result = client.judgment_of_learning(domain: :procedural, content: 'some content to assess')
      expect(result[:confidence_label]).to be_a(Symbol)
    end
  end

  describe '#detect_overconfidence' do
    context 'with no overconfident judgments' do
      it 'returns empty findings' do
        result = client.detect_overconfidence
        expect(result[:count]).to eq(0)
        expect(result[:findings]).to be_empty
      end
    end

    context 'with overconfident judgments' do
      before do
        r = client.record_judgment(type: :confidence_rating, domain: :test, predicted_confidence: 0.95)
        client.resolve_judgment(judgment_id: r[:judgment_id], actual_outcome: 0.1)
      end

      it 'detects overconfidence' do
        result = client.detect_overconfidence
        expect(result[:count]).to eq(1)
      end

      it 'includes finding details' do
        result = client.detect_overconfidence
        expect(result[:findings].first).to include(:id, :predicted_confidence, :actual_outcome)
      end
    end
  end

  describe '#detect_underconfidence' do
    context 'with underconfident judgment' do
      before do
        r = client.record_judgment(type: :confidence_rating, domain: :test, predicted_confidence: 0.1)
        client.resolve_judgment(judgment_id: r[:judgment_id], actual_outcome: 0.9)
      end

      it 'detects underconfidence' do
        result = client.detect_underconfidence
        expect(result[:count]).to eq(1)
        expect(result[:success]).to be true
      end
    end
  end

  describe '#calibration_report' do
    it 'returns success' do
      result = client.calibration_report
      expect(result[:success]).to be true
    end

    it 'includes report' do
      result = client.calibration_report
      expect(result[:report]).to include(:overall, :by_domain, :total_resolved)
    end

    it 'populates by_domain after resolving a domain judgment' do
      r = client.record_judgment(type: :feeling_of_knowing, domain: :episodic, predicted_confidence: 0.7)
      client.resolve_judgment(judgment_id: r[:judgment_id], actual_outcome: 0.6)
      report = client.calibration_report
      expect(report[:report][:by_domain]).to have_key(:episodic)
    end
  end

  describe '#monitoring_report' do
    before do
      r = client.record_judgment(type: :feeling_of_knowing, domain: :test, predicted_confidence: 0.7)
      client.resolve_judgment(judgment_id: r[:judgment_id], actual_outcome: 0.5)
      client.record_judgment(type: :effort_estimate, domain: :test)
    end

    it 'returns success' do
      expect(client.monitoring_report[:success]).to be true
    end

    it 'includes total_judgments' do
      expect(client.monitoring_report[:report][:total_judgments]).to eq(2)
    end

    it 'includes resolved and unresolved counts' do
      report = client.monitoring_report[:report]
      expect(report[:resolved_count]).to eq(1)
      expect(report[:unresolved_count]).to eq(1)
    end
  end

  describe '#average_effort' do
    it 'returns success' do
      result = client.average_effort
      expect(result[:success]).to be true
    end

    it 'returns 0.0 when no judgments' do
      result = client.average_effort
      expect(result[:average_effort]).to eq(0.0)
    end

    it 'includes effort_label' do
      client.record_judgment(type: :effort_estimate, domain: :test, effort: 0.9)
      result = client.average_effort
      expect(result[:effort_label]).to be_a(Symbol)
    end

    it 'reflects window parameter' do
      result = client.average_effort(window: 10)
      expect(result[:window]).to eq(10)
    end
  end

  describe '#calibration_curve' do
    it 'returns success' do
      expect(client.calibration_curve[:success]).to be true
    end

    it 'returns requested number of bins' do
      result = client.calibration_curve(bins: 5)
      expect(result[:bins]).to eq(5)
    end

    it 'returns curve array' do
      r = client.record_judgment(type: :confidence_rating, domain: :test, predicted_confidence: 0.7)
      client.resolve_judgment(judgment_id: r[:judgment_id], actual_outcome: 0.6)
      result = client.calibration_curve(bins: 5)
      expect(result[:curve]).to be_an(Array)
    end
  end
end
