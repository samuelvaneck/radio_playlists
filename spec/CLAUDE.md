# Specs

Guidance for `spec/`. The root `CLAUDE.md` has project-wide context.

## VCR for External API Calls

Use VCR to record and replay HTTP interactions for tests involving external APIs. This ensures tests are deterministic and don't depend on external services.

```ruby
# Add :use_vcr metadata to contexts that make external HTTP requests
context 'when API returns valid data', :use_vcr do
  it 'returns the expected data' do
    result = MyService.new.call
    expect(result).to be_present
  end
end
```

VCR cassettes are stored in `spec/fixtures/vcr_cassettes/` and are automatically named based on the test description. Prefer VCR over mocking Faraday/HTTP responses directly when testing service objects that call external APIs.

For tests that need real HTTP requests (no mocking), use `:real_http`:
```ruby
context 'with live API call', :real_http do
  it 'fetches real data' do
    # WebMock and VCR are disabled for this test
  end
end
```

## Multiple Expectations

The `RSpec/MultipleExpectations` cop is enabled with `Max: 1`. When you need multiple expectations in a single example, use `:aggregate_failures` to group them:

```ruby
it 'returns the correct response', :aggregate_failures do
  expect(response).to have_http_status(:ok)
  expect(json['data']).to be_an(Array)
  expect(json['data'].first['id']).to eq(record.id)
end
```

This tells RuboCop that the expectations are intentionally grouped, and RSpec will run all expectations even if earlier ones fail (providing better error messages).

## Swagger Regeneration

Request specs under `spec/requests/api/v1/` drive the Swagger doc. After adding or changing one, regenerate and commit:

```bash
bundle exec rake rswag:specs:swaggerize
```

CI's `swagger` job re-runs this and fails if the working tree is dirty.

## Other Conventions

- **RSpec context prefixes:** `when`, `with`, `without`, `if`, `unless`, `for` (enforced by rubocop-rspec).
