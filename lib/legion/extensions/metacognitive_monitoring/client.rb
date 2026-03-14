# frozen_string_literal: true

require 'legion/extensions/metacognitive_monitoring/runners/metacognitive_monitoring'

module Legion
  module Extensions
    module MetacognitiveMonitoring
      class Client
        include Runners::MetacognitiveMonitoring

        def initialize(engine: nil)
          @monitoring_engine = engine || Helpers::MonitoringEngine.new
        end

        private

        attr_reader :monitoring_engine
      end
    end
  end
end
