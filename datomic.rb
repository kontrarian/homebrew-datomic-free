class Datomic < Formula
  desc "A transactional database with a flexible data model, elastic scaling, and rich queries."
  homepage "https://www.datomic.com/"
  url "https://my.datomic.com/downloads/free/0.9.5544"
  version "0.9.5544"
  sha256 "ee866227d40048e7055f350c6958d62b85d6685e059e79b92b8695f45689b964"

  bottle :unneeded

  depends_on :openjdk

  def install
    inreplace "config/samples/free-transactor-template.properties" do |s|
      s.gsub! "# data-dir=data", "data-dir=#{var}/lib/datomic/"
      s.gsub! "# log-dir=log", "log-dir=#{var}/lib/datomic/log"
    end

    # install free-transactor properties
    (etc/"datomic").install "config/samples/free-transactor-template.properties" => "free-transactor.properties"

    libexec.install Dir["*"]
    (bin/"datomic").write_env_script libexec/"bin/datomic", Language::Java.java_home_env

    %w[transactor repl repl-jline rest shell groovysh maven-install].each do |file|
      (bin/"datomic-#{file}").write_env_script libexec/"bin/#{file}", Language::Java.java_home_env
    end

    # create directory for datomic data and logs
    (var/"lib/datomic").mkpath
  end

  def post_install
    # create directory for datomic stdout+stderr output logs
    (var/"log/datomic").mkpath
  end

  def caveats
    <<~EOS
      All commands have been installed with the prefix "datomic-".
      We agreed to the Datomic Free Edition License for you:
        https://my.datomic.com/downloads/free
      If this is unacceptable you should uninstall.
    EOS
  end

  plist_options :manual => "transactor #{HOMEBREW_PREFIX}/etc/datomic/free-transactor.properties"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
        <key>ProgramArguments</key>
        <array>
            <string>#{opt_bin}/datomic-transactor</string>
            <string>#{etc}/datomic/free-transactor.properties</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>#{var}/log/datomic/error.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/datomic/output.log</string>
    </dict>
    </plist>
  EOS
  end

  test do
    IO.popen("#{bin}/datomic-repl", "r+") do |pipe|
      assert_equal "Clojure 1.9.0", pipe.gets.chomp
      pipe.puts "^C"
      pipe.close_write
      pipe.close
    end
  end
end