# JAT (JSON API TOOLKIT)

JAT helps to serialize complex nested objects to JSON format.

Key features:

* **Auto preload** – No need to preload data manually to omit N+1 (Active Record only)
* **Configurable exposed attributes** – No more tons of serializers with different attributes sets
* **Modular design** – plugin system (aka [shrine](https://shrinerb.com/docs/getting-started#plugin-system)) allows you to load only the functionality you need

## Output Format

Supported two serialization formats:
  - [JSON-API](https://jsonapi.org/format/)
  - Simple nested JSON objects (same as good old [AMS](https://github.com/rails-api/active_model_serializers/tree/0-9-stable) or [Jbuilder](https://github.com/rails/jbuilder))
