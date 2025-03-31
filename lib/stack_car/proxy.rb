require 'thor'
require 'open-uri'
require 'fileutils'
require 'archive/zip'

module StackCar
  class Proxy < Thor
    include Thor::Actions

    desc 'up', 'Launch traefik proxy for local development, assumes localhost.direct is the domain'
    def up
      #find the socket
      set_proxy_env
      run("docker compose -f #{HammerOfTheGods.gem_root}/proxy/compose.yaml up -d")
    end

    desc 'down', 'Stop traefik proxy for local development'
    def down
      set_proxy_env
      run("docker compose -f #{HammerOfTheGods.gem_root}/proxy/compose.yaml down")
    end

    desc 'cert', 'Add a self-signed certificate for localhost.direct to the system'
    def cert
      say("Downloading certificate package...")

      IO.copy_stream(URI.open(download_url), output_file)
      say("Download complete.")
      unzip_file

      if Os.macos?
        run("sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain #{proxy_dir}/localhost.direct.SS.crt")
      elsif Os.ubuntu?
        run("sudo cp #{proxy_dir}/localhost.direct.SS.crt /usr/local/share/ca-certificates/localhost.direct.SS.crt")
        run("sudo update-ca-certificates")
      elsif Os.wsl?
        say("\n\n\nFor WSL, you need to add the certificate to Windows certificate store:\n")
        say("1. Copy the certificate to a Windows-accessible location:\n")
        run("cp #{proxy_dir}/localhost.direct.SS.crt /mnt/c/temp/localhost.direct.SS.crt")
        say("\n2. Now run this Windows command to import the certificate (requires admin rights):\n")
        run("powershell.exe -Command \"Start-Process powershell -Verb RunAs -ArgumentList '-Command Import-Certificate -FilePath C:\\temp\\localhost.direct.SS.crt -CertStoreLocation Cert:\\LocalMachine\\Root'\"")
        say("\n3. Then restart your browser to apply the changes\n\n")
      else
        say("\n\n\nPlease figure out how to add a certificate to your system, then open a PR for your OS/Distro")
        say("Files are located #{ENV['PWD']}/proxy/localhost.direct.SS.crt and #{ENV['PWD']}/proxy/localhost.direct.SS.key\n\n\n")
        exit(1)
      end
    end

    protected

    def unzip_file
      say("\n\n\nEnter the password found https://github.com/Upinel/localhost.direct?tab=readme-ov-file#a-non-public-ca-certificate-if-you-have-admin-right-on-your-development-environment-you-can-use-the-following-10-years-long-pre-generated-self-signed-certificate\n\n\n")
      password = ask('[Required] Enter the unzip password::')
      zip_file = "#{proxy_dir}/localhost-ss"
      Archive::Zip.extract(zip_file, proxy_dir, :password => password)
      say("Successfully unzipped certificate files.")
    rescue Zlib::DataError
      say("Incorrect password. Please try again.")
      exit(1)
    end

    def set_proxy_env
      ENV['DOCKER_SOCKET'] ||= "/var/run/docker.sock"
      unless File.exist?("#{HammerOfTheGods.gem_root}/proxy/localhost.direct.SS.crt")
        say("you must run proxy cert once after installing this gem before using the proxy")
        exit(1)
      end
    end

    def proxy_dir
       @proxy_dir ||= "#{HammerOfTheGods.gem_root}/proxy"
    end

    def download_url
      @download_url ||= "https://aka.re/localhost-ss"
    end

    def output_file
      @output_file ||= File.join(proxy_dir, "localhost-ss")
    end
  end
end
