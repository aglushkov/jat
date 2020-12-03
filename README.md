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

    relationship :profile, serializer: ProfileSerializer
    relationship :roles, serializer: RoleSerializer, many: true
  end

  # Serializes single object
  UsersSerializer.to_h(user)
  UsersSerializer.to_str(user)

  # Serializes multiple objects
  UsersSerializer.to_h(users, many: true)
  UsersSerializer.to_str(users, many: true)

 # Serializes single object with params context
  UsersSerializer.to_h(user, params: params)
  UsersSerializer.to_str(user, params: params)

  # Serializes multiple objects with params context
  UsersSerializer.to_h(users, params: params, many: true)
  UsersSerializer.to_str(users, params: params, many: true)

  # Add some meta
  UsersSerializer.to_h(user, params: params, meta: { some: :thing })
  UsersSerializer.to_str(user, params: params, meta: { some: :thing })

  # We also can initialize serializer and reuse it
  serializer = UsersSerializer.new(context)
  serializer.to_h(user1)
  serializer.to_h(user2)
```

### 1.2. Redefine attribute
All attributes and relationships are delegated to serialized object.
This can be changed by providing a new key, new method or a block.

Attributes redefining examples:
```ruby
  class UsersSerializer < Jat
    type :users

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

Relationships redefining examples:
```ruby
  class UserSerializer < Jat
    type :comments

    # by key
    relationship(:comments, key: :published_comments, many: true...) # will use `user.published_comments`

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
can change this on per-attribute basis
```ruby
  class UsersSerializer < Jat
    attribute :first_name, exposed: false
    relationship :profile, serializer: ProfileSerializer, exposed: true
  end
```

### 1.4. Defining has_many relationship
Any relationship by default has option `many: false`, we should redefine it:
```ruby
  class UsersSerializer < Jat
    relationship :roles, serializer: RolesSerializer, many: true
  end
```

## 2. Show associations to preload
We can tell which associations we want to preload for any attribute or relationship.
All relationships automatically knows to preload association with self name.
We can disable it by providing `{ includes: nil }`.
```ruby
  class UsersSerializer < Jat
    type :users
    attribute(:comments_count, includes: :users_stats) do |user|
      user.users_stats.comments_count
    end
    relationship :profile, serializer: ProfileSerializer
  end

  serializer = UsersSerializer.new
  includes = serializer._includes # => { users_stats: {}, profile: {} }

  user = User.includes(includes).find_by(...)
  serializer.to_h(user)
```

## 3. Client can request needed fields
Client can provide `fields` and `include` params to manipulate response.
Format and examples:
- `fields` - https://jsonapi.org/format/#fetching-sparse-fieldsets
- `include` - https://jsonapi.org/format/#fetching-includes

Code example:
```ruby
  class UsersSerializer < Jat
    type :users
    attribute :first_name
    attribute :last_name
    relationship :profile, serializer: ProfileSerializer # relationships are not exposed by default
  end

  context = nil
  UsersSerializer.to_h(user, context) # will return only first_name and last_name

  context = { params: { fields: { users: 'first_name,profile' } } }
  UsersSerializer.to_h(user, context) # will return only first_name and profile

  params = { params: { include: 'profile' } }
  UsersSerializer.to_h(user, context) # will return first_name, last_name and profile
```

## 4. Global config
### 4.1 Exposed
We can set all attributes to be exposed or not by config
```ruby
  class UsersSerializer < Jat
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
  class UsersSerializer < Jat
    config.delegate = true # (default) all keys are delegated to serialized object attributes
    # or
    config.delegate = false # nothing is delegated
  end
```

### 4.3 Camel Lower Keys
We can transfrom all keys to `camelLower` case
```ruby
  class UsersSerializer < Jat
    config.key_transform = :camelLower
    # or
    config.key_transform = :none # default
  end
```

### 4.4 JSON encoder
Default encoder is standard JSON module. You can change this for your favourite encoder by adding config globally or per-serializer.

```ruby
  Jat.config.to_str = ->(data) { Oj.dump(data) } # change to Oj
```

Serialization to string via `serializer#to_str` method will be best choice together with *caching* to not re-encode each cached response.

### 4.4 Meta
We can configure meta globally to be added to all responses.
We will not add meta when it has `nil` value. This way we can skip adding meta when conditions were not met.

```ruby
  # We can add static value
  Jat.config.meta[:version] = '1.2.3'

  # We can add dynamic value
  Jat.config.meta[:paging] = ->(records, context) do
    break unless context[:many]
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
You have full controll over caching on a per-request basis.
First of all you need to specify callable cache instance.

Performance tips:
- use `to_str` method when caching to save time for contructing and re-encoding hash
- change JSON adapter to dump json by `Jat.config.to_str = ->(data) { Oj.dump(data) }`

Example
```ruby
  # objects - Currently serialized object(s).
  # params - We can get `fields` and `include` params here to construct cache key.
  # opts   - We can use some opts to construct cache key or skip caching.
  # format - contains `:hash` or `:string` depending on serialization method.
  # &block - you should call it without arguments to generate response.
  cache = ->(objects, context, &block) do
    break if context[:no_cache] # We can return falsey value to skip caching

    # Some code to construct cache key, usually we will use:
    # - objects.cache_key (for ActiveRecord)
    # - context[:params][:fields]
    # - context[:params][:include]
    # - context[:format] # added by Jat - can be `:hash` or `:string`
    cache_key = '...'

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) { block.() }
  end

  UserSerializer.to_str(users, cache: cache, **context)
  # or
  UserSerializer.to_h(users, cache: cache, **context)
```
