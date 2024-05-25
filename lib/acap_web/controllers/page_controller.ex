defmodule AcapWeb.PageController do
  use AcapWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def about(conn, _params) do
    render(conn, :about)
  end

  def summer(conn, _params) do
    render(conn, :summer)
  end

  def history(conn, _params) do
    render(conn, :history)
  end
end
