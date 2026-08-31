defmodule DiaryWeb.Services.Gym.LocationSettingsComponent do
  @moduledoc """
  Gym-specific location settings component with toggle switch and 5-minute periodic updates.
  """
  use DiaryWeb, :html

  @doc """
  Renders the location settings UI block with a toggle switch.
  """
  attr :location_enabled, :boolean, default: false, doc: "whether location tracking toggle is ON or OFF"
  attr :location, :map, default: nil, doc: "map containing latitude, longitude, accuracy, and last_updated_at"
  attr :location_error, :string, default: nil, doc: "error message string if location fetch fails"

  def location_settings(assigns) do
    ~H"""
    <!-- Location Access Section with Geolocation JS Hook -->
    <div id="location-settings" phx-hook="Geolocation" class="my-6 p-4 border border-slate-200 dark:border-zinc-800 rounded-lg max-w-xl mx-auto">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold"><%= gettext("Location Settings") %></h3>
          <p class="text-sm text-slate-600 dark:text-zinc-400">
            <%= gettext("Allow location access to enable periodic location updates (every 5 mins).") %>
          </p>
        </div>

        <!-- Toggle Switch UI Component with specific ID -->
        <label class="cursor-pointer label ml-4">
          <input
            id="location-toggle-input"
            type="checkbox"
            class="toggle toggle-primary"
            checked={@location_enabled}
            phx-click="toggle_location"
          />
        </label>
      </div>

      <%= if @location_enabled && @location do %>
        <div class="mt-4 p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-md text-emerald-600 dark:text-emerald-400 text-sm">
          <div class="flex items-center justify-between">
            <p class="font-medium"><%= gettext("Location Tracking Active (Every 5 mins)") %></p>
            <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300">
              <%= gettext("Active") %>
            </span>
          </div>
          <p class="text-xs font-mono mt-1">
            Lat: {@location.latitude}, Lng: {@location.longitude} (±{@location.accuracy}m)
          </p>
          <%= if @location[:last_updated_at] do %>
            <p class="text-xs text-slate-400 mt-1">
              <%= gettext("Last updated:") %> {@location.last_updated_at}
            </p>
          <% end %>
        </div>
      <% else %>
        <%= if @location_enabled && @location_error do %>
          <div class="mt-4 p-3 bg-red-500/10 border border-red-500/20 rounded-md text-red-600 dark:text-red-400 text-sm">
            <p><%= @location_error %></p>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
