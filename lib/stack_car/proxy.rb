require 'thor'

module StackCar
  class Proxy < Thor
    include Thor::Actions

    desc 'up', 'Launch traefik proxy for local development, assumes localhost.direct is the domain'
    def up
      #find the socket
      set_proxy_env
      run("docker compose -f proxy/compose.yaml up -d")
    end

    desc 'down', 'Stop traefik proxy for local development'
    def down
      set_proxy_env
      run("docker compose -f proxy/compose.yaml down")
    end

    desc 'cert', 'Add a self-signed certificate for localhost.direct to the system'
    def cert
      run("pushd proxy && wget https://aka.re/localhost-ss && popd")
      say("\n\n\nEnter the password found https://github.com/Upinel/localhost.direct?tab=readme-ov-file#a-non-public-ca-certificate-if-you-have-admin-right-on-your-development-environment-you-can-use-the-following-10-years-long-pre-generated-self-signed-certificate\n\n\n")
      system("unzip -d proxy proxy/localhost-ss")
      if Os.macos?
        run("sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain proxy/localhost.direct.SS.crt")
      elsif Os.ubuntu?
        run("sudo cp proxy/localhost.direct.SS.crt /usr/local/share/ca-certificates/localhost.direct.SS.crt")
        run("sudo update-ca-certificates")
      else
        say("\n\n\nPlease figure out how to add a certificate to your system, then open a PR for your OS/Distro")
        say("Files are located #{ENV['PWD']}/proxy/localhost.direct.SS.crt and #{ENV['PWD']}/proxy/localhost.direct.SS.key\n\n\n")
        exit(1)
      end
    end

    protected
    def set_proxy_env
      ENV['DOCKER_SOCKET'] ||= "/var/run/docker.sock"
    end
  end
end
