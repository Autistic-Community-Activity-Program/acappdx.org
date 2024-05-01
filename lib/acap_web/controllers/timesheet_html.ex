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
end
