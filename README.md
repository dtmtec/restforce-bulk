# Restforce::Bulk

[![build status][1]][2]

[1]: https://travis-ci.org/dtmtec/restforce-bulk.svg


Client for Salesforce Bulk API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'restforce-bulk'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install restforce-bulk

## Usage

### Query:

    # Creating a query job and adding a batch, using CSV type
    job   = Restforce::Bulk::Job.create(:query, 'Account', :csv)
    batch = job.add_batch("select Id, Name from Account limit 10")

    # wait for the batch to complete, then refresh data
    batch.refresh
    batch.completed? # => true

    # query batches returns only one result
    result = batch.results.first

    # we can get the contents from the result
    csv = result.content

    # csv is a CSV::Table, now you can process it any way you want

### CRUD operations

    # Creating an upsert job, using XML type (default)
    job = Restforce::Bulk::Job.create(:upsert, 'Account')

    # Adding a batch
    batch = job.add_batch([{ Name: "New Account" }, { Id: 'a0B29000000XGxf', Name: 'Old Account' }])

    # wait for the batch to complete, then refresh data
    batch.refresh
    batch.completed? # => true

    # get the results for each row
    batch.results.each do |result|
      puts result.id      # Id of the result
      puts result.success # row successfully processed
      puts result.error   # error for row
    end

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dtmtec/restforce-bulk. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

