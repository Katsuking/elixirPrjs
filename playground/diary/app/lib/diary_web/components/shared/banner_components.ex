defmodule DiaryWeb.Shared.BannerComponents do
  @moduledoc """
  Provides shared banner UI components used across multiple services and subdomains.
  """
  use Phoenix.Component
  use Gettext, backend: DiaryWeb.Gettext

  import DiaryWeb.CoreComponents, only: [icon: 1]

  @doc """
  Renders a reusable banner indicating that a page, feature, or subdomain is under development.

  ## Examples

      <.under_development_banner />
      <.under_development_banner class="my-4" />

  """
  attr :class, :string, default: nil, doc: "optional additional CSS classes"

  def under_development_banner(assigns) do
    ~H"""
    <!-- Reusable banner component displaying "Under development." with i18n support across all subdomains -->
    <div class={[
      "w-full bg-gradient-to-r from-amber-500 via-orange-500 to-amber-600 dark:from-amber-600 dark:via-orange-600 dark:to-amber-700 text-white px-4 py-3 shadow-md flex items-center justify-center gap-3 text-lg sm:text-xl md:text-2xl font-black tracking-wider uppercase",
      @class
    ]}>
      <.icon name="hero-wrench-screwdriver" class="size-6 sm:size-7 shrink-0" />
      <span>{gettext("Under development.")}</span>
      <.icon name="hero-exclamation-triangle" class="size-6 sm:size-7 shrink-0" />
    </div>
    """
  end
end
