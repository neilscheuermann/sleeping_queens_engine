# SleepingQueensEngine

This holds the game logic for the popular children's card game,
[Sleeping Queens](https://gamewright.com/product/Sleeping-Queens)

## Rules of Play

_[TODO::: Select which rulebook to follow. 12 or 16 queens, but the rest is
the same.]_

- [Sleeping Queens rules](https://gamewright.com/pdfs/Rules/SleepingQueensTM-RULES.pdf)
- [Sleeping Queens rules (Deluxe)](https://gamewright.com/pdfs/Rules/Sleeping-Queens-Rules.pdf)

## Testing game actions and rule checks

Can test gameplay from an interactive Elixir shell (`iex -S mix`) to run the
following commands.

### Game Process Supervision

```elixir
alias SleepingQueensEngine.{Game, GameSupervisor}

# Create new game using the DynamicSupervisor so it can be restarted according to child specs.
# Game process is named in GenServer.start_link using &via_tuple/1 to register itself.
{:ok, game} = GameSupervisor.start_game("ABCD")
# used to find the game in the process Registry
via = Game.via_tuple("ABCD")

# can list the number of Game processes being supervised
DynamicSupervisor.count_children(GameSupervisor)
# can list which Game processes are being supervised
DynamicSupervisor.which_children(GameSupervisor)

# true and pid
Process.alive?(game)
GenServer.whereis(via)

Process.exit(game, :kaboom)

# false but new pid because DynamicSupervisor restarted it
Process.alive?(game)
GenServer.whereis(via)

GameSupervisor.stop_game("ABCD")
# false and nil
Process.alive?(game)
GenServer.whereis(via)
# 
```

### Game Process Registration

```elixir
alias SleepingQueensEngine.Game

# Name used by process Registry to register and find processes
via = Game.via_tuple("Lena")

# Can test manually starting a game passing the name and named via tuple
GenServer.start_link(Game, "Lena", name: via)
# and now use the via rather than the pid to reference the process
:sys.get_state(via)
# This will ERROR because there can't be 2 processes with the same name
GenServer.start_link(Game, "Lena", name: via)
```

### Game interface

```elixir
alias SleepingQueensEngine.Game

# new game
{:ok, game} = Game.start_link("Tammy1")

:sys.get_state(game)

Game.add_player(game, "Tammy2")
Game.add_player(game, "Tammy3")
Game.add_player(game, "Tammy4")
Game.add_player(game, "Tammy5")
Game.add_player(game, "will return :error")
Game.start_game(game)

# deal cards
Game.deal_cards(game)

# play cards
Game.play_cards(game, player_position, card_positions)
```

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

# Place queen back on board
{:ok, table} = Table.place_queen_on_board(table, 1, 1, {1, 1})

# Select queen again
{:ok, table} = Table.select_queen(table, {1, 1}, 1)

# Player 2 steal queen
{:ok, table} = Table.steal_queen(table, 1, 1, 2)
```

### Game Rules

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
