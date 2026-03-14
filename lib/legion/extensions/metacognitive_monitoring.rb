# frozen_string_literal: true

require 'legion/extensions/metacognitive_monitoring/version'
require 'legion/extensions/metacognitive_monitoring/helpers/constants'
require 'legion/extensions/metacognitive_monitoring/helpers/monitoring_judgment'
require 'legion/extensions/metacognitive_monitoring/helpers/calibration_tracker'
require 'legion/extensions/metacognitive_monitoring/helpers/monitoring_engine'
require 'legion/extensions/metacognitive_monitoring/runners/metacognitive_monitoring'
require 'legion/extensions/metacognitive_monitoring/client'

module Legion
  module Extensions
    module MetacognitiveMonitoring
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
