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
  class UsersSerializer < Jat
    type :users
    attribute :first_name
    attribute :last_name
    relationship :profile, serializer: ProfileSerializer
    relationship :roles, serializer: RolesSerializer, many: true
  end

  # Serializes single object without params
  UsersSerializer.to_h(user)
  UsersSerializer.to_str(user)

  # Serializes multiple objects without params
  UsersSerializer.to_h(users, many: true)
  UsersSerializer.to_str(users, many: true)

 # Serializes single object with params
  UsersSerializer.to_h(user, params: params)
  UsersSerializer.to_str(user, params: params)

  # Serializes multiple objects with params
  UsersSerializer.to_h(users, params: params, many: true)
  UsersSerializer.to_str(users, params: params, many: true)

  # Add some meta
  UsersSerializer.to_h(user, params: params, meta: { some: :thing })
  UsersSerializer.to_str(user, params: params, meta: { some: :thing })

  # We can save a little time on parsing params by creating serializer instance
  # and reusing it. No sence to do it with single serialization for single request.
  serializer = UsersSerializer.new(params)
  serializer.to_h(user1, opts_without_params) # { many: ..., meta: ..., cache: ...}
  serializer.to_h(user2, opts_without_params)
```

### 1.2. Redefine how to get attribute
All attributes and relationships are delegated to serialized object.
This can be changed by providing a new key, new method or a block.

```ruby
  class UsersSerializer < Jat
    type :users

    # by key
    attribute(:email, key: :confirmed_email) # will use `user.confirmed_email`

    # by block
    attribute(:email) { |user| user.confirmed_email }

    # by block with params
    attribute(:email) do |user, params|
      user.confirmed_email if params[:controller_name] == 'CurrentUserController'
    end

    # by new method
    attribute :email, delegate: false # `delegate: false` is optional, but it fixes low-level ruby warning about next method redefining.
    def email(user, params)
      user.confirmed_email || params[:email]
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

  params = nil
  serializer.new(params).to_h(user) # will return only first_name and last_name

  params = { fields: { users: 'first_name,profile' } }
  serializer.new(params).to_h(user) # will return only first_name and profile

  params = { include: 'profile' }
  serializer.new(params).to_h(user) # will return first_name, last_name and profile
```

## 4. Global config
### 4.1 Exposed
We can set all attributes to be exposed or not by config
```ruby
  class UsersSerializer < Jat
    config.exposed = :default # this is default - attributes are exposed, relationships - not
    # or
    config.exposed = :all # all attributes and relationships are exposed
    # or
    config.exposed = :none # nothing is exposed
  end
```

### 4.2 Delegate
We can set all attributes are delegated to object or not. By default they are delegated, but disabling can be usefull when
you know object has no same name methods.
```ruby
  class UsersSerializer < Jat
    config.delegate = true # this is default - all attributes and relationships are delegated
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
Default encoder is standard JSON module. You can change this for your favourite encoder
by adding config globally or per-serializer.

```ruby
  Jat.config.to_str = ->(data) { Oj.dump(data) } # change to Oj
```

Serialization to string will be best choice together with *caching* to not
re-encode same response for each request.


## 5. Inheritance
When you inherit serializer, child copies parent config, type, attributes and
relationships.

## 6. Caching
Its very unpredictable which caching algorithm is needed in specific use case, so
we decided to remove all responsobility from us.
You have full controll over caching on a per-request basis.
First of all you need to specify callable cache instance.
We will send all params we have to it.

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
  cache = ->(objects, params, opts, format, &block) do # It can be some callable class
    break if opts.dig(:meta, 'some') # We can return falsey value to skip caching

    cache_key = [
      objects.cache_key,
      *['fields', *params[:fields].to_a.flatten],
      *['include', params[:include]],
      meta.to_s,
      format,
    ].join('.')

    Rails.cache.fetch(cache_key, expires_in: 1.week) { block.() }
  end

  opts = { many: true, meta: { 'some' => 'thing' } }

  UserSerializer.to_str(users, cache: cache, params: params, **opts)
  # or
  UserSerializer.to_h(users, cache: cache, params: params, **opts)
```
