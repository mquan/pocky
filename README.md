# Pocky

Pocky generates dependency graphs for your packwerk packages. The gem is named after pocky, a beloved Japanese snack that comes in small packages.

![Pocky](https://user-images.githubusercontent.com/138784/103248942-c141de80-4921-11eb-99bd-3744816abc37.png)

## Usage

Invoke from irb or code, only `root_path` is required.
```ruby
Pocky::Packwerk.generate(
  root_path: 'path/to/app/packages',
  default_package: 'Default',    # The default package listed as "." in deprecated_references.yml
  filename: 'packwerk-viz.png', # Name of output file
  dpi: 150                     # Output file resolution
)
```

![pocky-graph](https://user-images.githubusercontent.com/138784/103251690-a6299b80-492e-11eb-92f1-205752d850d8.png)

Note that the the bold edges indicate heavier dependencies.

Invoke as a rake task:

    $ rake pocky:generate"[path/to/app/packages,Monolith,packages.png,100]"


#### `root_path` as an array
`root_path` can also be an array in case your packages are organized in multiple directories. Alternatively, you can also provide paths to individual packages to generate more focused graphs for your package subsystems.

```ruby
Pocky::Packwerk.generate(
  root_path: [
    'path/to/app/packages/a',
    'path/to/app/packages/z',
  ]
)
```

Generate the same graph using the rake task:

    $ rake pocky:generate"[path/to/app/packages/a path/to/app/packages/z]"


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

Bug reports and pull requests are welcome on GitHub at https://github.com/mquan/pocky.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
