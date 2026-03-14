# frozen_string_literal: true

require 'legion/extensions/metacognitive_monitoring/client'

RSpec.describe Legion::Extensions::MetacognitiveMonitoring::Client do
  subject(:client) { described_class.new }

  it 'responds to record_judgment' do
    expect(client).to respond_to(:record_judgment)
  end

  it 'responds to resolve_judgment' do
    expect(client).to respond_to(:resolve_judgment)
  end

  it 'responds to feeling_of_knowing' do
    expect(client).to respond_to(:feeling_of_knowing)
  end

  it 'responds to judgment_of_learning' do
    expect(client).to respond_to(:judgment_of_learning)
  end

  it 'responds to detect_overconfidence' do
    expect(client).to respond_to(:detect_overconfidence)
  end

  it 'responds to detect_underconfidence' do
    expect(client).to respond_to(:detect_underconfidence)
  end

  it 'responds to calibration_report' do
    expect(client).to respond_to(:calibration_report)
  end

  it 'responds to monitoring_report' do
    expect(client).to respond_to(:monitoring_report)
  end

  it 'responds to average_effort' do
    expect(client).to respond_to(:average_effort)
  end

  it 'responds to calibration_curve' do
    expect(client).to respond_to(:calibration_curve)
  end

  it 'accepts injected engine' do
    engine = Legion::Extensions::MetacognitiveMonitoring::Helpers::MonitoringEngine.new
    c      = described_class.new(engine: engine)
    c.record_judgment(type: :confidence_rating, domain: :test)
    expect(engine.judgments.size).to eq(1)
  end

  it 'creates its own engine when none injected' do
    c = described_class.new
    expect { c.record_judgment(type: :feeling_of_knowing, domain: :test) }.not_to raise_error
  end
end
