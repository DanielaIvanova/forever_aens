defmodule ForeverAens.Supervisor do
  @moduledoc """
  Supervisor responsible for ForeverAens.
  """
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      ForeverAens
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
