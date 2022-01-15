[![GitHub Actions](https://github.com/toptal/chewy/actions/workflows/ruby.yml/badge.svg)](https://github.com/toptal/chewy/actions/workflows/ruby.yml)

# JAT (JSON API TOOLKIT)

JAT helps to serialize objects to Hash format.

## Supported Formats

  - JSON:API - official [JSON:API] format. [JSON:API README].
  - SIMPLE:API - regular nested structs. [SIMPLE:API README].

## Key Features

* Configurable exposing of attributes
  By default we we will serialize only direct attributes of serialized objects and exposing relationships is configurable.

* Auto preload of relationships with `:activerecord` plugin.
  For those who have no activerecord, there are `:preloads` plugin that shows nested hash with all relationships.

* Modular design – plugin system allows you to load only functionality you need

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

  relationship :profile, serializer: -> { ProfileSerializer }, exposed: true
  relationship :roles, serializer: -> { RoleSerializer }, exposed: true
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

  relationship :profile, serializer: -> { ProfileSerializer }, exposed: true
  relationship :roles, serializer: -> { RoleSerializer }, exposed: true
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

## Supported rubies

  Ruby versions:

  - MRI 2.5
  - MRI 2.6
  - MRI 2.7
  - MRI 3.0
  - MRI 3.1
  - jruby 9.3.2
  - truffleruby 21.3.0

  ActiveRecord versions:

  - 5.2
  - 6.1
  - 7.0


[JSON:API]: https://jsonapi.org/format/
[JSON:API README]: doc/JSON_API.md
[SIMPLE:API README]:  doc/SIMPLE_API.md
