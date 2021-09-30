# JAT (JSON API TOOLKIT)

JAT helps to serialize complex nested objects to JSON format.

Key features:

* **Auto preload** – No need to preload data manually to omit N+1 (Active Record only)
* **Configurable exposed attributes** – No more tons of serializers with different attributes sets
* **Modular design** – plugin system (aka [shrine]) allows you to load only the functionality you need

## Output Format

Supported two serialization formats:
  - [JSON:API]
  - Simple:API (it is just nested JSON objects, same response format as constructed by good old [AMS] or [Jbuilder])

## Quick Examples
<details>
  <summary>JSON:API format example</summary>

```ruby
role1 = OpenStruct.new(id: 4, name: 'superhero')
role2 = OpenStruct.new(id: 3, name: 'reporter')
profile = OpenStruct.new(id: 2, followers_count: 999, location: nil)
user = OpenStruct.new(id: 1, first_name: 'Clark', last_name: 'Kent', profile: profile, roles: [role1, role2])

class BaseSerializer < Jat
  plugin :json_api, activerecord: false # or true to preload relations automatically
end

class UserSerializer < BaseSerializer
  type :user

  attribute :id
  attribute(:name) { |user| [user.first_name, user.last_name].join(' ') }

  attribute :profile, serializer: -> { ProfileSerializer }, exposed: true
  attribute :roles, serializer: -> { RoleSerializer }, exposed: true
end

class ProfileSerializer < BaseSerializer
  type :profile

  attribute :id
  attribute(:location) { |profile| profile.location || 'Gotham City' }
  attribute :followers_count
end

class RoleSerializer < BaseSerializer
  type :role

  attribute :id
  attribute :name
end

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
role1 = OpenStruct.new(id: 4, name: 'superhero')
role2 = OpenStruct.new(id: 3, name: 'reporter')
profile = OpenStruct.new(id: 2, followers_count: 999, location: nil)
user = OpenStruct.new(id: 1, first_name: 'Clark', last_name: 'Kent', profile: profile, roles: [role1, role2])

class BaseSerializer < Jat
  plugin :simple_api, activerecord: false # or true to preload relations automatically
end

class UserSerializer < BaseSerializer
  root :users

  attribute :id
  attribute(:name) { |user| [user.first_name, user.last_name].join(' ') }

  attribute :profile, serializer: -> { ProfileSerializer }, exposed: true
  attribute :roles, serializer: -> { RoleSerializer }, exposed: true
end

class ProfileSerializer < BaseSerializer
  attribute :id
  attribute(:location) { |profile| profile.location || 'Gotham City' }
  attribute :followers_count
end

class RoleSerializer < BaseSerializer
  attribute :id
  attribute :name
end

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

## DSL

### Plugins

Plugins can be enabled on `Jat` class itself or inside any subclass
```ruby
Jat.plugin :json_api 
Jat.plugin :cache 
Jat.plugin :camel_lower
Jat.plugin :to_str

# or 

class BaseSerializer < Jat
  Jat.plugin :simple_api 
  Jat.plugin :cache 
  Jat.plugin :camel_lower
  Jat.plugin :to_str
end
```

### Attributes
All attributes are delegated to serialized object. We can define attributes in various of simple ways. \
Attributes will be inherited by subclasses, but they can be redefined there.

```ruby
class UserSerializer < Jat
  # We will serialize `object.confirmed_email`
  attribute(:email, key: :confirmed_email)

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

[shrine]: https://shrinerb.com/docs/getting-started#plugin-system
[JSON:API]: https://jsonapi.org/format/
[AMS]: https://github.com/rails-api/active_model_serializers/tree/0-9-stable
[Jbuilder]: https://github.com/rails/jbuilder
