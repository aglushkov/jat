# JAT
Jat is a serialization tool to build JSON API response.

## Why another serializer?
There is a hope this gem will make developers happy again.

## Format
Serialization format is almost like original [JSON-API](https://jsonapi.org/format/).

## Features
1. Simple DSL.
2. Showing associations to preload.
3. Configurable response fields.
4. Global config.
5. Inheritance.

## 1. Simple DSL

### 1.1. Define type, attributes, relationships.
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

  serializer = UsersSerializer.new
  serializer.to_h(user)
  serializer.to_h(users, many: true)
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
Any relationship be default has option `many: false`, we should redefine it:
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

### 4.1 Delegate
We can set all attributes are delegated to object or not. By default they are delegated, but disabling can be usefull when
you know object has no same name methods.
```ruby
  class UsersSerializer < Jat
    config.delegate = true # this is default - all attributes and relationships are delegated
    # or
    config.delegate = false # nothing is delegated
  end
```

## 5. Inheritance
When you inherit serializer, child copies parent config, type, attributes and
relationships.
