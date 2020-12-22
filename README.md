# JAT
Jat is a serialization tool to build JSON API response.

## README
Current README is in development state and can show non-compatible with latest release examples.\
For stable version look at [0.0.1 README](https://github.com/aglushkov/jat/tree/v0.0.1)

## Table of Contents
* [Format](#format)
* [DSL](#dsl)
  * [Example](#example)
  * [Redefining attributes](#redefining-attributes)
  * [Exposing attributes](#exposing-attributes)
* [Auto preload](#auto-preload)
* [Limit response fields](#limit-response-fields)
* [Configuration](#configuration)
  * [Exposed option](#exposed-option)
  * [Camel Lower option](#camel-lower-option)
  * [JSON encoder option](#json-encoder-option)
  * [Global Meta](#global-meta)
* [Inheritance](#inheritance)
* [Caching](#caching)
* [Paging](#paging)

## Format
Serialization format is almost like original [JSON-API](https://jsonapi.org/format/).

What we don't support yet:
- `links`
- object specific `meta`

## DSL
### Example
Each serializer must have *type*.
Also we can add attributes and relationships.

```ruby
  class UserSerializer < Jat
    type :user

    attribute :id
    attribute :first_name
    attribute :last_name

    relationship :profile, serializer: -> { ProfileSerializer }
    relationship :roles, serializer: -> { RoleSerializer }
  end

  # Serializes single object
  UserSerializer.to_h(user) # serializes to hash
  UserSerializer.to_str(user) # serializes to json string

  # Serializes multiple objects
  UserSerializer.to_h(users, many: true) # `many: true` is optional, we can define this automatically

 # Serializes object with params context
  UserSerializer.to_h(user, params: params)

  # Add some meta
  UserSerializer.to_h(user, meta: { some: :thing })

  # Using cache
  UserSerializer.to_str(user, cache: cache) # more about caching below

  # We can also initialize serializer and reuse it
  serializer = UserSerializer.new(context)
  serializer.to_h(user1)
  serializer.to_h(user2)
```

### Redefining attributes
All attributes and relationships are delegated to serialized object.
This can be changed by providing a `key:` or a block.

Redefine attribute example:
```ruby
  class UserSerializer < Jat
    # By key
    attribute(:email, key: :confirmed_email) # `user.confirmed_email` will be executed

    # By block
    # We can use `object` and `context` variables
    attribute(:email) { object.confirmed_email }

    # By block with one or two args (aliases for `object` and `context`)
    attribute(:email) do |user, ctx|
      user.confirmed_email if ctx[:controller_name] == 'CurrentUserController'
    end
  end
```

Redefine relationship example:
```ruby
  class UserSerializer < Jat
    # By key
    relationship(:comments, key: :published_comments...) # will use `user.published_comments`

    # By block
    relationship(:comments) { object.published_comments }

    # By block with renamed `object` and `context` varaibles
    relationship(:comments) do |user, _ctx|
      context[:current_user] == user ? user.comments : user.published_comments
    end
  end
```

### Exposing Attributes
By default all attributes are exposed, and all relationships are hidden, we
can change this on per-attribute basis or by global config.

```ruby
  class UserSerializer < Jat
    config.exposed = :default # :default, :all, :none

    attribute :first_name, exposed: false

    relationship :profile, serializer: -> { ProfileSerializer }, exposed: true
  end
```

## Auto Preload
We can tell which associations we want to preload for any attribute or relationship.

- `preload` can be complex value consisting of hashes and arrays
- `preload`s are merged together only for returned fields
- `preload` can be disabled by providing `preload: false / nil` - helpfull for non-ActiveRecord relationships
- relationships do `preload` self name by default
- works with ActiveRecord scope, ActiveRecord object, Array of ActiveRecord  objects

```ruby
  class UserSerializer < Jat
    attribute :current_email, preload: :emails

    relationship :profile, expose: true, serializer: -> { ProfileSerializer } # preloads :profile by default
    relationship :comments, expose: true, serializer: -> { CommentSerializer } # preloads :comments by default
  end

  class CommentSerializer < Jat
    relationship :images, expose: true, serializer: -> { ImagesSerializer }, preload: { images_attachments: :blob }
  end

  serializer = UserSerializer.to_h(users)
  # Executes `users.preload(:emails, :profile, comments: { images_attachments: :blob })` before processing
```

Tips:
 - We can run `someSerializer.new(params: params)._preloads` to find what we will `preload`.

## Limit Response Fields
Client can provide `fields` and `include` parameters to change response fields.

Parameters have same format as in JSON-api specification:
- `fields` - https://jsonapi.org/format/#fetching-sparse-fieldsets
- `include` - https://jsonapi.org/format/#fetching-includes

Fields should be provided as hash where keys are serializers `types` and values combinded with comma:
```ruby
UserSerializer.to_h(user, params: { fields: { user: `first_name,last_name`, comments: `text,images` } })
```

`include` parameter must be a string that contains different relations that should be included to main requested resource. Relationships should be combined with ',', nested relationships combined with '.':
```ruby
UserSerializer.to_h(user, params: { include: `profile,comments.images` } })
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

### Camel Lower Option
We can transfrom all keys to `camelLower` case

```ruby
  class UserSerializer < Jat
    config.key_transform = :camelLower
    # or
    config.key_transform = :none # default
  end
```

### JSON Encoder Option
We need this to serialize to string with maximum efficiency.
Default encoder is a standard JSON module.
Serialization to string via `serializer.to_str` will be best choice together with *caching* to not re-encode each cached response.

```ruby
  Jat.config.to_str = ->(data) { Oj.dump(data, mode: :compat) } # changed JSON.dump to Oj
```

### Global Meta
We can configure meta globally to be added to all responses.
We will not add meta when it has `nil` value. This way we can skip adding meta when conditions were not met.

```ruby
  # We can add static value
  Jat.config.meta[:version] = '1.2.3'

  # We can add dynamic value
  Jat.config.meta[:is_admin] = ->(records, context) do
    return unless context[:current_user].admin? # skip adding meta `is_admin` key
    true
  end
```

## Inheritance
When you inherit serializer, child copies parent config, type, attributes and
relationships.

## Caching
You should provide callable cache instance.
This instance is responsible for constructing cache key and calling `your-cache-adapter.fetch { yield }`.
It should accept provided serialized objects and context and it should yield provided block.

Performance tip:
- use `to_str` method when caching to save time for re-encoding hash

Example:
```ruby
  class SerializersCache
    def self.call(objects, context, &block)
      return if context[:params][:no_cache] # We can return falsey value to skip caching

      # Some code to construct cache key, usually you want to use:
      # - objects.cache_key (for ActiveRecord)
      # - context[:params][:fields]
      # - context[:params][:include]
      # - context[:format] # added by Jat - can be `:hash` or `:string`
      cache_key = '...'

      Rails.cache.fetch(cache_key, expires_in: 5.minutes) { block.() }
    end
  end

  UserSerializer.to_str(users, cache: SerializersCache, **context)
  # or
  UserSerializer.to_h(users, cache: SerializersCache, **context)
```

## Paging
There are no specific stuff to implement paging, we can just use `meta`

```ruby
  # config/initializers/jat.rb
  #
  Jat.config.meta[:paging] = ->(records, _context) do
    break unless records.is_a?(Enumerable)
    break unless records.respond_to?(:total_count)

    {
      total_count: records.total_count
      size: records.size,
      offset_value: records.offset_value,
    }
  end
```
