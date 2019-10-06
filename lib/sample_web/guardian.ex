defmodule SampleWeb.Guardian do
  use Guardian, otp_app: :sample

  alias Sample.Accounts

  def subject_for_token(resource, _claims) do
    {:ok, resource.username}
  end

  def resource_from_claims(%{"sub" => username}) do
    case Accounts.get_user_by(username: username) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end
end
