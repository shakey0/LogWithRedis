# LogWithRedis

Log with Redis is a simple script you can run in a terminal to see logs from your application as it runs. All you need to do is simply add your logs to the redis list with the default or specified key, and the script will pop them out and log them in the order they were added in.

## Usage Example

### Adding an entry to Redis:

```ruby
$redis.lpush("lwr", "Test string")
$redis.lpush("lwr", "Test string---green")
```

### Terminal Output:

![String Output](example_screenshots/string_output.png)

## Available Colors

You can colorize your log entries by appending `---color` to your string, where `color` is one of:

- `yellow` (displays as light yellow)
- `blue` (displays as light blue)
- `red` (displays as light red)
- `green` (displays as light green)
- `cyan` (displays as light cyan)
- `magenta` (displays as light magenta)

## JSON Handling

JSON objects are automatically detected and pretty-printed with colorization:

```ruby
$redis.lpush("lwr", '{"name":"John","age":30}')
```

![JSON Output](example_screenshots/json_output.png)

## ActiveRecord Object Handling

ActiveRecord objects can easily be added:

```ruby
$redis.lpush("lwr", user.to_json)
$redis.lpush("lwr", pets.to_json)
```

![ActiveRecord Output](example_screenshots/activerecord_output.png)

## Installation

1. Clone the repository and `cd LogWithRedis`
2. Install the required gems: `gem install redis json colorize pygments.rb`
3. Make the script executable: `chmod +x log_with_redis.rb`
4. Run the script with `./log_with_redis.rb`
