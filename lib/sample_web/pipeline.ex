defmodule SampleWeb.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :hello,
    error_handler: SampleWeb.ErrorHandler,
    module: SampleWeb.Guardian

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource, allow_blank: true
end
