# Slicing
:v: Slice and dice your csv files for further analysis.

# Reason for making slicing
No database required, mom!

Data slicing and cleaning usually happen within a database like mysql or postgresql. And you will need to use sql command to manipulate the data.

I thought why can't I slice and dice them on the go. And take a subset of the data and peek it through excel or a text-editor.

Hence, slicing is created to make it easy to slice csv files from terminal.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'slicing'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install slicing

## Usage
`slicing mask` - mask the column with md5.

`slicing subset` - return a subset of 10 lines of the bigger csv file.

`slicing head` - return the header of the csv file.

`slicing rm` - remove the column from csv file.

`slicing first` - return the first line of data of the csv file.

`slicing count` - return the total row and column of the csv file.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/slicing. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
