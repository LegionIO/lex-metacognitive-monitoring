# frozen_string_literal: true

RSpec.describe Legion::Extensions::MetacognitiveMonitoring::Helpers do
  describe 'JUDGMENT_TYPES' do
    subject(:types) { described_class::JUDGMENT_TYPES }

    it 'includes feeling_of_knowing' do
      expect(types).to include(:feeling_of_knowing)
    end

    it 'includes judgment_of_learning' do
      expect(types).to include(:judgment_of_learning)
    end

    it 'includes confidence_rating' do
      expect(types).to include(:confidence_rating)
    end

    it 'includes effort_estimate' do
      expect(types).to include(:effort_estimate)
    end

    it 'includes error_detection' do
      expect(types).to include(:error_detection)
    end

    it 'is frozen' do
      expect(types).to be_frozen
    end
  end

  describe 'CALIBRATION_LABELS' do
    subject(:labels) { described_class::CALIBRATION_LABELS }

    it 'maps high score to :well_calibrated' do
      label = labels.find { |range, _| range.cover? 0.9 }&.last
      expect(label).to eq(:well_calibrated)
    end

    it 'maps low score to :uncalibrated' do
      label = labels.find { |range, _| range.cover? 0.1 }&.last
      expect(label).to eq(:uncalibrated)
    end
  end

  describe 'CONFIDENCE_LABELS' do
    subject(:labels) { described_class::CONFIDENCE_LABELS }

    it 'maps 0.9 to :very_high' do
      label = labels.find { |range, _| range.cover? 0.9 }&.last
      expect(label).to eq(:very_high)
    end

    it 'maps 0.1 to :very_low' do
      label = labels.find { |range, _| range.cover? 0.1 }&.last
      expect(label).to eq(:very_low)
    end
  end

  describe 'EFFORT_LABELS' do
    subject(:labels) { described_class::EFFORT_LABELS }

    it 'maps 0.9 to :extreme' do
      label = labels.find { |range, _| range.cover? 0.9 }&.last
      expect(label).to eq(:extreme)
    end

    it 'maps 0.1 to :minimal' do
      label = labels.find { |range, _| range.cover? 0.1 }&.last
      expect(label).to eq(:minimal)
    end
  end

  describe 'thresholds' do
    it 'OVERCONFIDENCE_THRESHOLD is 0.2' do
      expect(described_class::OVERCONFIDENCE_THRESHOLD).to eq(0.2)
    end

    it 'UNDERCONFIDENCE_THRESHOLD is -0.2' do
      expect(described_class::UNDERCONFIDENCE_THRESHOLD).to eq(-0.2)
    end

    it 'DEFAULT_CONFIDENCE is 0.5' do
      expect(described_class::DEFAULT_CONFIDENCE).to eq(0.5)
    end

    it 'CALIBRATION_WINDOW is 50' do
      expect(described_class::CALIBRATION_WINDOW).to eq(50)
    end
  end
end
