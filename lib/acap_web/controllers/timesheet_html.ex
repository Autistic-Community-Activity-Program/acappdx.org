defmodule AcapWeb.TimesheetHTML do
  use AcapWeb, :html

  embed_templates "timesheet_html/*"

  @doc """
  Renders a timesheet form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :admin, :boolean, default: false

  def timesheet_form(assigns)

  def markdown_to_html(nil), do: ""

  def markdown_to_html(markdown) do
    {:ok, html, _} = Earmark.as_html(markdown)
    html
  end
end
