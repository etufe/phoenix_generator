#Phoenix Generator
A collection of boilerplate generators for the [Phoenix Web Framework](https://github.com/phoenixframework/phoenix).

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/etufe/phoenix_generator?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

https://hex.pm/packages/phoenix_generator

https://github.com/etufe/phoenix_generator

##Setup
 - Start a Phoenix project: http://www.phoenixframework.org/v0.8.0/docs
 - Add Phoenix Generator and optionally [Ecto](https://github.com/elixir-lang/ecto) and [Postgrex](https://github.com/ericmj/postgrex) to your project's dependencies

```elixir
defp deps do
  [{:postgrex, ">= 0.0.0"},
   {:ecto, github: "elixir-lang/ecto"},
   {:phoenix_generator, github: "etufe/phoenix_generator"}]
end
```

You should also update your applications list to include postgrex and ecto:

```elixir
def application do
  [applications: [:postgrex, :ecto]]
end
```
 - `mix do deps.get, compile`

## Generators
run a generator: `mix phoenix.gen.some_generator`

get help and options: `mix help phoenix.gen.some_generator`

 - **jumpstart** requires ecto: Sets up a repo and database config.
 - **scaffold** requires ecto: Generates a Controller/Model/View/Template scaffold.
 - **controller** : Generates a controller and optionally sets up a view, actions and templates.
 - **view**: generates a view class
 - **ectomodel** requires ecto: Generates a model optionally with fields and a migration.
 - **template**: Generates an empty template for the given action.
 - **channel**: Generates an empty Channel and optionally the route.
 - **instachat**: Generates a chatroom as a channel demo.

## Putting it all together
Let's use the generators to create a simple notes app.

 - Create a phoenix application http://www.phoenixframework.org/v0.8.0/docs
 - Add `phoenix_generator`, `ecto`, and `postgrex` to your dependencies (see above)
 - make sure you have postgres running. If you don't configure `jumpstart` with a `postgres-url` then make sure user: `user` has adequate permissions in postgres
 - run `mix phoenix.gen.jumpstart`
 - run `mix ecto.create`
 - run `mix phoenix.gen.scaffold note title:string body:string`
 - run `mix ecto.migrate`
 - run `mix phoenix.server`
 - navigate to http://localhost:4000/notes

## Caveats
 - At the moment this project is only meant to work with the most recent versions of Ecto and Phoenix on github.
 - Ecto doesn't currently support `datetime`s being inserted directly into html. If you want this functionality, say by using the `--timestamps` flag when running the `scaffold` generator, create a file called `lib/ecto_datetime_html_safe.ex` with the contens:
```elixir
defimpl Phoenix.HTML.Safe, for: Ecto.DateTime do
  def to_iodata(%Ecto.DateTime{day: day, hour: hour,
      min: min, month: month, sec: sec, year: year}) do
    "#{year}/#{month}/#{day} #{hour}:#{min}:#{sec}"
  end
end

```

## Trying out Channels / Instachat
The instachat generator generates a functioning chat with multiple rooms and basic nickname management. It uses an ets table to store the nicknames.

 - Create a phoenix application.
 - Add `phoenix_generator` to your dependencies.
 - run `mix phoenix.gen.instachat`
 - run `mix phoenix.server`
 - navigate to http://localhost:4000/instachat
 - Look around web/channels/instachat.exs and web/templates/instachat/index.html.eex

## Contributing
Feel free to make pull requests or create github issues. Ecto and Phoenix are both moving targets at the moment and I aim to keep these generators in sync with whatever is in master of those two projects.

##Todo
  - Replace all resources_path references with the helper
  - There seems to be a bug with `Map.merge(@model.__struct__, params["resource"])`
  - Flash messages
  - Handle Ecto date/times better
  - Keep up with changes
  - Tests
  - Chat takes a minute to start working, find out why.
