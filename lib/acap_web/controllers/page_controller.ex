defmodule AcapWeb.PageController do
  use AcapWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
