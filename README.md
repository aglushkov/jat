# JAT
Jat is a serialization tool to build JSON API response.

## Why another serializer?
There is a hope this gem will make developers happy again.

## Format
Serialization format is almost like original [JSON-API](https://jsonapi.org/format/).

## Features
1. Simple DSL.
  - Quick example
  - Redefine how to get attribute
  - Exposing attributes
  - Defining has_many relationship

2. Showing associations to preload.
3. Configurable response fields.
4. Global config.
  - Exposed
  - Delegate
  - Camel Lower Keys
  - JSON encoder
  - Meta / Paging
5. Inheritance.
6. Caching

## 1. Simple DSL

### 1.1. Quick example
Each serializer must have *type*.
Also we can add attributes and relationships.

```ruby
  class UserSerializer < Jat
    type :user

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

### 1.2. Redefine attribute
All attributes and relationships are delegated to serialized object.
This can be changed by providing a new key, new method or a block.

Redefine attribute examples:
```ruby
  class UserSerializer < Jat
    type :user

    # by key
    attribute(:email, key: :confirmed_email) # will use `user.confirmed_email`

    # by block
    attribute(:email) { |user| user.confirmed_email }

    # by block with context
    attribute(:email) do |user, context|
      user.confirmed_email if context[:controller_name] == 'CurrentUserController'
    end

    # by new method
    attribute :email, delegate: false # `delegate: false` is optional, but it fixes low-level ruby warning about next method redefining.
    def email(user, context)
      user.confirmed_email || context[:email]
    end
  end
```

Redefine relationship examples:
```ruby
  class UserSerializer < Jat
    type :comments

    # by key
    relationship(:comments, key: :published_comments...) # will use `user.published_comments`

    # by block
    relationship(:comments) { |user| user.published_comments }

    # by block with context
    relationship(:comments) do |user, context|
      context[:current_user] == user ? user.comments : user.published_comments
    end

    # by new method
    relationship :comments, delegate: false

    def comments(user, context)
      context[:current_user] == user ? user.comments : user.published_comments
      user.confirmed_email || context[:email]
    end
  end
```

### 1.3. Exposing attributes
By default all attributes are exposed, and all relationships are hidden, we
can change this on per-attribute basis or by global config.

```ruby
  class UserSerializer < Jat
    config.exposed = :default # :default, :all, :none

    attribute :first_name, exposed: false

    relationship :profile, serializer: -> { ProfileSerializer }, exposed: true
  end
```

## 2. Auto preload
We can tell which associations we want to preload for any attribute or relationship.

All relationships automatically knows to preload association with its name.

It is also possible to preload hashes or arrays.

`Preloads` are merged together for all requested fields from all requested types/fields.

This `preloads` will be added to serialized object automatically via ActiveRecord's `preload`.

We can disable preloading by providing `preload: false / nil` - it should be helpfull for non ActiveRecord relationships.

```ruby
  class UserSerializer < Jat
    type :user

    attribute :current_email, preload: :emails

    relationship :profile, expose: true, serializer: -> { ProfileSerializer } # preloads :profile by default
    relationship :comments, expose: true, serializer: -> { CommentSerializer } # preloads :comments by default
  end

  class CommentSerializer < Jat
    type :comment

    relationship :images, expose: true, serializer: -> { ImagesSerializer }, preload: { images_attachments: :blob }
  end

  serializer = UserSerializer.new
  includes = serializer._preloads
  # => { emails: {}, profile: {}, comments: { images_attachments: :blob } }
```

## 3. Specifying requested fields
Client can provide `fields` and `include` params to manipulate response.
Format and examples:
- `fields` - https://jsonapi.org/format/#fetching-sparse-fieldsets
- `include` - https://jsonapi.org/format/#fetching-includes

Code example:
```ruby
  class UserSerializer < Jat
    type :user
    attribute :first_name
    attribute :last_name
    relationship :profile, serializer: -> { ProfileSerializer } # relationships are not exposed by default
  end

  context = nil
  UserSerializer.to_h(user, context) # will return only first_name and last_name

  context = { params: { fields: { users: 'first_name,profile' } } }
  UserSerializer.to_h(user, context) # will return only first_name and profile

  params = { params: { include: 'profile' } }
  UserSerializer.to_h(user, context) # will return first_name, last_name and profile
```

## 4. Global config
### 4.1 Exposed
We can set all attributes to be exposed or not by config
```ruby
  class UserSerializer < Jat
    config.exposed = :default # (default) attributes are exposed, relationships are not
    # or
    config.exposed = :all # everything is exposed
    # or
    config.exposed = :none # nothing is exposed
  end
```

### 4.2 Delegate
We can set if we need delegation or not.
By default all keys are delegated to same object attribute.
```ruby
  class UserSerializer < Jat
    config.delegate = true # (default) all keys are delegated to serialized object attributes
    # or
    config.delegate = false # nothing is delegated
  end
```

### 4.3 Camel Lower Keys
We can transfrom all keys to `camelLower` case
```ruby
  class UserSerializer < Jat
    config.key_transform = :camelLower
    # or
    config.key_transform = :none # default
  end
```

### 4.4 JSON encoder
We need this to serialize to string by Jat.
Serialization to string via `serializer.to_str` will be best choice together with *caching* to not re-encode each cached response.

Default encoder is a standard JSON module. You can change this for your favourite encoder by adding config globally or per-serializer.

```ruby
  Jat.config.to_str = ->(data) { Oj.dump(data, mode: :compat) } # change to Oj
```

### 4.5 Meta / Paging
We can configure meta globally to be added to all responses.
We will not add meta when it has `nil` value. This way we can skip adding meta when conditions were not met.

```ruby
  # We can add static value
  Jat.config.meta[:version] = '1.2.3'

  # We can add dynamic value
  Jat.config.meta[:paging] = ->(records, context) do
    break unless records.is_a?(Enumerable)
    break unless records.respond_to?(:total_count)

    {
      total_count: records.total_count
      size: records.size,
      offset_value: records.offset_value,
    }
  end
```

## 5. Inheritance
When you inherit serializer, child copies parent config, type, attributes and
relationships.

## 6. Caching
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
