# frozen_string_literal: true

# Pulls the latest docker image on all the 3 web heads
on ['serv-deployer@oh-web01.dc1.lan', 'serv-deployer@oh-web02.dc1.lan', 'serv-deployer@oh-web03.dc1.lan'] do
  within '/home/serv-deployer' do
    execute('wget -O docker-compose.yml https://raw.githubusercontent.com/blackducksoftware/ohloh-ui/master/docker-compose.yml')
    execute('docker pull sigsynopsys/openhub:latest')
  end
end

# Run the bundle install, assets on one of the web host
on ['serv-deployer@oh-web01.dc1.lan'] do
  within '/home/serv-deployer' do
    execute('docker-compose run --rm web bundle install')
    execute('docker-compose run --rm web rake assets:precompile RAILS_ENV=staging')
  end
end

# Rebuild the container with the latest changes (code, assets)
on ['serv-deployer@oh-web01.dc1.lan', 'serv-deployer@oh-web02.dc1.lan', 'serv-deployer@oh-web03.dc1.lan'] do
  within '/home/serv-deployer' do
    execute('docker-compose up -d --build')
  end
end
