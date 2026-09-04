defmodule DiaryWeb.UserLive.Login do
  use DiaryWeb, :live_view

  alias Diary.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Full screen container matching 404 style: dark background with ambient glow effects -->
    <main class="min-h-screen w-full flex flex-col items-center justify-center bg-slate-950 text-slate-100 relative overflow-hidden p-4">
      <!-- Ambient background glowing decorative circles -->
      <div class="absolute top-1/4 left-1/4 w-96 h-96 bg-orange-600/10 rounded-full blur-[120px] pointer-events-none animate-pulse"></div>
      <div class="absolute bottom-1/4 right-1/4 w-96 h-96 bg-cyan-600/10 rounded-full blur-[120px] pointer-events-none animate-pulse" style="animation-delay: 2s;"></div>

      <!-- Flash notifications group -->
      <Layouts.flash_group flash={@flash} />

      <!-- Centered sleek card container -->
      <div class="w-full max-w-sm space-y-6 bg-slate-900/80 backdrop-blur-xl p-8 rounded-2xl border border-slate-800/80 shadow-2xl relative z-10">
        <div class="text-center space-y-3">
          <!-- Logo display -->
          <div class="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-slate-800/80 border border-slate-700/50 shadow-inner">
            <img src={~p"/images/power.svg"} class="w-7 h-auto" alt="Wayup Logo" />
          </div>
          <div>
            <h1 class="text-2xl font-extrabold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-orange-400 via-rose-400 to-cyan-400">
              <%= gettext("Log in") %>
            </h1>
            <p class="mt-1 text-xs text-slate-400">
              <%= if @current_scope do %>
                <%= gettext("You need to reauthenticate to perform sensitive actions on your account.") %>
              <% else %>
                <%= gettext("Don't have an account?") %> <.link
                  navigate={~p"/users/register"}
                  class="font-semibold text-orange-400 hover:text-orange-300 hover:underline"
                  phx-no-format
                ><%= gettext("Sign up") %></.link>
              <% end %>
            </p>
          </div>
        </div>

        <%!-- Preserved form code for potential future use --%>
        <%!--
        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p><%= gettext("You are running the local mail adapter.") %></p>
            <p>
              <%= gettext("To see sent emails, visit") %> <.link href="/dev/mailbox" class="underline"><%= gettext("the mailbox page") %></.link>.
            </p>
          </div>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label={gettext("Email")}
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            <%= gettext("Log in with email") %> <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="divider"><%= gettext("or") %></div>

        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label={gettext("Email")}
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label={gettext("Password")}
            autocomplete="current-password"
            spellcheck="false"
          />
          <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
            <%= gettext("Log in and stay logged in") %> <span aria-hidden="true">→</span>
          </.button>
          <.button class="btn btn-primary btn-soft w-full mt-2">
            <%= gettext("Log in only this time") %>
          </.button>
        </.form>

        <div class="divider"><%= gettext("or log in with") %></div>
        --%>

        <!-- Social login buttons (Google, GitHub, Discord) using static SVG assets -->
        <div class="flex flex-col gap-3 pt-2">
          <.link
            href={~p"/auth/google"}
            class="w-full flex items-center justify-center gap-3 py-2.5 px-4 rounded-xl font-semibold text-xs text-slate-200 bg-slate-800/60 hover:bg-slate-800 border border-slate-700/60 hover:border-slate-600 transition-all duration-200 shadow-md hover:shadow-lg"
          >
            <!-- Render Google icon from static assets -->
            <img src={~p"/images/google.svg"} class="size-4" alt="Google" />
            <span>Google</span>
          </.link>

          <.link
            href={~p"/auth/github"}
            class="w-full flex items-center justify-center gap-3 py-2.5 px-4 rounded-xl font-semibold text-xs text-slate-200 bg-slate-800/60 hover:bg-slate-800 border border-slate-700/60 hover:border-slate-600 transition-all duration-200 shadow-md hover:shadow-lg"
          >
            <!-- Render GitHub icon from static assets with dark mode inversion -->
            <img src={~p"/images/github.svg"} class="size-4 invert" alt="GitHub" />
            <span>GitHub</span>
          </.link>

          <.link
            href={~p"/auth/discord"}
            class="w-full flex items-center justify-center gap-3 py-2.5 px-4 rounded-xl font-semibold text-xs text-slate-200 bg-slate-800/60 hover:bg-slate-800 border border-slate-700/60 hover:border-slate-600 transition-all duration-200 shadow-md hover:shadow-lg"
          >
            <!-- Render Discord icon from static assets with dark mode inversion -->
            <img src={~p"/images/discord.svg"} class="size-4 invert" alt="Discord" />
            <span>Discord</span>
          </.link>
        </div>

        <!-- Footer watermark matching 404 style -->
        <div class="pt-4 flex items-center justify-center space-x-2 opacity-40 hover:opacity-70 transition-all duration-300">
          <span class="text-xs tracking-widest font-bold uppercase text-slate-400">Wayup</span>
          <span class="text-slate-600">•</span>
          <span class="text-[10px] text-slate-500 font-mono">Workout & Activity Diary</span>
        </div>
      </div>
    </main>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    locale = session["locale"] || "en" # Fetch locale from session
    Gettext.put_locale(DiaryWeb.Gettext, locale) # Set the locale for the current process
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      gettext("If your email is in our system, you will receive instructions for logging in shortly.") # Localized message

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  # defp local_mail_adapter? do
  #   Application.get_env(:diary, Diary.Mailer)[:adapter] == Swoosh.Adapters.Local
  # end
end
