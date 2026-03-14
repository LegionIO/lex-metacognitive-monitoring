# frozen_string_literal: true

RSpec.describe Legion::Extensions::MetacognitiveMonitoring::Helpers::MonitoringJudgment do
  let(:judgment) do
    described_class.new(
      judgment_type:        :feeling_of_knowing,
      domain:               :episodic,
      predicted_confidence: 0.7,
      effort_level:         0.4
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(judgment.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores judgment_type' do
      expect(judgment.judgment_type).to eq(:feeling_of_knowing)
    end

    it 'stores domain' do
      expect(judgment.domain).to eq(:episodic)
    end

    it 'stores predicted_confidence' do
      expect(judgment.predicted_confidence).to eq(0.7)
    end

    it 'stores effort_level' do
      expect(judgment.effort_level).to eq(0.4)
    end

    it 'starts unresolved' do
      expect(judgment.resolved).to be false
    end

    it 'starts with nil actual_outcome' do
      expect(judgment.actual_outcome).to be_nil
    end

    it 'clamps predicted_confidence above 1.0 to 1.0' do
      j = described_class.new(judgment_type: :confidence_rating, domain: :test, predicted_confidence: 1.5)
      expect(j.predicted_confidence).to eq(1.0)
    end

    it 'clamps predicted_confidence below 0.0 to 0.0' do
      j = described_class.new(judgment_type: :confidence_rating, domain: :test, predicted_confidence: -0.3)
      expect(j.predicted_confidence).to eq(0.0)
    end

    it 'clamps effort_level above 1.0 to 1.0' do
      j = described_class.new(judgment_type: :effort_estimate, domain: :test, effort_level: 2.0)
      expect(j.effort_level).to eq(1.0)
    end
  end

  describe '#resolve!' do
    it 'sets actual_outcome' do
      judgment.resolve!(actual: 0.6)
      expect(judgment.actual_outcome).to eq(0.6)
    end

    it 'marks as resolved' do
      judgment.resolve!(actual: 0.6)
      expect(judgment.resolved).to be true
    end

    it 'returns self' do
      result = judgment.resolve!(actual: 0.6)
      expect(result).to eq(judgment)
    end

    it 'clamps actual_outcome to 0.0..1.0' do
      judgment.resolve!(actual: 1.5)
      expect(judgment.actual_outcome).to eq(1.0)
    end
  end

  describe '#calibration_error' do
    it 'returns nil when unresolved' do
      expect(judgment.calibration_error).to be_nil
    end

    it 'returns predicted - actual when resolved' do
      judgment.resolve!(actual: 0.5)
      expect(judgment.calibration_error).to eq(0.2)
    end

    it 'returns negative when underconfident' do
      judgment.resolve!(actual: 0.9)
      expect(judgment.calibration_error).to be < 0
    end
  end

  describe '#overconfident?' do
    it 'returns false when unresolved' do
      expect(judgment.overconfident?).to be false
    end

    it 'returns true when calibration_error > OVERCONFIDENCE_THRESHOLD' do
      judgment.resolve!(actual: 0.1)
      expect(judgment.overconfident?).to be true
    end

    it 'returns false when calibration_error is within range' do
      judgment.resolve!(actual: 0.65)
      expect(judgment.overconfident?).to be false
    end
  end

  describe '#underconfident?' do
    it 'returns false when unresolved' do
      expect(judgment.underconfident?).to be false
    end

    it 'returns true when actual >> predicted' do
      j = described_class.new(judgment_type: :feeling_of_knowing, domain: :test, predicted_confidence: 0.2)
      j.resolve!(actual: 0.9)
      expect(j.underconfident?).to be true
    end

    it 'returns false for well-calibrated judgment' do
      judgment.resolve!(actual: 0.65)
      expect(judgment.underconfident?).to be false
    end
  end

  describe '#confidence_label' do
    it 'returns :very_high for 0.9' do
      j = described_class.new(judgment_type: :confidence_rating, domain: :test, predicted_confidence: 0.9)
      expect(j.confidence_label).to eq(:very_high)
    end

    it 'returns :moderate for 0.5' do
      j = described_class.new(judgment_type: :confidence_rating, domain: :test, predicted_confidence: 0.5)
      expect(j.confidence_label).to eq(:moderate)
    end

    it 'returns :very_low for 0.1' do
      j = described_class.new(judgment_type: :confidence_rating, domain: :test, predicted_confidence: 0.1)
      expect(j.confidence_label).to eq(:very_low)
    end
  end

  describe '#effort_label' do
    it 'returns :extreme for 0.9' do
      j = described_class.new(judgment_type: :effort_estimate, domain: :test, effort_level: 0.9)
      expect(j.effort_label).to eq(:extreme)
    end

    it 'returns :minimal for 0.1' do
      j = described_class.new(judgment_type: :effort_estimate, domain: :test, effort_level: 0.1)
      expect(j.effort_label).to eq(:minimal)
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      h = judgment.to_h
      expect(h).to include(:id, :judgment_type, :domain, :predicted_confidence, :actual_outcome,
                           :effort_level, :resolved, :calibration_error, :confidence_label, :effort_label, :created_at)
    end

    it 'reflects resolved state after resolution' do
      judgment.resolve!(actual: 0.6)
      h = judgment.to_h
      expect(h[:resolved]).to be true
      expect(h[:actual_outcome]).to eq(0.6)
    end
  end
end
