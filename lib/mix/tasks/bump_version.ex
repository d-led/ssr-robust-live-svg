defmodule Mix.Tasks.BumpVersion do
  use Mix.Task

  @shortdoc "Bumps the version in mix.exs (patch, minor, or major)"

  @moduledoc """
  Bumps the version in mix.exs.

      mix bump_version.patch
      mix bump_version.minor
      mix bump_version.major
  """

  @impl true
  def run([type]) when type in ["patch", "minor", "major"] do
    file = "mix.exs"
    {:ok, content} = File.read(file)

    version_regex = ~r/version:\s*"(\d+)\.(\d+)\.(\d+)"/

    new_content =
      Regex.replace(version_regex, content, fn _, major, minor, patch ->
        {major, minor, patch} =
          case type do
            "patch" -> {major, minor, Integer.to_string(String.to_integer(patch) + 1)}
            "minor" -> {major, Integer.to_string(String.to_integer(minor) + 1), "0"}
            "major" -> {Integer.to_string(String.to_integer(major) + 1), "0", "0"}
          end

        ~s/version: "#{major}.#{minor}.#{patch}"/
      end)

    File.write!(file, new_content)
    Mix.shell().info("Bumped #{type} version in #{file}")
  end

  def run(_) do
    Mix.shell().error("Usage: mix bump_version.{patch|minor|major}")
  end
end
