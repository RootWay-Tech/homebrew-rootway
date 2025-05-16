class Rootway < Formula
  include Language::Python::Virtualenv

  desc "Rootway Agent - monitoring serwera"
  homepage "https://github.com/RootWay-Tech/homebrew-rootway"
  url "https://github.com/RootWay-Tech/homebrew-rootway/releases/download/v1.0.0/rootway-agent.zip"
  sha256 "9b690dcff2582615da2209d9cedc3a3c7fce14d28c0c1276d37a718dedd3a732"
  license "MIT"
  version "1.0.0"

  depends_on "python@3.12"
  depends_on "wireguard-tools"

  resource "flask" do
    url "https://files.pythonhosted.org/packages/32/01/e6946ddcf7c19ad227f4f4b9a60c6f79b6bfcf6494f47d08005cb1ad02cd/Flask-3.0.2.tar.gz"
    sha256 "7cd0b2d324a89469e2dcb9f7c9e30dbdc66cd8dbcf8651683aa5b4a2581a4c47"
  end

  def install
    # Instalacja wszystkich plików z paczki ZIP
    prefix.install Dir["*"]

    # Utworzenie wymaganych katalogów
    (var/"log").mkpath
    (var/"rootway").mkpath
    (prefix/"templates").mkpath
  end

  def post_install
    venv_dir = var/"rootway/venv"
    pip_install_log = var/"log/rootway_pip_install.log"
    wireguard_log = var/"log/rootway_wireguard_setup.log"
    python_bin = Formula["python@3.12"].opt_libexec/"bin/python3"

    # Tworzenie środowiska virtualenv jeśli nie istnieje
    unless venv_dir.exist?
      ohai "Tworzenie środowiska virtualenv w #{venv_dir}..."
      system python_bin, "-m", "venv", venv_dir
    else
      ohai "Środowisko virtualenv już istnieje w #{venv_dir} - pomijam tworzenie."
    end

    # Instalacja Flask do virtualenv
    pip_bin = venv_dir/"bin/pip"
    resource("flask").stage do
      system pip_bin, "install", "--no-deps", "."
    end

    # Instalacja lokalnych zależności z requirements.txt (jeśli istnieje)
    if (opt_prefix/"requirements.txt").exist?
      ohai "Instalacja zależności z requirements.txt..."
      unless system pip_bin, "install", "--log", pip_install_log, "-r", opt_prefix/"requirements.txt"
        opoo "Instalacja zależności zakończona błędem. Sprawdź log: #{pip_install_log}"
      end
    end

    # Konfiguracja WireGuard
    ohai "Konfiguracja WireGuard..."
    unless system "sudo", python_bin, opt_prefix/"wireguard_setup.py", ">", wireguard_log, "2>&1"
      opoo "Konfiguracja WireGuard zakończona błędem. Sprawdź log: #{wireguard_log}"
    end
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
