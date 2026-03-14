# lex-metacognitive-monitoring

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-metacognitive-monitoring`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::MetacognitiveMonitoring`

## Purpose

Metacognitive judgment tracking and calibration for LegionIO agents. Records five types of metacognitive judgments (feeling of knowing, judgment of learning, confidence rating, effort estimate, error detection), resolves them against actual outcomes to build a calibration model, detects overconfidence and underconfidence, and produces a calibration curve showing how well the agent's confidence estimates track actual accuracy.

## Gem Info

- **Require path**: `legion/extensions/metacognitive_monitoring`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/metacognitive_monitoring/
  version.rb
  helpers/
    monitoring_judgment.rb    # MonitoringJudgment value object
    calibration_tracker.rb    # CalibrationTracker with calibration curve
    monitoring_engine.rb      # MonitoringEngine combining judgments + calibration
  runners/
    metacognitive_monitoring.rb  # Runner module

spec/
  legion/extensions/metacognitive_monitoring/
    helpers/
      monitoring_judgment_spec.rb
      calibration_tracker_spec.rb
      monitoring_engine_spec.rb
    runners/metacognitive_monitoring_spec.rb
  spec_helper.rb
```

## Key Constants

Constants are defined directly in the `Legion::Extensions::MetacognitiveMonitoring` module (not in a nested Constants submodule):

```ruby
MAX_JUDGMENTS             = 500
MAX_CALIBRATION_POINTS    = 200
OVERCONFIDENCE_THRESHOLD  = 0.2   # confidence exceeds accuracy by this amount -> overconfident
CALIBRATION_WINDOW        = 50    # judgments in rolling calibration window

JUDGMENT_TYPES = %i[
  feeling_of_knowing judgment_of_learning confidence_rating
  effort_estimate error_detection
]

CALIBRATION_LABELS = {
  (0.8..)     => :well_calibrated,
  (0.5...0.8) => :moderately_calibrated,
  (0.2...0.5) => :poorly_calibrated,
  (..0.2)     => :uncalibrated
}

CONFIDENCE_LABELS = {
  (0.8..)     => :very_high,
  (0.6...0.8) => :high,
  (0.4...0.6) => :moderate,
  (0.2...0.4) => :low,
  (..0.2)     => :very_low
}

EFFORT_LABELS = {
  (0.8..)     => :very_high,
  (0.6...0.8) => :high,
  (0.4...0.6) => :moderate,
  (0.2...0.4) => :low,
  (..0.2)     => :minimal
}
```

## Helpers

### `Helpers::MonitoringJudgment` (class)

A single metacognitive judgment event.

| Attribute | Type | Description |
|---|---|---|
| `id` | String (UUID) | unique identifier |
| `judgment_type` | Symbol | from JUDGMENT_TYPES |
| `domain` | Symbol | subject domain |
| `confidence` | Float (0..1) | predicted confidence |
| `effort` | Float (0..1) | estimated effort |
| `resolved` | Boolean | whether actual outcome is known |
| `accurate` | Boolean | whether the judgment was accurate |

### `Helpers::CalibrationTracker` (class)

Tracks how well confidence estimates match actual outcomes.

| Method | Description |
|---|---|
| `record(judgment)` | adds judgment to calibration buffer |
| `resolve(judgment_id:, accurate:)` | marks judgment resolved with outcome |
| `calibration_score` | ratio of resolved judgments that were accurate |
| `calibration_label` | label from CALIBRATION_LABELS |
| `overconfidence_bias` | mean(confidence) - mean(accuracy) for resolved judgments |
| `underconfidence_bias` | mean(accuracy) - mean(confidence) for resolved judgments |
| `calibration_curve(bins:)` | histogram of confidence bins vs actual accuracy |

### `Helpers::MonitoringEngine` (class)

Combines judgment recording and calibration tracking.

| Method | Description |
|---|---|
| `record_judgment(type:, domain:, confidence:, effort:)` | creates and stores judgment; adds to calibration tracker |
| `resolve_judgment(id:, accurate:)` | resolves judgment, updates calibration |
| `feeling_of_knowing(domain:)` | shortcut: record judgment_type :feeling_of_knowing |
| `judgment_of_learning(domain:, confidence:)` | shortcut: record judgment_type :judgment_of_learning |
| `detect_overconfidence` | judgments where confidence exceeds accuracy by > OVERCONFIDENCE_THRESHOLD |
| `detect_underconfidence` | judgments where accuracy exceeds confidence significantly |
| `calibration_report` | full calibration stats: score, label, bias, curve |
| `monitoring_report` | judgment counts by type, resolved ratio, avg confidence/effort |
| `average_effort(domain:)` | mean effort estimate for a domain |
| `calibration_curve(bins:)` | delegates to CalibrationTracker |

## Runners

Module: `Legion::Extensions::MetacognitiveMonitoring::Runners::MetacognitiveMonitoring`

Private state: `@engine` (memoized `MonitoringEngine` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `record_judgment` | `type:, domain:, confidence:, effort: 0.5` | Record a metacognitive judgment |
| `resolve_judgment` | `id:, accurate:` | Resolve a judgment with actual outcome |
| `feeling_of_knowing` | `domain:` | Record a feeling-of-knowing judgment |
| `judgment_of_learning` | `domain:, confidence:` | Record a judgment-of-learning |
| `detect_overconfidence` | (none) | Return overconfident unresolved judgments |
| `detect_underconfidence` | (none) | Return underconfident patterns |
| `calibration_report` | (none) | Full calibration: score, label, bias, curve |
| `monitoring_report` | (none) | Judgment counts, resolved ratio, avg confidence |
| `average_effort` | `domain:` | Mean effort estimate for a domain |
| `calibration_curve` | `bins: 10` | Confidence vs accuracy histogram |

## Integration Points

- **lex-prediction**: prediction confidence is a direct source for `confidence_rating` and `judgment_of_learning` judgments. When a prediction resolves, `resolve_judgment` is called.
- **lex-learning-rate**: high calibration errors (overconfidence) suggest the learning rate should be increased — the agent is worse than it thinks.
- **lex-hypothesis-testing**: hypothesis posteriors can be recorded as `feeling_of_knowing` judgments; confirmation resolves them.
- **lex-metacognition**: `MetacognitiveMonitoring` is listed under `:introspection` capability category.

## Development Notes

- Constants are at the module level (`Legion::Extensions::MetacognitiveMonitoring`), not nested in a `Constants` submodule. This is an anomaly vs other LEX gems where constants are in `Helpers::Constants`.
- OVERCONFIDENCE_THRESHOLD of 0.2 means the agent must be 20 percentage points more confident than accurate to flag as overconfident.
- `calibration_curve` bins confidence into equal-width buckets (default 10 bins of 0.1 each) and computes mean accuracy within each bin. Bins with no resolved judgments are omitted.
- `detect_overconfidence` operates on unresolved judgments using historical overconfidence bias as the comparator — it does not wait for resolution.
- MAX_JUDGMENTS eviction removes oldest judgments (FIFO). Calibration points from the CalibrationTracker use a separate MAX_CALIBRATION_POINTS cap.
- No actor defined; judgments are recorded and resolved on-demand.
