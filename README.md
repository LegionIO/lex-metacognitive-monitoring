# lex-metacognitive-monitoring

Metacognitive judgment tracking and calibration for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-metacognitive-monitoring` tracks how well an agent knows what it knows. It records five types of metacognitive judgments (feeling of knowing, judgment of learning, confidence rating, effort estimate, error detection), resolves them against actual outcomes, and builds a calibration model showing how well the agent's confidence estimates track reality. Detects overconfidence and underconfidence patterns.

Key capabilities:

- **Five judgment types**: feeling_of_knowing, judgment_of_learning, confidence_rating, effort_estimate, error_detection
- **Calibration tracking**: confidence vs accuracy correlation
- **Overconfidence/underconfidence detection**: flags when confidence significantly mismatches accuracy
- **Calibration curve**: histogram of confidence bins vs actual accuracy rates
- **Calibration labels**: well_calibrated / moderately_calibrated / poorly_calibrated / uncalibrated

## Installation

Add to your Gemfile:

```ruby
gem 'lex-metacognitive-monitoring'
```

Or install directly:

```
gem install lex-metacognitive-monitoring
```

## Usage

```ruby
require 'legion/extensions/metacognitive_monitoring'

client = Legion::Extensions::MetacognitiveMonitoring::Client.new

# Record a feeling of knowing
judgment = client.feeling_of_knowing(domain: :networking)
# => { id: "...", type: :feeling_of_knowing, confidence: 0.5 }

# Record with specific confidence
judgment = client.record_judgment(
  type: :confidence_rating, domain: :ruby, confidence: 0.85, effort: 0.3
)

# Resolve against actual outcome
client.resolve_judgment(id: judgment[:judgment][:id], accurate: true)

# Check calibration
report = client.calibration_report
# => { score: 0.72, label: :moderately_calibrated, overconfidence_bias: 0.08 }

# Detect overconfidence
client.detect_overconfidence
# => [{ judgment_id: "...", domain: :ruby, confidence_excess: 0.25 }]

# View calibration curve
client.calibration_curve(bins: 5)
```

## Runner Methods

| Method | Description |
|---|---|
| `record_judgment` | Record a metacognitive judgment with type, domain, confidence, effort |
| `resolve_judgment` | Resolve a judgment with the actual outcome |
| `feeling_of_knowing` | Shortcut: record a feeling-of-knowing judgment |
| `judgment_of_learning` | Shortcut: record a judgment-of-learning |
| `detect_overconfidence` | Return judgments where confidence significantly exceeds accuracy |
| `detect_underconfidence` | Return patterns where accuracy exceeds confidence |
| `calibration_report` | Full calibration: score, label, bias, curve |
| `monitoring_report` | Judgment counts, resolved ratio, avg confidence and effort |
| `average_effort` | Mean effort estimate for a domain |
| `calibration_curve` | Confidence vs accuracy histogram |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
