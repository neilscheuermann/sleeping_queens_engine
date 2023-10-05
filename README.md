# SleepingQueensEngine

This holds the game logic for the popular children's card game,
[Sleeping Queens](https://gamewright.com/product/Sleeping-Queens)

## Rules of Play

_[TODO>>>>: Select which rulebook to follow. 12 or 16 queens, but the rest is
the same.]_

- [Sleeping Queens rules](https://gamewright.com/pdfs/Rules/SleepingQueensTM-RULES.pdf)
- [Sleeping Queens rules (new)](https://gamewright.com/pdfs/Rules/Sleeping-Queens-Rules.pdf)

## Testing game actions and rule checks

Can test gameplay from an interactive Elixir shell (`iex -S mix`) to run the
following commands.

### Game actions

```elixir
alias SleepingQueensEngine.Player
alias SleepingQueensEngine.Table

player1 = Player.new("neil")
player2 = Player.new("beth")
players = [player1, player2]

# new table
table = Table.new(players)

# deal cards
table = Table.deal_cards(table)

# discard cards
{:ok, table} = Table.discard_cards(table, [1], 1)

# Select queen
{:ok, table} = Table.select_queen(table, {1, 1}, 1)
# error if selcting a nil queen
{:ok, table} = Table.select_queen(table, {1, 1}, 1)
# error if selecting invalid queens_board coordinate
{:ok, table} = Table.select_queen(table, {1, 5}, 1)
```

### Rule checks

```elixir
alias SleepingQueensEngine.Rules

rules = Rules.new()

# add player should increment :player_count
{:ok, rules} = Rules.check(rules, :add_player)

# remove player should decrement :player_count
{:ok, rules} = Rules.check(rules, :remove_player)

# start game should change state to :playing
{:ok, rules} = Rules.check(rules, :start_game)

# deal cards should cycle :player_turn through available players
{:ok, rules} = Rules.check(rules, :deal_cards)

# win check with a :win should change state to :game_over
{:ok, rules} = Rules.check(rules, {:win_check, :no_win})
{:ok, rules} = Rules.check(rules, {:win_check, :win})
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sleeping_queens_engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sleeping_queens_engine, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with
[ExDoc](https://github.com/elixir-lang/ex_doc) and published on
[HexDocs](https://hexdocs.pm). Once published, the docs can be found at
<https://hexdocs.pm/sleeping_queens_engine>.
