defmodule DiaryWeb.UserLive.Settings do
  use DiaryWeb, :live_view

  on_mount {DiaryWeb.UserAuth, :require_sudo_mode}

  alias Diary.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          <%= gettext("Account Settings") %>
          <:subtitle><%= gettext("Manage your account email address, password, and avatar settings") %></:subtitle>
        </.header>
      </div>

      <!-- Avatar Upload Section -->
      <div class="my-6 p-4 border border-slate-200 dark:border-zinc-800 rounded-lg max-w-xl mx-auto">
        <h3 class="text-lg font-semibold mb-3"><%= gettext("Profile Picture") %></h3>
        <div class="flex items-center gap-6 mb-4">
          <!-- Current Avatar Preview using Core Component with version timestamp for cache busting -->
          <.user_avatar user={@current_scope.user} version={@avatar_version} size={:xl} />
          <div class="text-sm text-slate-600 dark:text-zinc-400">
            <p><%= gettext("Upload a new avatar image.") %></p>
            <p class="text-xs text-slate-400"><%= gettext("JPG, PNG, WebP up to 5MB.") %></p>
          </div>
        </div>

        <form id="avatar_form" phx-change="validate_avatar" phx-submit="save_avatar">
          <div class="mb-4">
            <.live_file_input upload={@uploads.avatar} class="file-input file-input-bordered w-full max-w-xs" />
          </div>

          <!-- Selected entry preview -->
          <%= for entry <- @uploads.avatar.entries do %>
            <div class="flex items-center gap-3 my-2 text-sm">
              <.live_img_preview entry={entry} class="w-12 h-12 rounded-full object-cover" />
              <span>{entry.client_name}</span>
              <button type="button" phx-click="cancel_avatar" phx-value-ref={entry.ref} class="text-red-500 hover:underline">
                <%= gettext("Cancel") %>
              </button>
            </div>
            <%= for err <- upload_errors(@uploads.avatar, entry) do %>
              <p class="text-red-500 text-xs">{error_to_string(err)}</p>
            <% end %>
          <% end %>

          <%= for err <- upload_errors(@uploads.avatar) do %>
            <p class="text-red-500 text-xs">{error_to_string(err)}</p>
          <% end %>

          <.button variant="primary" disabled={@uploads.avatar.entries == []} phx-disable-with={gettext("Uploading...")}>
            <%= gettext("Upload Avatar") %>
          </.button>
        </form>
      </div>

    <!--
      <div class="divider" />

      <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
        <.input
          field={@email_form[:email]}
          type="email"
          label={gettext("Email")}
          autocomplete="username"
          spellcheck="false"
          required
        />
        <.button variant="primary" phx-disable-with={gettext("Changing...")}><%= gettext("Change Email") %></.button>
      </.form>

      <div class="divider" />

      <.form
        for={@password_form}
        id="password_form"
        action={~p"/users/update-password"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <input
          name={@password_form[:email].name}
          type="hidden"
          id="hidden_user_email"
          spellcheck="false"
          value={@current_email}
        />
        <.input
          field={@password_form[:password]}
          type="password"
          label={gettext("New password")}
          autocomplete="new-password"
          spellcheck="false"
          required
        />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label={gettext("Confirm new password")}
          autocomplete="new-password"
          spellcheck="false"
        />
        <.button variant="primary" phx-disable-with={gettext("Saving...")}>
          <%= gettext("Save Password") %>
        </.button>
      </.form>
    -->
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, session, socket) do
    locale = session["locale"] || "en" # Fetch locale from session
    Gettext.put_locale(DiaryWeb.Gettext, locale) # Set the locale for the current process
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, gettext("Email changed successfully.")) # Localized message

        {:error, _} ->
          put_flash(socket, :error, gettext("Email change link is invalid or it has expired.")) # Localized message
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, session, socket) do
    locale = session["locale"] || "en" # Fetch locale from session
    Gettext.put_locale(DiaryWeb.Gettext, locale) # Set the locale for the current process
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:avatar_version, System.system_time(:second))
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      # Configure LiveView upload for user avatar images
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_avatar", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_avatar", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("save_avatar", _params, socket) do
    user = socket.assigns.current_scope.user
    s3_key = Diary.Accounts.Avatar.s3_key(user.email)

    results =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        case File.read(path) do
          {:ok, binary} ->
            # Upload binary to S3 using Diary.Storage helper
            case Diary.Storage.put_object(s3_key, binary, headers: [{"content-type", entry.client_type}]) do
              {:ok, _url} -> {:ok, :uploaded}
              {:error, reason} -> {:post_error, reason}
            end

          {:error, reason} ->
            {:post_error, reason}
        end
      end)

    case results do
      [:uploaded] ->
        info = gettext("Avatar updated successfully.")

        # Touch user updated_at to ensure cache-busting timestamp propagates to current_scope and navigation bar
        {:ok, updated_user} = Accounts.touch_user(user)

        updated_scope = %{socket.assigns.current_scope | user: updated_user}
        new_version = System.system_time(:second)

        socket =
          socket
          |> assign(:current_scope, updated_scope)
          |> assign(:avatar_version, new_version)
          |> put_flash(:info, info)

        {:noreply, socket}

      _ ->
        error = gettext("Failed to upload avatar image.")
        {:noreply, socket |> put_flash(:error, error)}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = gettext("A link to confirm your email change has been sent to the new address.") # Localized message
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  # Localized error messages for LiveView uploads
  defp error_to_string(:too_large), do: gettext("File is too large (max 5MB)")
  defp error_to_string(:too_many_files), do: gettext("You have selected too many files")
  defp error_to_string(:not_accepted), do: gettext("Unacceptable file type")
end
