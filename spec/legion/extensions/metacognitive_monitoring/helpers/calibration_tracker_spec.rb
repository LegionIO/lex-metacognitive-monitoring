# frozen_string_literal: true

RSpec.describe Legion::Extensions::MetacognitiveMonitoring::Helpers::CalibrationTracker do
  subject(:tracker) { described_class.new }

  describe '#initialize' do
    it 'starts with empty points' do
      expect(tracker.points).to be_empty
    end
  end

  describe '#add_point' do
    it 'adds a point' do
      tracker.add_point(predicted: 0.7, actual: 0.6)
      expect(tracker.count).to eq(1)
    end

    it 'returns self for chaining' do
      result = tracker.add_point(predicted: 0.7, actual: 0.6)
      expect(result).to eq(tracker)
    end

    it 'clamps predicted above 1.0' do
      tracker.add_point(predicted: 1.5, actual: 0.5)
      expect(tracker.points.first[:predicted]).to eq(1.0)
    end

    it 'clamps actual below 0.0' do
      tracker.add_point(predicted: 0.5, actual: -0.1)
      expect(tracker.points.first[:actual]).to eq(0.0)
    end

    it 'respects MAX_CALIBRATION_POINTS limit' do
      Legion::Extensions::MetacognitiveMonitoring::Helpers::MAX_CALIBRATION_POINTS.times do
        tracker.add_point(predicted: 0.5, actual: 0.5)
      end
      tracker.add_point(predicted: 0.9, actual: 0.9)
      expect(tracker.count).to eq(Legion::Extensions::MetacognitiveMonitoring::Helpers::MAX_CALIBRATION_POINTS)
    end
  end

  describe '#mean_calibration_error' do
    it 'returns 0.0 when no points' do
      expect(tracker.mean_calibration_error).to eq(0.0)
    end

    it 'computes mean of (predicted - actual)' do
      tracker.add_point(predicted: 0.8, actual: 0.6)
      tracker.add_point(predicted: 0.6, actual: 0.6)
      expect(tracker.mean_calibration_error).to eq(0.1)
    end

    it 'returns negative for underconfidence' do
      tracker.add_point(predicted: 0.3, actual: 0.8)
      expect(tracker.mean_calibration_error).to be < 0
    end
  end

  describe '#calibration_score' do
    it 'returns 1.0 for perfect calibration' do
      tracker.add_point(predicted: 0.7, actual: 0.7)
      expect(tracker.calibration_score).to eq(1.0)
    end

    it 'decreases with larger error' do
      tracker.add_point(predicted: 0.9, actual: 0.1)
      expect(tracker.calibration_score).to be < 0.5
    end

    it 'never goes below 0.0' do
      tracker.add_point(predicted: 1.0, actual: 0.0)
      expect(tracker.calibration_score).to be >= 0.0
    end
  end

  describe '#overconfident?' do
    it 'returns true when mean error > OVERCONFIDENCE_THRESHOLD' do
      tracker.add_point(predicted: 0.9, actual: 0.4)
      expect(tracker.overconfident?).to be true
    end

    it 'returns false when well calibrated' do
      tracker.add_point(predicted: 0.7, actual: 0.65)
      expect(tracker.overconfident?).to be false
    end
  end

  describe '#underconfident?' do
    it 'returns true when mean error < UNDERCONFIDENCE_THRESHOLD' do
      tracker.add_point(predicted: 0.2, actual: 0.9)
      expect(tracker.underconfident?).to be true
    end

    it 'returns false when well calibrated' do
      tracker.add_point(predicted: 0.7, actual: 0.65)
      expect(tracker.underconfident?).to be false
    end
  end

  describe '#calibration_label' do
    it 'returns :well_calibrated for high score' do
      tracker.add_point(predicted: 0.7, actual: 0.7)
      expect(tracker.calibration_label).to eq(:well_calibrated)
    end

    it 'returns a symbol label' do
      tracker.add_point(predicted: 0.8, actual: 0.1)
      expect(tracker.calibration_label).to be_a(Symbol)
    end
  end

  describe '#calibration_curve' do
    before do
      10.times { |i| tracker.add_point(predicted: i * 0.1, actual: i * 0.1) }
    end

    it 'returns an array of bin hashes' do
      curve = tracker.calibration_curve(bins: 5)
      expect(curve).to be_an(Array)
      expect(curve.size).to eq(5)
    end

    it 'each bin has required keys' do
      curve = tracker.calibration_curve(bins: 5)
      curve.each do |bin|
        expect(bin).to include(:predicted_range, :sample_count, :actual_accuracy)
      end
    end

    it 'returns empty array when no points' do
      empty = described_class.new
      expect(empty.calibration_curve).to be_empty
    end
  end

  describe '#to_h' do
    it 'includes all summary keys' do
      h = tracker.to_h
      expect(h).to include(:count, :mean_calibration_error, :calibration_score, :calibration_label,
                           :overconfident, :underconfident)
    end
  end
end
