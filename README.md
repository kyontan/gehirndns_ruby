# `gehirndns-ruby`

An API Client of [Gehirn DNS](https://www.gehirn.jp/gis/dns.html) for Ruby

## Installation

Add this line to your application's Gemfile:
(*This way can't use now, I'll publish this to rubygems on nearby 2017-08-01)

```ruby
gem 'gehirn_dns'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gehirn_dns

## Usage

```ruby
# Create client instance
client = GehirnDns::Client.new(token: "nice_token", secret: "mikakunin")

# Get all managing zones
client.zones

# Get specify zone
zone = client.zone(name: "example.jp")

# Get all record sets (A, AAAA, TXT, ...) of current version
# zone.current_record_sets

# Get all versions
# zone.versions

# Get current specify record set (name, type are optional)
current_record_set = zone.current_record_set(name: "miku.example.jp.", type: :A)
# => #<GehirnDns::RecordSet
#  @alias_to=nil,
#  @editable=false,
#  @enable_alias=false,
#  @id=...,
#  @name="miku.example.jp.",
#  @records=[#<GehirnDns::Record @address=... >],
#  @ttl=3600,
#  @type=:A,
#  @version=...>

current_record_set.records
# => [#<GehirnDns::Record
#   @address="10.39.39.39",
#   @record_set=
#    #<GehirnDns::RecordSet
#     @alias_to=nil,
#     @base_path=...,
#     @client=...,
#     @editable=false,
#     @enable_alias=false,
#     @id=...,
#     @name="miku.example.jp.",
#     @records=[...],
#     @ttl=3600,
#     @type=:A, ...>>,
#   ...]

# It's possible to edit DNS record directly! (if the record is editable: latest version or not migrated yet)
# current_record_set.records.first.address = "10.0.0.22"


# you can get all versions (already sorted by the time):
# zone.versions

# Let's begin add record set, and migrate!
new_version = zone.current_version.clone(name: "Add A record to megu.example.jp.")

# You can set :A, :AAAA, :CNAME, :MX, :NS, :SRV, :TXT, and following attributes are to be set to records
# A, AAAA: address
# CNAME: cname
# MX: prio exchange
# NS: nsdname
# SRV: target port weight
# TXT: data

new_record_set = GehirnDns::RecordSet.new(name: "megu.example.jp.", ttl: 300, type: :A)
# => #<GehirnDns::RecordSet
#  @alias_to=nil,
#  @editable=true,
#  @enable_alias=false,
#  @id=nil,
#  @name="megu.example.jp.",
#  @records=[],
#  @ttl=300,
#  @type=:A, ...>

# of course, you can edit as:
# new_record_set.name = "megu.example.jp."
# new_record_set.ttl = 300
# new_record_set.type = :A

new_record_set << GehirnDns::Record.new(address: '10.22.39.22')

# Add second record (DNS Round-robin)
new_record_set << GehirnDns::Record.new(address: '10.22.39.23')

# If you want to alias existing domain:
# new_record_set.alias_to = "example.jp."

# Add record set to new version
new_version << new_record_set

# Ship it!
# (applied_at is to be enough later to gradually decrease TTL by Gehirn DNS, or denied)
new_version.migrate(name: "Add megu.example.jp!", applied_at: Time.now + 600)
# => #<GehirnDns::Preset:0x007fd7d73a2df0
#   @applied_at=2017-07-24 14:xx:yy UTC,
#   @completed_at=2017-07-24 14:xx:yy UTC,
#   @created_at=2017-07-24 14:xx:yy UTC,
#   @id=...,
#   @is_completed=false,
#   @name="Add megu.example.jp!",
#   @next_version_id=nil,
#   @prev_version_id=...>

# Or you can apply just now!
# new_version.migrate!

# You can refer migrations by:
migration = zone.migrations.last
# migration.next_migration
# migration.prev_migration
```

## Development

From bundler auto generated doc:

> After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
> 
> To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Any questions, bug reports, patches are welcome on GitHub at [kyontan/gehirndns_ruby](https://github.com/kyontan/gehirndns_ruby)

## LICENCE

Refer LICENCE.md.  Also, this library is licenced as [![SUSHI-WARE LICENSE](https://img.shields.io/badge/license-SUSHI--WARE%F0%9F%8D%A3-blue.svg)](https://github.com/MakeNowJust/sushi-ware)
