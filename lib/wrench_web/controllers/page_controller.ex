defmodule WrenchWeb.PageController do
  use WrenchWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
