# Pocky

Pocky is used to generate dependency graphs for your packwerk packages. The gem is named after pocky, a beloved Japanese snack that comes in small packages.

## Usage

```ruby
Pocky::Graph.generate(
  root_path: 'path/to/app/packages',
  default_package: 'The Monolith', # The default package listed as "." in deprecated_references.yml
  package_prefix: 'app/packages', # this is for matching package names listed in deprecated_references.yml
  output_filename: 'pocky-graph.png'
)
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pocky'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pocky

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pocky.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
