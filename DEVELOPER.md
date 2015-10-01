## Release process

### Run the specs
```bash
rake test
```

### Release the gem
You need to update the `version.rb` file

Generate the gem file
```
gem build maestrano.gemspec
```

To push to Rubygems, you need to configure your credentials
```bash
curl -u maestrano https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials; chmod 0600 ~/.gem/credentials
```

Then push the gem
```bash
gem push maestrano-0.12.0.gem -k maesrtano
```
