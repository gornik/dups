defmodule Dups do
  @chunk_size 1024 * 128
  @min_size 0

  def main([dir]) do
    dir
    |> walk_dir()
    |> Flow.from_enumerable()
    |> Flow.map(fn file -> {File.stat!(file).size, file} end)
    |> Flow.partition(key: {:elem, 0})
    |> Flow.group_by(&(elem(&1, 0)), &(elem(&1, 1)))
    |> Flow.filter(fn {size, files} -> length(files) > 1 and size > @min_size end)
    |> Flow.flat_map(fn {_size, files} ->
      files
      |> Task.async_stream(&(md5(&1, :first_chunk)))
      |> Stream.map(fn {:ok, {bytes, file}} -> {bytes, file} end)
      |> Enum.group_by(&(elem(&1, 0)), &(elem(&1, 1)))
      |> Enum.filter(fn {_bytes, files} -> length(files) > 1 end)
      |> Enum.flat_map(fn {_bytes, files} ->
        files
        |> Task.async_stream(&(md5(&1, :full)))
        |> Stream.map(fn {:ok, {hash, file}} -> {hash, file} end)
        |> Enum.group_by(&(elem(&1, 0)), &(elem(&1, 1)))
        |> Enum.filter(fn {_hash, files} -> length(files) > 1 end)
        |> Enum.map(fn {_hash, files} -> files end)
      end)
    end)
    |> Enum.to_list()
    |> IO.inspect()
  end

  defp walk_dir(path) do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        with {:ok, files} <- File.ls(path) do
          files
          |> Stream.map(&Path.join(path, &1))
          |> Stream.map(&walk_dir/1)
          |> Stream.concat()
        else
          {:error, _reason} -> []
        end

      true ->
        []
    end
  end

  defp md5(file, type) do
    hash =
      file
      |> File.stream!([], @chunk_size)
      |> limit_stream(type)
      |> Enum.reduce(:crypto.hash_init(:md5), fn chunk, hash ->
        :crypto.hash_update(hash, chunk)
      end)
      |> :crypto.hash_final()
    {hash, file}
  end

  defp limit_stream(stream, :first_chunk), do: Stream.take(stream, 1)
  defp limit_stream(stream, :full), do: stream
end
