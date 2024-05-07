defmodule Acap.Exporter do
  # Define a NimbleCSV module called AcapCSV
  NimbleCSV.define(AcapCSV, separator: ",", escape: "\"")

  def export(records, fields) do
    # Convert records to CSV format using the defined AcapCSV module
    csv_content = convert_to_csv(records, fields)
    {:ok, csv_content}
  end

  defp convert_to_csv(records, fields) do
    # Define the CSV module if not already defined (ensure this is outside of function scope in real usage)
    NimbleCSV.define(AcapCSV, separator: ",", escape: "\"")

    # Remove the :entries field from the fields list if present and add it back as 'entries_json'
    fields = Enum.reject(fields, &(&1 == :entries))
    fields = [:entries_json | fields]

    # Extract and flatten the records to include embedded schema fields as a JSON string
    rows =
      Enum.map(records, fn record ->
        flatten_record_to_json(record, fields)
      end)

    # Convert rows to CSV
    # Convert field atoms to strings for the header
    [fields |> Enum.map(&Atom.to_string/1)]
    |> AcapCSV.dump_to_iodata()
    |> Enum.concat(AcapCSV.dump_to_iodata(rows))
    |> Enum.join()
  end

  defp flatten_record_to_json(record, fields) do
    Enum.map(fields, fn
      :user ->
        record
        |> Map.get(:user)
        |> Map.get(:email)

      :entries_json ->
        record
        |> Map.get(:entries, [])
        # Convert the list of entries to a JSON string
        |> Jason.encode!()

      field ->
        record
        |> Map.fetch!(field)
        |> inspect
    end)
  end
end
