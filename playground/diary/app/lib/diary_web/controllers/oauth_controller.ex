defmodule DiaryWeb.OAuthController do
  use DiaryWeb, :controller

  import Ecto.Query, warn: false
  alias Diary.Repo
  alias Diary.Accounts
  alias Diary.Accounts.User
  alias Diary.Accounts.UserIdentity
  alias DiaryWeb.UserAuth

  # Fetch active OAuth config from application settings
  defp get_provider_config!(provider) do
    providers = Application.get_env(:diary, :oauth_providers)

    provider_atom =
      case provider do
        "github" -> :github
        "google" -> :google
        "discord" -> :discord
        _ -> raise "Unsupported OAuth provider: #{provider}"
      end

    case Keyword.get(providers, provider_atom) do
      nil -> raise "Unsupported OAuth provider: #{provider}"
      config -> config
    end
  end

  @doc """
  Initiates the OAuth authorization flow by redirecting the user to the provider.
  Uses per-subdomain dynamic redirect_uri (e.g. https://gym.wayup.cc/auth/google/callback).
  """
  def request(conn, %{"provider" => provider}) do
    config = get_provider_config!(provider)
    redirect_uri = unverified_url(conn, "/auth/#{provider}/callback", host: conn.host)

    config = Keyword.put(config, :redirect_uri, redirect_uri)

    # Generate Authorization URL via Assent Strategy
    strategy = config[:strategy]
    case strategy.authorize_url(config) do
      {:ok, %{url: url, session_params: session_params}} ->
        conn
        |> put_session(:oauth_session_params, session_params)
        |> redirect(external: url)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to initialize OAuth flow: #{inspect(reason)}")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  @doc """
  Handles the callback from the OAuth provider directly on the requesting subdomain endpoint,
  authenticates the user, and logs the user into the subdomain context.
  """
  def callback(conn, %{"provider" => provider} = params) do
    config = get_provider_config!(provider)
    redirect_uri = unverified_url(conn, "/auth/#{provider}/callback", host: conn.host)

    session_params = get_session(conn, :oauth_session_params) || %{}

    config =
      config
      |> Keyword.put(:redirect_uri, redirect_uri)
      |> Keyword.put(:session_params, session_params)

    strategy = config[:strategy]

    # Handle Assent callback with exception protection
    try do
      case strategy.callback(config, params) do
        {:ok, %{user: user_profile}} ->
          raw_uid = user_profile["sub"] || user_profile["id"]
          uid = if raw_uid, do: to_string(raw_uid), else: nil
          email = user_profile["email"]

          case login_or_create_oauth_user(conn, provider, uid, email) do
            {:ok, user} ->
              conn
              |> delete_session(:oauth_session_params)
              |> put_flash(:info, "Successfully authenticated with #{String.capitalize(provider)}.")
              |> UserAuth.log_in_user(user)

            {:error, reason} ->
              conn
              |> delete_session(:oauth_session_params)
              |> put_flash(:error, "OAuth authentication failed: #{reason}")
              |> redirect(to: ~p"/users/log-in")
          end

        {:error, reason} ->
          conn
          |> delete_session(:oauth_session_params)
          |> put_flash(:error, "Failed to authenticate with provider: #{inspect(reason)}")
          |> redirect(to: ~p"/users/log-in")
      end
    rescue
      e ->
        conn
        |> delete_session(:oauth_session_params)
        |> put_flash(:error, "An error occurred during authentication: #{Exception.message(e)}")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  # Helper to resolve user matching or registration for OAuth identities
  defp login_or_create_oauth_user(_conn, provider, uid, email) do
    # Verify that email and uid are valid strings
    if is_nil(email) or email == "" or is_nil(uid) or uid == "" do
      {:error, "Provider did not return a valid email address or user ID. Please check your provider account settings."}
    else
      identity_query =
        from(ui in UserIdentity,
          where: ui.provider == ^provider and ui.uid == ^uid,
          preload: [:user]
        )

      case Repo.one(identity_query) do
        %UserIdentity{user: user} when not is_nil(user) ->
          {:ok, user}

        _ ->
          case Accounts.get_user_by_email(email) do
            %User{} = existing_user ->
              # Link existing user account with the OAuth identity safely
              changeset =
                UserIdentity.changeset(%UserIdentity{}, %{
                  provider: provider,
                  uid: uid,
                  user_id: existing_user.id
                })

              case Repo.insert(changeset) do
                {:ok, _} -> {:ok, existing_user}
                {:error, _changeset} -> {:error, "Could not link OAuth identity to existing account."}
              end

            nil ->
              # Safely create new user and identity without raising exceptions
              result =
                Repo.transaction(fn ->
                  user_params = %{
                    email: email,
                    confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
                  }

                  user_changeset =
                    %User{}
                    |> Ecto.Changeset.change(user_params)
                    |> Ecto.Changeset.validate_required([:email])

                  with {:ok, user} <- Repo.insert(user_changeset),
                       identity_changeset <- UserIdentity.changeset(%UserIdentity{}, %{provider: provider, uid: uid, user_id: user.id}),
                       {:ok, _identity} <- Repo.insert(identity_changeset) do
                    user
                  else
                    {:error, changeset} -> Repo.rollback(changeset)
                  end
                end)

              case result do
                {:ok, user} -> {:ok, user}
                {:error, _reason} -> {:error, "Failed to create account from OAuth."}
              end
          end
      end
    end
  end
end
