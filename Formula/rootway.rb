class Rootway < Formula
  desc "Rootway Agent - monitoring serwera"
  homepage "https://github.com/kamilheree/homebrew-rootway"
  url "https://github.com/kamilheree/homebrew-rootway/releases/download/v1.0.0/rootway-agent.zip"
  sha256 "99FDCA102E784E25F8B5653E9E9AC8FCC232663DE3BC7937227785B4987C6728"
  license "MIT"
  version "1.0.0"

  depends_on "python@3.12"
  depends_on "wireguard-tools"

  def install
    # Instalacja wszystkich plików
    prefix.install Dir["*"]

    # Utworzenie wymaganych katalogów
    (var/"log").mkpath
    (var/"rootway").mkpath
    (prefix/"templates").mkpath
  end

  def post_install
    venv_dir = var/"rootway/venv"

    # Tworzenie środowiska virtualenv
    system Formula["python@3.12"].opt_bin/"python3", "-m", "venv", venv_dir

    # Instalacja zależności Pythona z logowaniem
    pip_install_log = var/"log/rootway_pip_install.log"
    system "#{venv_dir}/bin/pip", "install", "--log", pip_install_log, "-r", opt_prefix/"requirements.txt"

    # Automatyczna konfiguracja WireGuard z logowaniem
    wireguard_log = var/"log/rootway_wireguard_setup.log"
    system "sudo", "python3", opt_prefix/"wireguard_setup.py", ">", wireguard_log, "2>&1"
  end

  service do
    run [var/"rootway/venv/bin/python3", opt_prefix/"main.py"]
    keep_alive true
    working_dir opt_prefix
    log_path var/"log/rootway.log"
    error_log_path var/"log/rootway_error.log"
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      Panel logowania dostępny pod:
        http://localhost:8080

      Konfiguracja WireGuard:
        #{etc}/wireguard/wg0.conf

      Aby uruchomić tunel WireGuard:
        sudo wg-quick up wg0

      Logi instalacji i działania znajdziesz w katalogu:
        /usr/local/var/log/
    EOS
  end
end