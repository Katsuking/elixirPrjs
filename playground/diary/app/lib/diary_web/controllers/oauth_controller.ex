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
  """
  def request(conn, %{"provider" => provider}) do
    config = get_provider_config!(provider)
    redirect_uri = url(conn, ~p"/auth/#{provider}/callback")

    config = Keyword.put(config, :redirect_uri, redirect_uri)

    # Generate Authorization URL via Assent Strategy
    strategy = config[:strategy]
    case strategy.authorize_url(config) do
      {:ok, %{url: url, session_params: session_params}} ->
        # Store state/session parameters in session to verify during callback
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
  Handles the callback from the OAuth provider.
  """
  def callback(conn, %{"provider" => provider} = params) do
    config = get_provider_config!(provider)
    redirect_uri = url(conn, ~p"/auth/#{provider}/callback")

    session_params = get_session(conn, :oauth_session_params) || %{}

    config = 
      config
      |> Keyword.put(:redirect_uri, redirect_uri)
      |> Keyword.put(:session_params, session_params)

    # Verify callback code and fetch user profile via Assent
    strategy = config[:strategy]
    case strategy.callback(config, params) do
      {:ok, %{user: user_profile}} ->
        # user_profile contains uid, email, etc.
        uid = to_string(user_profile["sub"] || user_profile["id"])
        email = user_profile["email"]

        case login_or_create_oauth_user(conn, provider, uid, email) do
          {:ok, user} ->
            conn
            |> delete_session(:oauth_session_params)
            |> put_flash(:info, "Successfully authenticated with #{String.capitalize(provider)}.")
            |> UserAuth.log_in_user(user)

          {:error, reason} ->
            conn
            |> put_flash(:error, "OAuth authentication failed: #{reason}")
            |> redirect(to: ~p"/users/log-in")
        end

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to authenticate with provider: #{inspect(reason)}")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  # Helper to resolve user matching or registration for OAuth identities
  defp login_or_create_oauth_user(_conn, provider, uid, email) do
    # 1. Check if identity already exists
    identity_query = 
      from(ui in UserIdentity, 
        where: ui.provider == ^provider and ui.uid == ^uid,
        preload: [:user]
      )

    case Repo.one(identity_query) do
      %UserIdentity{user: user} ->
        {:ok, user}

      nil ->
        # 2. Check if a user with the same email exists
        case Accounts.get_user_by_email(email) do
          %User{} = existing_user ->
            # Link existing account with new identity
            changeset = UserIdentity.changeset(%UserIdentity{}, %{
              provider: provider,
              uid: uid,
              user_id: existing_user.id
            })

            case Repo.insert(changeset) do
              {:ok, _} -> {:ok, existing_user}
              {:error, _} -> {:error, "Could not link account"}
            end

          nil ->
            # 3. Create a new user with confirmed status and no password
            Repo.transaction(fn ->
              user_params = %{
                email: email,
                confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
              }

              user = 
                %User{}
                |> Ecto.Changeset.change(user_params)
                |> Repo.insert!()

              # Create associated UserIdentity
              %UserIdentity{}
              |> UserIdentity.changeset(%{
                provider: provider,
                uid: uid,
                user_id: user.id
              })
              |> Repo.insert!()

              user
            end)
        end
    end
  end
end
