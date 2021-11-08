# SIMPLE:API

First of all, there are no official format that named `SIMPLE:API`.

SIMPLE:API is a format that constructs response in a form of nested hash structures. Same format is generated with [AMS] or [Jbuilder] gems.

Killer feature is that you can describe all attributes in one serializer but serialize only attributes that were requested (aka GraphQL). More on this here: [Configure Exposed Attributes]. Also this gem helps to avoid N+1 and to not request additional DB queries when serializing custom attributes set.

<details>
  <summary>SIMPLE:API format example</summary>

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

## Table of Contents
* [Compatible Plugins](#compatible-plugins)
* [Activation](#activation)
* [Serialization](#serialization)
* [DSL](#dsl)
  * [Root](#root)
  * [Attribute](#attribute)
  * [Relationship](#relationship)
  * [Meta](#meta)
  * [Config](#config)
* [Preloads](#preloads)
* [Activerecord](#activerecord)
* [Validate Params](#validate-params)
* [Configure Exposed Attributes](#configure-exposed-attributes)
* [Additional Meta](#additional-meta)
* [Paging](#paging)
* [Serializing to String](#serializing-to-string)
* [Caching](#caching)
* [Lower Camel Case](#lower-camel-case)
* [Internal Cache](#internal-cache)

## Activation

```ruby
  class BaseSerializer < Jat
    plugin :simple_api
  end
```

## Serialization

```ruby
  CurrentSerializer.to_h(object, context)
  # or
  CurrentSerializer.new(context).to_h(object)
```

## DSL
  All DSL methods are inherited by subclasses and can be redefined by subclasses.

### Root
  `root` method specifies root key for response. Accepts one argument (default root name for all cases) or two key arguments - `:one`, `:many` to specify different names for one or list of objects. Response can be serialized without root, but it is not possible to add meta information without root.

```ruby
class UserSerializer < Jat
  root :data # root object `:data` for all responses
  root one: :user, many: :users # different root names when serializing one object or list
end
```

### Attribute

```ruby
class UserSerializer < Jat
  # Serializes `object.email`
  attribute(:email)

  # Serializes `object.confirmed_email`
  attribute(:email, key: :confirmed_email)

  # When provided block without args, we can specify direct value
  attribute(:email) { 'example@example.com '}

  # Define block with serialized object argument
  attribute(:email) { |user| user.confirmed_email }

  # Define block with serialized object and context
  attribute(:email) { |user, ctx| user.confirmed_email || ctx[:email] }
end
```

### Relationship
  `relationship` is an alias of `attribute`, but with forced `:serializer` option. If two serializers have cross referenced relationships, they should be defined as callable lambdas.

```ruby
class UserSerializer < Jat
  # Serializes `object.profile`
  # Same as:
  #  attribute :profile, serializer: ProfileSerializer
  relationship :profile, serializer: ProfileSerializer

  # Serializes `object.main_profile`
  attribute :profile, key: :main_profile, serializer: -> { ProfileSerializer }

  # Serializes result of block execution
  attribute(:profile, serializer: -> { ProfileSerializer }) do |user, _ctx|
    user.profiles.select(&:last)
  end
end
```

### Meta
  `meta_key` specifies root metadata key. By default it is `:meta`. \
  `meta` specifies specifies one metadata attribute. Metadata attributes are shown always. One way to hide metadata attribute from response is to return nil from its block. Its a good place to show app version or paging info.

  ```ruby
  class UserSerializer < Jat
    meta(:version) { '1.2.3' }
    meta(:paging) { |objects, context| ... } # access to serialized object(s) or context
  end
  ```

  📌 Meta can be also added through context, more information in [Additional Meta](#additional-meta)
  ```
    UserSerializer.to_h(user, meta: { foo: :bar })
  ```

### Config
  We can change or check config options this way:

  ```ruby
    class UserSerializer < Jat
      config[:foo] = :bar # add config option
    end

    UserSerializer.config # show current config
  ```


## Preloads
  Plugin `:preloads` adds methods to show `preloads` hash. It can be used with you favorite database ORM to omit N+1.

  All relationships by default add preloads that match current relationship key. Preloads can be changed by providing `:preload` option on any attribute or relationship. Preloads from nested relationships are also
  merged to current `preloads` result.

  ```ruby
    class SimpleSerializer < Jat
      plugin :simple_api
      plugin :preloads
    end

    class UserSerializer < SimpleSerializer
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

  class AccountSerializer < SimpleSerializer;
    attribute(:plan, preload: :plan) { |obj| obj.plan.name }
  end
  class HashtagSerializer < SimpleSerializer; end
  class AvatarSerializer < SimpleSerializer; end
  class FooSerializer < SimpleSerializer; end
  class BarSerializer < SimpleSerializer; end

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


## Activerecord
  Plugin `:activerecord` loads `preloads` gem and uses ActiveRecord to automatically preload data to serialized object(s).

  ```ruby
    class SimpleSerializer < Jat
      plugin :simple_api
      plugin :activerecord
    end
  ```

## Validate Params
  Plugin `:validate_params` can be used to validate `fields` parameters and to get errors before serialization starts. Without it not existing fields attributes will be skipped.

  Plugin adds class method `.validate(context)` and instance method `#validate`.

  Example without validation:
  ```ruby
    class WithoutValidation < Jat
      plugin :simple_api
      attribute(:foo) { |obj| obj }
    end

    WithoutValidation.to_h(1, fields: 'bar') # => { foo: 1 }
  ```

  Example with validation:
  ```ruby
    class WithValidation < Jat
      plugin :simple_api
      plugin :validate_params
      attribute(:foo) { |obj| obj }
    end

    # adds validate method
    WithValidation.validate(fields: 'bar') # => Jat::SimpleApiFieldsError, "Field 'bar' not exists"
    WithValidation.new(fields: 'bar').validate # => Jat::SimpleApiFieldsError, "Field 'bar' not exists"

    # validates during serialization
    WithValidation.to_h(1, fields: 'bar') # => Jat::SimpleApiFieldsError, "Field 'bar' not exists"
  ```

## Configure Exposed Attributes
  When developing application it is always a tricky question to find which attributes will be needed. Usually it is unwanted to expose everything, and at the same time it is unwanted to create different serializers for different pages. So this gem tries to avoid this responsibility and allows to tell him what is needed. As exposing object attributes usually does not require additional (DB) queries, current gem exposes all attributes by default and hides all relationships.

  📌 Rule of thumb:
  - _attributes_ are **exposed by default**
  - _relationships_ are **hidden by default**

There are 4 ways to change this rule:

1. Adding `config[:exposed]=:all/:none/:default` config option to set default exposed value for all attributes/relationships in current serializer.
    ```ruby
      class UserSerializer < Jat
        config[:exposed] = :none # :none, :all, :default

        attribute :email
        relationship :avatar, serializer: { AvatarSerializer }
      end
    ```
2. Adding `exposed: true/false` option per attribute. Per-attribute `exposed` option has precedence over `config[:exposed]` option.
    ```ruby
      class UserSerializer < Jat
        attribute :email, exposed: false
        relationship :avatar, serializer: { AvatarSerializer }, exposed: true
      end
    ```
3. Adding `{ exposed: ':all/:none/:default' }` context when serializing object. This context option has precedence over per-attributes `:exposed` values. It changes exposed attributes in current serializer and all relationships. Exposed `:none` is useful only in combination with `fields` which additionally specifies exposed attributes, if you want full control over each serialized attribute.
    ```ruby
      UserSerializer.to_h(user) # returns all exposed by default attributes
      UserSerializer.to_h(user, exposed: :default) # same, returns all exposed by default attributes
      UserSerializer.to_h(user, exposed: :all) # returns all attributes of current and nested objects
      UserSerializer.to_h(user, exposed: :none) # returns empty hash
    ```
4. Adding `{ fields: 'foo,bar(bazz)'}` context when serializing object. Attributes are separated with comma and nested attributes are in parenthesis.
    ```ruby
      UserSerializer.to_h(user, fields: 'foo') # returns 'foo' + all exposed by default attributes
      UserSerializer.to_h(user, exposed: :default, fields: 'foo') # same, returns 'foo' + all exposed by default attributes
      UserSerializer.to_h(user, exposed: :all, fields: 'foo') # returns everything, fields can't change response
      UserSerializer.to_h(user, exposed: :none, fields: 'foo') # returns only 'foo' attribute
      # or
    ```

## Additional meta

Metadata can be added by specifying `:meta` context option. By default metadata root key is `:meta` but it can be changed with `:meta_key` option. Adding metadata requires `:root` key to be specified (in serializer or as context option), because it is not a good practice to mix object attributes with metadata, as object can also have :meta attribute. Root key can be specified using DSL or using context `:root` option. Metadata defined in context has precedence over metadata defined in serializer.

Example:
```ruby
  # {
  #   data: { ... },
  #   metadata: { version: '1.2.3' }
  # }
  UserSerializer.to_h(user, root: :data, meta_key: :metadata, meta: { version: '1.2.3' })
```

## Paging
There are no specific paging plugin, we can use `meta` defined on some base class.

```ruby
  class BaseSerializer < Jat
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

## Serializing to String
  Objects can be serialized to JSON string if we enable `:to_str` plugin. This plugin adds additional `.to_str` DSL method. By default JSON will be generated using ruby standard `JSON` library. This can be changed with your favorite adapter, it works like this:

  ```ruby
    class MySerializer < Jat
      plugin :simple_api
      plugin :to_str
      config[:to_str] = ->(hash) { Oj.dump(hash, mode: :compat) } # use Oj instead of JSON
      # ... some attributes
    end

    MySerializer.to_str(obj, context)
    # or
    MySerializer.new(obj).to_str(context)
  ```


## Caching
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


## Lower Camel Case
Enabled by requiring `plugin :lower_camel_case`.

```ruby
class UserSerializer < Jat
  plugin :simple_api
  plugin :lower_camel_case

  attribute :foo_bar_bazz # becomes fooBarBazz in response
end
```


## Internal Cache

Internal cache can be enabled with plugin `:maps_cache` to improve serialization performance. Structures (**maps**) that we generate after parsing `fields` parameter can be stored to use in next serialization. Cached **maps** are stored in class variable, maximum 100 **maps** are stored per serializer.

Performance improvement depends on serialized object and context, in example benchmark
serializing with enabled cache ~ 1.6x faster. [Internal cache benchmark script] attached.

```
Comparison:
Include Internal Cache:    48420.6 i/s
Exclude Internal Cache:    30126.8 i/s - 1.61x  (± 0.00) slower
```

Enabling internal cache:

```ruby
  class SimpleSerializer < Jat
    plugin :simple_api
    plugin :maps_cache, cached_maps_count: 50 # default: 100
  end
```

[AMS]: https://github.com/rails-api/active_model_serializers/tree/0-9-stable
[Jbuilder]: https://github.com/rails/jbuilder
[Internal cache benchmark script]: benchmarks/simple_api/simple_api_maps_cache_benchmark.rb
