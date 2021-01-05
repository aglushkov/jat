# JAT
Jat is a serialization tool to build JSON API response.

## README
Current README is in development state and can show non-compatible with latest release examples.\
For stable version look at [0.0.2 README](https://github.com/aglushkov/jat/tree/v0.0.2)

## Table of Contents
* [Format](#format)
* [Quick Example](#example)
  * [Redefining attributes](#redefining-attributes)
  * [Exposing attributes](#exposing-attributes)
* [Auto preload](#auto-preload)
* [Configuration](#configuration)
  * [Exposed option](#exposed-option)
  * [Global Meta](#global-meta)
* [Paging](#paging)
* [Plugins](#plugins)
  * [JSON_API](#json_api)
  * [TO_STR](#to_str)
  * [CAMEL_LOWER](#camel_lower)
  * [CACHE](#cache)

## Format
Serialization format is almost like original [JSON-API](https://jsonapi.org/format/).

What we don't support yet:
- `links`
- object specific `meta`


## Quick Example

First of all we should specify which format we want to use. Here is an example for
json-api format.

```ruby
  class BaseSerializer < Jat
    # common plugins here ...
    # common options here ...
  end

  class UserSerializer < BaseSerializer
    attribute :id
    attribute :first_name
    attribute :last_name

    attribute :profile, serializer: -> { ProfileSerializer }
    attribute :roles, serializer: -> { RoleSerializer }
  end

  class ProfileSerializer < BaseSerializer
    attribute :description
    attribute :location
  end

  class RoleSerializer < BaseSerializer
    attribute :id
    attribute :name
  end

  UserSerializer.to_h(user) # or users
```

### Attributes
All attributes are delegated to serialized object.

Define attribute example:
```ruby
  class UserSerializer < Jat
    attribute(:email, key: :confirmed_email) # We will execute `user.confirmed_email`
    attribute(:email) { object.confirmed_email } # We can use `object` and `context`
    attribute(:email) { |user| user.confirmed_email } # We can use `object` or `user`
    attribute(:email) { |user, ctx| user.confirmed_email } # We can use `context` or `ctx`
  end
```

### Exposing Attributes
By default all attributes without serializer are exposed, we
can change this on per-attribute basis or by global config.

```ruby
  class UserSerializer < Jat
    config[:exposed] = :default # :default, :all, :none

    attribute :first_name, exposed: false
    attribute :profile, serializer: -> { ProfileSerializer }, exposed: true
  end
```

## Auto Preload

This works only when required serialization plugin with `activerecord: true` option.

We can tell which associations we want to preload for any attribute or relationship.

- `preload` can be complex value consisting of hashes and arrays
- `preload`s are merged together only for returned fields
- relationships do `preload` current name by default, can be disabled with `preload: false / nil`
- works with ActiveRecord scope, ActiveRecord object, Array of ActiveRecord objects

```ruby
  class UserSerializer < Jat
    attribute :current_email, preload: :emails

    attribute :profile, serializer: -> { ProfileSerializer } # preloads :profile by default
    attribute :comments, serializer: -> { CommentSerializer } # preloads :comments by default
  end

  class CommentSerializer < Jat
    attribute :images, serializer: -> { ImagesSerializer }, preload: { images_attachments: :blob }
  end

  # All preloads options from all serializers will be joined and preloaded to serialized resources, aka:
  #  users.preload(:emails, :profile, comments: { images_attachments: :blob })
  serializer = UserSerializer.to_h(users)
```

## Configuration
  All config options can be specified globally in main Jat class or in specific classes.
  Options are inherited from parent class.

### Exposed Option
We can set all attributes to be exposed or hidden by `exposed`
```ruby
  class UserSerializer < Jat
    config.exposed = :default # (default) attributes are exposed, relationships are not
    # or
    config.exposed = :all # everything is exposed
    # or
    config.exposed = :none # nothing is exposed
  end
```

### Global Meta
We can configure global meta to be added to all responses. \
We will not add meta when it has `nil` value.

```ruby
  # We can add static or dynamic values
  Jat.config[:meta] = {
    version: "1.2.3",
    is_admin: -> (_object, context) do
      break unless context[:current_user].admin? # nil result skips adding meta key
      true
    end
  }
```

## Paging
There are no specific stuff to implement paging, we can just use `meta`

```ruby
  Jat.config[:meta] = {
    paging: ->(records, context) do
      break unless context.dig(:params, :page)
      break unless records.is_a?(Enumerable)
      break unless records.respond_to?(:total_count)

      {
        total_count: records.total_count
        size: records.size,
        offset_value: records.offset_value,
      }
    end
  }
```

## Plugins

### JSON_API

Enabled by requiring `plugin :json_api`\
For ActiveRecord auto-preloads: `plugin :json_api, activerecord: true`

We must specify `type` for each json-api serializer.\
Also we have additional `relationship` DSL method, that is same as `attribute`, but requires `serializer` option.\
Very usefull to distinguish regular attributes from relationships.

Client can provide `fields` and `include` parameters to change response fields.

Parameters have same format as in JSON-api specification:
- `fields` - https://jsonapi.org/format/#fetching-sparse-fieldsets
- `include` - https://jsonapi.org/format/#fetching-includes

```ruby
  class UserSerializer < Jat
    plugin :json_api, activerecord: true
    type :users

    attribute :name
    attribute :username

    relationship :profile, serializer: -> { ProfileSerializer }
    relationship :comments, serializer: -> { CommentSerializer }
  end

  # Fields should be provided as hash where keys are `types` and values combinded with comma:
  UserSerializer.to_h(user, params: { fields: { users: `first_name,last_name`, comments: `text,images` } })

  # `include` parameter must be a string that contains relations to include in response.
  # Relationships should be combined with `,`, nested relationships combined with `.`:
  UserSerializer.to_h(user, params: { include: `profile,comments.images` } })
```

### TO_STR

Enabled by requiring `plugin :to_str`

Adds additional `.to_str` method to serializers to serialize directly to str.

Accepts optional config option `:to_str` to specify how to generate string from hash

```ruby
class UserSerializer < Jat
  plugin :to_str, to_str: ->(hash) { Oj.dump(hash, mode: :compat) } # use Oj instead of JSON
end

UserSerializer.to_str(user)
```

### CAMEL_LOWER

Enabled by requiring `plugin :camel_lower`

Thats it. Now all attribute keys will be serialized in camelLower case.

```ruby
class UserSerializer < Jat
  plugin :camel_lower

  attribute :foo_bar_bazz # becomes fooBarBazz in response
end
```

### CACHE

Enabled by requiring `plugin :cache`

This plugins also loads `:to_str` plugin, so you can cache strings, which is more effective.

Client should provide callable cache instance in context. \
This instance is responsible for constructing cache key and calling `this-cache.fetch { yield }`. \
It should accept provided serialized objects and context and it should yield provided block.

Example:
```ruby
  cache = lambda do |object, context, &block|
    # Some code to construct cache key, usually you want to use:
    # - object.cache_key (for ActiveRecord)
    # - context[:params]
    # - context[:format]
    cache_key = '...'

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) { block.() }
  end

  UserSerializer.to_str(users, cache: cache, **context)
  UserSerializer.to_h(users, cache: cache, **context)
```
