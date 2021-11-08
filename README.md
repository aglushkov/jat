# JAT (JSON API TOOLKIT)

JAT helps to serialize objects to Hash format.

## Supported Formats

  - [JSON:API]
  - [SIMPLE:API]

## Key Features:

* Configurable exposing of attributes
* Auto preload (currently only with ActiveRecord, but more to come)
* Modular design – plugin system allows you to load only functionality you need

## Plugins

* **plugin :json_api** - enables JSON:API response formatting
* **plugin :simple_api** - enables SIMPLE:API response formatting
* **plugin :preloads** - adds method to show relationships names that will be loaded during serialization
* **plugin :activerecord** - automatically preloads nested relationships to serializaed objects before serialization.
* **plugin :cache** - allows to cache response
* **plugin :to_str** - allows to serialize to json string
* **plugin :lower_camel_case** - transaforms all attributes to lowerCamelCase

## Quick Examples
<details>
  <summary>JSON:API format example</summary>

```ruby
class JsonapiSerializer < Jat
  plugin :json_api
end

class UserSerializer < JsonapiSerializer
  type :user

  attribute :id
  attribute(:name) { |user| [user.first_name, user.last_name].join(" ") }

  attribute :profile, serializer: -> { ProfileSerializer }, exposed: true
  attribute :roles, serializer: -> { RoleSerializer }, exposed: true
end

class ProfileSerializer < JsonapiSerializer
  type :profile

  attribute :id
  attribute(:location) { |profile| profile.location || "Gotham City" }
  attribute :followers_count
end

class RoleSerializer < JsonapiSerializer
  type :role

  attribute :id
  attribute :name
end

role1 = OpenStruct.new(id: 4, name: "superhero")
role2 = OpenStruct.new(id: 3, name: "reporter")
profile = OpenStruct.new(id: 2, followers_count: 999, location: nil)
user = OpenStruct.new(id: 1, first_name: "Clark", last_name: "Kent", profile: profile, roles: [role1, role2])

response = UserSerializer.to_h(user)
puts JSON.pretty_generate(response)
```

```json
{
  "data": {
    "type": "user",
    "id": 1,
    "attributes": {
      "name": "Clark Kent"
    },
    "relationships": {
      "profile": {
        "data": {
          "type": "profile",
          "id": 2
        }
      },
      "roles": {
        "data": [
          {
            "type": "role",
            "id": 4
          },
          {
            "type": "role",
            "id": 3
          }
        ]
      }
    }
  },
  "included": [
    {
      "type": "profile",
      "id": 2,
      "attributes": {
        "location": "Gotham City",
        "followers_count": 999
      }
    },
    {
      "type": "role",
      "id": 4,
      "attributes": {
        "name": "superhero"
      }
    },
    {
      "type": "role",
      "id": 3,
      "attributes": {
        "name": "reporter"
      }
    }
  ]
}
```
</details>

<details>
  <summary>Simple:API format example</summary>

```ruby
class SimpleSerializer < Jat
  plugin :simple_api
end

class UserSerializer < SimpleSerializer
  root :users

  attribute :id
  attribute(:name) { |user| [user.first_name, user.last_name].join(" ") }

  attribute :profile, serializer: -> { ProfileSerializer }, exposed: true
  attribute :roles, serializer: -> { RoleSerializer }, exposed: true
end

class ProfileSerializer < SimpleSerializer
  attribute :id
  attribute(:location) { |profile| profile.location || "Gotham City" }
  attribute :followers_count
end

class RoleSerializer < SimpleSerializer
  attribute :id
  attribute :name
end

role1 = OpenStruct.new(id: 4, name: "superhero")
role2 = OpenStruct.new(id: 3, name: "reporter")
profile = OpenStruct.new(id: 2, followers_count: 999, location: nil)
user = OpenStruct.new(id: 1, first_name: "Clark", last_name: "Kent", profile: profile, roles: [role1, role2])

response = UserSerializer.to_h(user)
puts JSON.pretty_generate(response)
```

```json
{
  "users": {
    "id": 1,
    "name": "Clark Kent",
    "profile": {
      "id": 2,
      "location": "Gotham City",
      "followers_count": 999
    },
    "roles": [
      {
        "id": 4,
        "name": "superhero"
      },
      {
        "id": 3,
        "name": "reporter"
      }
    ]
  }
}
```
</details>

## Plugins

Plugins can be enabled on `Jat` class itself or inside any subclass
```ruby
Jat.plugin :simple_api
Jat.plugin :json_api
Jat.plugin :cache 
Jat.plugin :lower_camel_case
Jat.plugin :to_str

# or 

class BaseSerializer < Jat
  Jat.plugin :simple_api 
  Jat.plugin :cache 
  Jat.plugin :lower_camel_case
  Jat.plugin :to_str
end
```

### Attributes
All attributes are delegated to serialized object. 
Attributes will be inherited by subclasses, but they can be redefined there.

```ruby
class UserSerializer < Jat
  # We will serialize `object.email`
  attribute(:email)

  # We will serialize `object.confirmed_email`
  attribute(:email, key: :confirmed_email)
  
  # When we provide block without args, we have access to `object` and `context` public methods inside block
  attribute(:email) { object.confirmed_email } 
  
  # We can define block with arguments
  attribute(:email) { |user| user.confirmed_email } # `object` wil be used as first argument
  
  # We have access to named context as well 
  attribute(:email) { |user, ctx| user.confirmed_email || ctx[:email] }
end
```

### Relationships
Relationships are also _attributes_, but with `:serializer` option. It should be defined as lambda. 

```ruby
class UserSerializer < Jat
  # We will serialize `object.profile`
  attribute :profile, serializer: -> { ProfileSerializer }

  # We will serialize `object.main_profile`
  attribute :profile, key: :main_profile, serializer: -> { ProfileSerializer }

  # We can define block to find needed record
  attribute(:profile, serializer: -> { ProfileSerializer }) do |user, _ctx|
    user.profiles.select(&:last)
  end 
end
```

### JSON:API Relationships
JSON:API plugin has additional `.relationship` method that forces adding serializer option.

```ruby
Jat.plugin :json_api
class UserSerializer < Jat
  # Same as:
  #  attribute :profile, serializer: -> { ProfileSerializer }
  relationship :profile, serializer: -> { ProfileSerializer }
end
```

### Configure exposed attributes & relationships

Rule of thumb:
- _attributes_ are **exposed by default**
- _relationships_ are **hidden by default**

We have 3 ways to change this rule:

1. We can add `config[:exposed]=:all/:none/:deafult` config option to set default exposed value for all attributes/relationships in current serializer.
    ```ruby
      class UserSerializer < Jat
        config[:exposed] = :none # or :all
        
        attribute :email
        attribute :avatar, serializer: { AvatarSerializer }
      end
    ```
2. We can add `exposed: true/false` option per attribute. Per-attribute `exposed` options have precendence over `config[:exposed]` option.
    ```ruby
      class UserSerializer < Jat
        attribute :email, exposed: false 
        attribute :avatar, serializer: { AvatarSerializer }, exposed: true
      end
    ```
3. We can add `{ exposed: :all/:none }` context when serializing object. This context option has precendence over per-attributes `:exposed` values. It changes exposed attributes in current serializer and all relationships. Exposed `:none` is useful only in combination with parameters which additionally specifies exposed attributes, if you want full control over each serialized attribute.
    ```ruby
      UserSerializer.to_h(user, exposed: :all)
      # or
      UserSerializer.to_h(user, exposed: :none, params: { ... })
    ```

<details>
  <summary>Example of changing exposed attributes in Simple:API</summary>

```ruby
# frozen_string_literal: true

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "jat", "~> 0.0.3"
end

class SimpleSerializer < Jat
  plugin :simple_api
end

class UserSerializer < SimpleSerializer
  config[:exposed] = :default # Default value can be omitted. Other options: :all, :none

  # Attributes are exposed by default
  attribute :name

  # Hide exposed by default attribute
  attribute :email, exposed: false

  # Relationships are hidden by default
  attribute :profile, serializer: -> { ProfileSerializer }

  # Expose hidden by default relationship
  attribute :avatar, serializer: -> { AvatarSerializer }, exposed: true
end

class AvatarSerializer < SimpleSerializer
  attribute :url
  attribute :url_2x
end

class ProfileSerializer < SimpleSerializer
  attribute :id
end

require "ostruct"
avatar = OpenStruct.new(url: "http://example.com/url", url_2x: "http://example.com/url_2x")
profile = OpenStruct.new(id: 2)
user = OpenStruct.new(id: 1, name: "batman", avatar: avatar, email: "janedoe@example.com", profile: profile)

require "json"

puts "UserSerializer.to_h(user, exposed: :default)"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :default))

puts

puts "UserSerializer.to_h(user, exposed: :all)"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :all))

puts

puts "UserSerializer.to_h(user, exposed: :none, params: { fields: 'name,email' })"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :none, params: {fields: "name,email"}))
```
 
```jsonc
UserSerializer.to_h(user, exposed: :default)
{
  "name": "batman",
  "avatar": {
    "url": "http://example.com/url",
    "url_2x": "http://example.com/url_2x"
  }
}

UserSerializer.to_h(user, exposed: :all)
{
  "name": "batman",
  "email": "janedoe@example.com",
  "profile": {
    "id": 2
  },
  "avatar": {
    "url": "http://example.com/url",
    "url_2x": "http://example.com/url_2x"
  }
}

UserSerializer.to_h(user, exposed: :none, params: { fields: 'name,email' })
{
  "name": "batman",
  "email": "janedoe@example.com"
}
```
</details>

<details>
  <summary>Example of changing exposed attributes in JSON:API</summary>

```ruby
# frozen_string_literal: true

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "jat", "~> 0.0.3"
end

class JsonapiSerializer < Jat
  plugin :json_api
end

class UserSerializer < JsonapiSerializer
  config[:exposed] = :default # Default value can be omitted. Other options: :all, :none

  type :user
  attribute :id

  # Attributes are exposed by default
  attribute :name

  # Hide exposed by default attribute
  attribute :email, exposed: false

  # Relationships are hidden by default
  relationship :profile, serializer: -> { ProfileSerializer }

  # Expose hidden by default relationship
  relationship :avatar, serializer: -> { AvatarSerializer }, exposed: true
end

class AvatarSerializer < JsonapiSerializer
  config[:exposed] = :none
  type :avatar

  attribute :id, exposed: true
  attribute :url, exposed: true
  attribute :url_2x
end

class ProfileSerializer < JsonapiSerializer
  type :profile
  attribute :id
end

require "ostruct"
avatar = OpenStruct.new(id: 3, url: "http://example.com/url", url_2x: "http://example.com/url_2x")
profile = OpenStruct.new(id: 2)
user = OpenStruct.new(id: 1, name: "batman", avatar: avatar, email: "janedoe@example.com", profile: profile)

require "json"

puts "UserSerializer.to_h(user, exposed: :default)"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :default))

puts

puts "UserSerializer.to_h(user, exposed: :all)"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :all))

puts

puts "UserSerializer.to_h(user, exposed: :none, params: { fields: { user: 'name,email' }})"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :none, params: {fields: {user: "name,email"}}))
```
 
```jsonc
UserSerializer.to_h(user, exposed: :default)
{
  "data": {
    "type": "user",
    "id": 1,
    "attributes": {
      "name": "batman"
    },
    "relationships": {
      "avatar": {
        "data": {
          "type": "avatar",
          "id": 3
        }
      }
    }
  },
  "included": [
    {
      "type": "avatar",
      "id": 3,
      "attributes": {
        "url": "http://example.com/url"
      }
    }
  ]
}

UserSerializer.to_h(user, exposed: :all)
{
  "data": {
    "type": "user",
    "id": 1,
    "attributes": {
      "name": "batman"
    },
    "relationships": {
      "avatar": {
        "data": {
          "type": "avatar",
          "id": 3
        }
      }
    }
  },
  "included": [
    {
      "type": "avatar",
      "id": 3,
      "attributes": {
        "url": "http://example.com/url"
      }
    }
  ]
}

UserSerializer.to_h(user, exposed: :none, params: { fields: { user: 'name,email' }})
{
  "data": {
    "type": "user",
    "id": 1,
    "attributes": {
      "name": "batman",
      "email": "janedoe@example.com"
    }
  }
}
```
</details>

[shrine]: https://shrinerb.com/docs/getting-started#plugin-system
[JSON:API]: https://jsonapi.org/format/
[AMS]: https://github.com/rails-api/active_model_serializers/tree/0-9-stable
[Jbuilder]: https://github.com/rails/jbuilder

### Meta

### Reques
