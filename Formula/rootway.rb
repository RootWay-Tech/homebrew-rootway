class Rootway < Formula
  desc "Rootway Agent - monitoring serwera"
  homepage "https://github.com/RootWay-Tech/homebrew-rootway"
  url "https://github.com/RootWay-Tech/homebrew-rootway/releases/download/v1.0.0/rootway-agent.zip"
  sha256 "54AAC8C59ED47E704AD40E5A65C4DED77AEA533FB5E13776B9C78CA5C22B3CC7"
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
  pip_install_log = var/"log/rootway_pip_install.log"
  wireguard_log = var/"log/rootway_wireguard_setup.log"
  python_bin = Formula["python@3.12"].opt_libexec/"bin/python3"

  # Tworzymy katalogi jeśli ich brak
  (var/"rootway").mkpath
  (var/"log").mkpath

  # Sprawdź, czy venv już istnieje
  unless venv_dir.exist?
    ohai "Tworzenie środowiska virtualenv w #{venv_dir}..."
    system python_bin, "-m", "venv", venv_dir
  else
    ohai "Środowisko virtualenv już istnieje w #{venv_dir} - pomijam tworzenie."
  end

  # Instalacja zależności Pythona z logowaniem
  ohai "Instalacja zależności Pythona z requirements.txt..."
  pip_bin = venv_dir/"bin/pip"
  if !system "#{pip_bin}", "install", "--log", pip_install_log, "-r", opt_prefix/"requirements.txt"
    opoo "Instalacja zależności Pythona zakończona błędem. Sprawdź log: #{pip_install_log}"
  end

  # Automatyczna konfiguracja WireGuard z logowaniem
  ohai "Konfiguracja WireGuard..."
  if !system "sudo", python_bin, opt_prefix/"wireguard_setup.py", ">", wireguard_log, "2>&1"
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