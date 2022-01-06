# JSON:API

JSON:API is a standard format described at https://jsonapi.org/.

<details>
  <summary>JSON:API FORMAT EXAMPLE</summary>

  ```ruby
  class JsonapiSerializer < Jat
    plugin :json_api
  end

  class UserSerializer < JsonapiSerializer
    config[:exposed] = :default # Default value can be omitted. Other options: :all, :none

    type :user

    attribute(:name) { |user| [user.first_name, user.last_name].join(" ") }

    relationship :profile, serializer: -> { ProfileSerializer }, exposed: true
    relationship :roles, serializer: -> { RoleSerializer }, exposed: true
  end

  class ProfileSerializer < JsonapiSerializer
    type :profile

    attribute(:location) { |profile| profile.location || "New York City" }
    attribute :followers_count
  end

  class RoleSerializer < JsonapiSerializer
    type :role

    attribute :name
  end

  require "ostruct"
  role1 = OpenStruct.new(id: 4, name: "superhero")
  role2 = OpenStruct.new(id: 3, name: "reporter")
  profile = OpenStruct.new(id: 2, followers_count: 999, location: nil)
  user = OpenStruct.new(id: 1, first_name: "Clark", last_name: "Kent", profile: profile, roles: [role1, role2])

  response = UserSerializer.to_h(user)

  require "json"
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

## Table of Contents
* [Activation]
* [Serialization]
* [DSL]
  * [Type and ID]
  * [Attribute]
  * [Relationship]
  * [Config]
  * [Meta]
    * [Document Meta]
    * [Object Meta]
    * [Relationship Meta]
  * [Links]
    * [Document Links]
    * [Object Links]
    * [Relationship Links]
  * [Jsonapi]
* [Plugins]
  * [Preloads]
  * [Activerecord]
  * [Validate Params]
  * [Serializing to String]
  * [Caching]
  * [Lower Camel Case]
  * [Internal Cache]
* [Miscellaneous]
  * [Configure Exposed Attributes]
  * [Paging]


## Activation
  JSON:API is activated by adding `plugin :json_api`

  ```ruby
    class ResponseSerializer < Jat
      plugin :json_api

      # Other plugins
      plugin :activerecord # auto preload
      plugin :validate_params # adds validate methods that check context[:fields]
      plugin :to_str # allows to serialize object to JSON string
      plugin :cache # allows to provide context[:cache] to cache response
      plugin :maps_cache # improves serialization performance by caching some internal data in class variables
      plugin :lower_camel_case # automatically transforms all attribute to lowerCamelCase.
    end
  ```

## Serialization
  Serializer accepts object and context parameters.
  ```ruby
    ResponseSerializer.to_h(object, context) # context is optional, empty hash by default
  ```

  If `context` is constant, then performance can be slightly improved by saving serializer instance in some variable and reusing it.
  ```ruby
    serializer = ResponseSerializer.new(context)
    serializer.to_h(object)
  ```

  Serializer detects if we serialize one object or a list by checking `object.is_a?(Enumerable)`, but we can configure this directly via context `:many` option
  ```ruby
    ResponseSerializer.to_h(objects, many: true)
  ```

  Context has three system options that configures attributes to serialize:
  * `:exposed` - allows to expose all or no attributes. Allowed values are `:all`, `:none`, `:default`.
  * `:fields` - [Sparse Fieldsets]
  * `:include` - [Inclusion of Related Resources]
  ```ruby
    ResponseSerializer.to_h(
      objects,
      exposed: :none,
      fields: {user: 'name,surname', address: 'line1,line2', profile: 'bio'}
      includes: 'profile,addresses.some_nested_relationship'
  ```
  Look at [Configure Exposed Attributes] for more information.


## DSL
  All DSL methods are inherited by subclasses and can be redefined by subclasses.

### Type and ID
  Every JSON:API serializer must define type and id to identify resource.
  `Type` is a constant string value that must be specified. Specifying ID is not required, as usually it is `resource.id`, but it can be overwritten.

  ```ruby
    class UserSerializer < ResponseSerializer
      # Required
      type :users

      # Optional
      id(key: :id) # this is default
      id(key: :username) # Use user.username as ID
      id { |user, context| f(user, context) } # use custom function to find ID
    end
  ```

### Attribute
  ```ruby
    class UserSerializer < ResponseSerializer
      # Serializes `object.email`
      attribute(:email)

      # Serializes `object.confirmed_email`
      attribute(:email, key: :confirmed_email)

      # When provided block without args, we can specify direct value
      attribute(:email) { 'example@example.com '}

      # Define block with object argument
      attribute(:email) { |user| user.confirmed_email }

      # Define block with object and context arguments
      attribute(:email) { |user, ctx| user.confirmed_email || ctx[:email] }
    end
  ```

### Relationship
  `relationship` is an alias of `attribute`, but with forced `:serializer` option. If two serializers have cross referenced relationships, they should be defined as callable lambdas.

  ```ruby
    class UserSerializer < ResponseSerializer
      # Serializes `object.profile`
      relationship :profile, serializer: ProfileSerializer

      # Serializes `object.main_profile`
      relationship :profile, key: :main_profile, serializer: -> { ProfileSerializer }

      # Serializes result of block execution
      relationship(:profile, serializer: -> { ProfileSerializer }) do |user, _ctx|
        user.profiles.select(&:last)
      end
    end
  ```

  We can manually specify if relationship returns one object or a list by adding `:many` option. By default we will check `is_a?(Enumerable)` on serialized object.
  ```ruby
    class UserSerializer < ResponseSerializer
      # Serializes `object.profile`
      relationship :profile, serializer: ProfileSerializer, many: false
      relationship :addresses, serializer: AddressSerializer, many: true
    end
  ```

### Config
  We can change or check config options this way:

  ```ruby
    class UserSerializer < ResponseSerializer
      config[:foo] = :bar # add config option
    end

    UserSerializer.config # show current config
  ```

### Meta
  JSON:API allow to place meta at any of three response levels:

    - Document Meta
    - Relationship meta
    - Object meta

  Example of all levels of meta
  ```jsonp
  {
    meta: {} # Top level meta,
    data: {
      type: 'type',
      id: 'id',
      attributes: [],
      relationships: {
        nested_resource: {
          meta: {} # Relationship meta
        }
      },
      meta: {} # Object meta
    },
  }
  ```

#### Document Meta
  `document_meta` specifies top-level metadata attribute. There are only main serializer document meta in response. If nested relationships define some document_meta, it will not be shown in response. Meta attribute will be skipped if block returns nil.

  https://jsonapi.org/format/#document-meta

  ```ruby
  class UserSerializer < ResponseSerializer
    document_meta(:version) { '1.2.3' }
    document_meta(:paging) { |objects, context| ... } # access to serialized object(s) or context
  end
  ```

  📌 Document metadata can be added by specifying `:meta` context option. Meta defined in context have precedence over meta defined in serializer.

  Example:
  ```ruby
    # {
    #   data: { ... },
    #   meta: { version: '2.0' }
    # }
    UserSerializer.to_h(user, meta: { version: '2.0' })
  ```

  #### Relationship Meta
  `relationship_meta` specifies metadata attribute that is placed in relationships objects. Meta attribute will be skipped if block returns nil.

  https://jsonapi.org/format/#document-resource-object-relationships

  ```ruby
  class UserSerializer < ResponseSerializer
    relationship_meta(:foo) { 'bar' }
    relationship_meta(:foo) { |objects, context| ... } # access to serialized object(s) or context
  end
  ```

  #### Object Meta
  `object_meta` specifies metadata attribute that is placed in objects. Meta attribute will be skipped if block returns nil.

  https://jsonapi.org/format/#document-resource-object-relationships

  ```ruby
  class UserSerializer < ResponseSerializer
    object_meta(:foo) { 'bar' }
    object_meta(:foo) { |object, context| ... } # access to serialized object or context
  end
  ```

### Links
  JSON:API allow to place links at any of three response levels:

    - Document links
    - Relationship links
    - Object links

  Example of all levels of links
  ```jsonp
  {
    links: {} # Top level links,
    data: {
      type: 'type',
      id: 'id',
      attributes: [],
      relationships: {
        nested_resource: {
          links: {} # Relationship links
        }
      },
      links: {} # Object links
    },
  }
  ```

#### Document Links
  `document_meta` specifies top-level links attribute. There are only main serializer document_links in response. If nested relationships define some document_link, it will not be shown in response. Link will be skipped if block returns nil.

  https://jsonapi.org/format/#document-top-level

  ```ruby
  class UserSerializer < ResponseSerializer
    document_link(:self) do |user, context|
      context[:action] == 'index' ? '/users' : "/user/#{user.username}"
    end
  end
  ```

  📌 Document top-level links can be added by specifying `:links` context option. Links defined in context have precedence over links defined in serializer.

  Example:
  ```ruby
    # {
    #   data: { ... },
    #   links: { current: '/user/123' }
    # }
    UserSerializer.to_h(user, links: { current: '/user/123' })
  ```

  #### Relationship Links
  `relationship_link` specifies link that is placed in relationships objects. Link will be skipped if block returns nil.

  https://jsonapi.org/format/#document-resource-object-linkage

  ```ruby
  class UserSerializer < ResponseSerializer
    relationship_link(:foo) { 'bar' }
    relationship_link(:foo) { |objects, context| ... } # access to serialized object(s) or context
  end
  ```

  #### Object Links
  `object_link` specifies link that is placed in objects. Link will be skipped if block returns nil.

  https://jsonapi.org/format/#document-resource-objects

  ```ruby
  class UserSerializer < ResponseSerializer
    object_link(:self) { "/user/#{username}" }
  end
  ```

### JSONAPI
  `jsonapi` adds document jsonapi object

  https://jsonapi.org/format/#document-jsonapi-object

  ```ruby
  class UserSerializer < ResponseSerializer
    jsonapi(:version) { '1.0' }
  end
  ```

## Plugins
### Preloads
  Plugin `:preloads` adds methods to show `preloads` hash. It can be used with you favorite database ORM to omit N+1.

  All relationships by default add preloads that match current relationship key. Preloads can be changed by providing `:preload` option on any attribute or relationship. Preloads from nested relationships are also
  merged to current `preloads` result.

  ```ruby
    class ResponseSerializer < Jat
      plugin :json_api
      plugin :preloads
    end

    class UserSerializer < ResponseSerializer
      # preloads nothing for attributes
      attribute :email

      # preloads `:addresses` as specified manually
      attribute(:address, preload: :addresses) { |object| object.addresses.select(&:main).address }

      # preloads :account
      relationship :account, serializer: -> { AccountSerializer }

      # preloads :hashtags
      relationship :tag, key: :hashtags, serializer: -> { HashtagSerializer }

      # preloads { avatar_attachment: :blob: }
      relationship :avatar, preload: { avatar_attachment: :blob }, serializer: -> { AvatarSerializer }

      # disable preloads for relationships (add nil or false value)
      relationship :foo, preloads: nil, serializer:-> { FooSerializer }
      relationship :bar, preloads: false , serializer:-> { BarSerializer }
    end

  class AccountSerializer < ResponseSerializer;
    attribute(:plan, preload: :plan) { |obj| obj.plan.name }
  end
  class HashtagSerializer < ResponseSerializer; end
  class AvatarSerializer < ResponseSerializer; end
  class FooSerializer < ResponseSerializer; end
  class BarSerializer < ResponseSerializer; end

    # Generate preloads hash
    UserSerializer.preloads(fields: 'email, address, account, tag, avatar, foo, bar')
    # or same
    UserSerializer.new(fields: 'email, address, account, tag, avatar, foo, bar').preloads

    # =>
    # {
    #   addresses:{},
    #   account: {plan: {}},
    #   hashtags: {},
    #   avatar_attachment: {blob: {}},
    # }
  ```


### Activerecord
  Plugin `:activerecord` loads `[Preloads]` plugin and uses ActiveRecord to automatically preload data to serialized object(s).

  ```ruby
    class ResponseSerializer < Jat
      plugin :json_api
      plugin :activerecord
    end
  ```

### Validate Params
  Plugin `:validate_params` can be used to validate `fields` parameters and to get errors before serialization starts. Without it not existing fields attributes will be skipped.

  Plugin adds class method `.validate(context)` and instance method `#validate`.

  Example without validation:
  ```ruby
    class WithoutValidation < Jat
      plugin :json_api
      attribute(:foo) { |obj| obj }
    end

    WithoutValidation.to_h(1, fields: 'bar') # => { foo: 1 }
  ```

  Example with validation:
  ```ruby
    class WithValidation < Jat
      plugin :json_api
      plugin :validate_params
      attribute(:foo) { |obj| obj }
    end

    # adds validate method
    WithValidation.validate(fields: 'bar') # => Jat::SimpleApiFieldsError, "Field 'bar' not exists"
    WithValidation.new(fields: 'bar').validate # => Jat::SimpleApiFieldsError, "Field 'bar' not exists"

    # validates during serialization
    WithValidation.to_h(1, fields: 'bar') # => Jat::SimpleApiFieldsError, "Field 'bar' not exists"
  ```

### Serializing to String
  Objects can be serialized to JSON string if we enable `:to_str` plugin. This plugin adds additional `.to_str` DSL method. By default JSON will be generated using ruby standard `JSON` library. This can be changed with your favorite adapter, it works like this:

  ```ruby
    class MySerializer < Jat
      plugin :json_api
      plugin :to_str
      config[:to_str] = ->(hash) { Oj.dump(hash, mode: :compat) } # use Oj instead of JSON
      # ... some attributes
    end

    MySerializer.to_str(obj, context)
    # or
    MySerializer.new(obj).to_str(context)
  ```


### Caching
  Caching does not needed very often when serializing objects to hash, as it is usually a fast procedure. Most of the time people are constructing JSON API, so it will be more effective to cache serialized JSON strings. That's why, when enabled `:cache` plugin, `:to_str` plugin is also automatically enabled.

  It is hard to predict how cache_key should look like and for how long cache should be stored. So it is not serializer's responsibility to know such stuff. Requester should provide a callable instance that will use some caching mechanism. Example:
  ```ruby
    cache = lambda do |object, context, &block|
      # Some code to construct cache key, usually you want to use:
      # - object.cache_key (for ActiveRecord)
      # - context[:params]
      # - context[:format] (:to_h | :to_str)
      cache_key = '...'

      Rails.cache.fetch(cache_key, expires_in: 5.minutes) { block.() }
    end

    UserSerializer.to_str(users, cache: cache, **context)
    UserSerializer.to_h(users, cache: cache, **context)
  ```

  📌 Add `:cache` plugin only after `:activerecord` plugin to not preload relations each time even when response taken from cache.


### Lower Camel Case
Enabled by requiring `plugin :lower_camel_case`.

```ruby
class UserSerializer < ResponseSerializer
  plugin :json_api
  plugin :lower_camel_case

  attribute :foo_bar_bazz # becomes fooBarBazz in response
end
```

### Internal Cache

Internal cache can be enabled with plugin `:maps_cache` to improve serialization performance. Structures (**maps**) that we generate after parsing `fields` parameter can be stored to use in next serialization. Cached **maps** are stored in class variable, maximum 100 **maps** are stored per serializer.

Performance improvement depends on serialized object and context, in example benchmark
serializing with enabled cache ~ 1.27x faster. [Internal cache benchmark script] attached.

```
Comparison:
Include Internal Cache:    21608.0 i/s
Exclude Internal Cache:    17078.9 i/s - 1.27x  (± 0.00) slower
```

Enabling internal cache:

```ruby
  class ResponseSerializer < Jat
    plugin :json_api
    plugin :maps_cache, cached_maps_count: 50 # default: 100
  end
```

## Miscellaneous
### Configure Exposed Attributes
  When developing application it is always a tricky question to find which attributes will be needed. Usually it is unwanted to expose everything, and at the same time it is unwanted to create different serializers with different attribute sets. This gem allows to configure what is needed. As exposing object attributes usually does not require additional (DB) queries, current gem exposes all attributes by default and hides all relationships.

  📌 Rule of thumb:
  - _attributes_ are **exposed by default**
  - _relationships_ are **hidden by default**

  There are 4 ways to change this rule:

  1. Adding `config[:exposed]=:all/:none/:default` config option to set default exposed value for all attributes/relationships in current serializer.
      ```ruby
        class UserSerializer < ResponseSerializer
          config[:exposed] = :none # :none, :all, :default

          attribute :email
          relationship :avatar, serializer: AvatarSerializer
        end
      ```
  2. Adding `exposed: true/false` option per attribute. Per-attribute `exposed` option has precedence over `config[:exposed]` option.
      ```ruby
        class UserSerializer < ResponseSerializer
          attribute :email, exposed: false
          relationship :avatar, serializer: AvatarSerializer, exposed: true
        end
      ```
  3. Adding `{ exposed: ':all/:none/:default' }` context when serializing object. This context option has precedence over per-attributes `:exposed` values. It changes exposed attributes in current serializer and all relationships. Exposed `:none` is useful only in combination with `fields` which additionally specifies exposed attributes, if you want full control over each serialized attribute.
      ```ruby
        UserSerializer.to_h(user) # returns all exposed by default attributes
        UserSerializer.to_h(user, exposed: :default) # same, returns all exposed by default attributes
        UserSerializer.to_h(user, exposed: :all) # returns all attributes of current and nested objects
        UserSerializer.to_h(user, exposed: :none) # returns empty hash
      ```

  4. Adding standard JSON:API `fields` and `include` parameters when serializing object.
    - https://jsonapi.org/format/#fetching-sparse-fieldsets
    - https://jsonapi.org/format/#fetching-includes


      ```ruby
        UserSerializer.to_h(user) # returns default attributes
        UserSerializer.to_h(user, exposed: :default) # same, returns default attributes
        UserSerializer.to_h(user, exposed: :all) # returns all attributes
        UserSerializer.to_h(user, exposed: :none, fields: { articles: 'title' }) # returns only 'title' attribute for articles, and no attributes for other types.
        UserSerializer.to_h(user, include: 'articles') # returns default attributes and `articles relationship with default attributes
        UserSerializer.to_h(user, fields: { articles: 'title,body', people: 'name'}) # returns only `title` and `body` for articles and only `name` for people. Other types will be returned with default attributes.
      ```

### Paging
  There are no specific paging plugin, we can use `meta` defined on some base class.

  ```ruby
    class ResponseSerializer < Jat
      meta(:paging) do |records, context|
        break unless context.dig(:params, :page)
        break unless records.is_a?(Enumerable)
        break unless records.respond_to?(:total_count)

        {
          total_count: records.total_count,
          size: records.size,
          offset_value: records.offset_value
        }
      end
    end
  ```

[Activation]: #activation
[Serialization]: #serialization
[DSL]: #dsl
  [Type and ID]: #type-and-id
  [Attribute]: #attribute
  [Relationship]: #relationship
  [Config]: #config
  [Meta]: #meta
    [Document Meta]: #document-meta
    [Relationship Meta]: #relationship-meta
    [Object Meta]: #object-meta
  [Links]: #links
    [Document Links]: #document-links
    [Relationship Links]: #relationship-links
    [Object Links]: #object-links
  [Jsonapi]: #jsonapi
[Plugins]: #plugins
  [Preloads]: #preloads
  [Activerecord]: #activerecord
  [Validate Params]: #validate-params
  [Serializing to String]: #serializing-to-string
  [Caching]: #caching
  [Lower Camel Case]: #lower-camel-case
  [Internal Cache]: #internal-cache
[Miscellaneous]: #miscellaneous
  [Configure Exposed Attributes]: #configure-exposed-attributes
  [Paging]: #paging

[Sparse Fieldsets]: https://jsonapi.org/format/#fetching-sparse-fieldsets
[Inclusion of Related Resources]: https://jsonapi.org/format/#fetching-includes

[Internal cache benchmark script]: benchmarks/json_api/json_api_maps_cache_benchmark.rb
[:preloads]: #preloads
[:activerecord]: #activerecord
