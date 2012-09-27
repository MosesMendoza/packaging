namespace :pl do
  desc "Ship mocked rpms to #{@yum_host}"
  task :ship_rpms do
    rsync_to('pkg/el', @yum_host, @yum_repo_path)
    rsync_to('pkg/fedora', @yum_host, @yum_repo_path)
  end

  desc "Update remote rpm repodata on #{@yum_host}"
  task :update_yum_repo do
    remote_ssh_cmd(@yum_host, '/var/lib/gems/1.8/gems/rake-0.9.2.2/bin/rake -f /opt/repository/Rakefile mk_repo')
  end

  desc "Ship cow-built debs to #{@apt_host}"
  task :ship_debs do
    rsync_to('pkg/deb/', @apt_host, @apt_repo_path)
  end

  desc "freight RCs to devel repos on #{@apt_host}"
  task :remote_freight_devel do
    remote_ssh_cmd(@apt_host, '/var/lib/gems/1.8/gems/rake-0.9.2.2/bin/rake -f /opt/repository/Rakefile devel')
  end

  desc "remote freight final packages to PRODUCTION repos on #{@apt_host}"
  task :remote_freight_final do
    remote_ssh_cmd(@apt_host, '/var/lib/gems/1.8/gems/rake-0.9.2.2/bin/rake -f /opt/repository/Rakefile community')
  end

  if @build_ips
    desc "Update remote ips repository on #{@ips_host}"
    task :update_ips_repo do
      rsync_to('pkg/ips/pkgs', @ips_host, @ips_store)
      remote_ssh_cmd(@ips_host, "pkgrecv -s #{@ips_store}/pkgs/#{@name}@#{@ipsversion}.p5p -d #{@ips_repo} \\*")
      remote_ssh_cmd(@ips_host, "pkgrepo refresh -s #{@ips_repo}")
      remote_ssh_cmd(@ips_host, "/usr/sbin/svcadm restart svc:/application/pkg/server")
    end
  end

  if @build_gem
    desc "Ship built gem to rubygems"
    task :ship_gem do
      ship_gem("pkg/#{@name}-#{@gemversion}.gem")
    end
  end

  if File.exist?("#{ENV['HOME']}/.packaging/#{@builder_data_file}")
    desc "ship apple dmg to package host"
    task :ship_dmg => :fetch do
      rsync_to('pkg/apple/*.dmg', @yum_host, @dmg_path)
    end if @build_dmg

    desc "ship tarball and signature to package host"
    task :ship_tar => :fetch do
      rsync_to("pkg/#{@name}-#{@version}.tar.gz*", @yum_host, @tarball_path)
    end

    desc "UBER ship: ship all the things in pkg"
    task :uber_ship => :fetch do
      if confirm_ship(FileList["pkg/**/*"])
        ENV['ANSWER_OVERRIDE'] = 'yes'
        Rake::Task["pl:ship_gem"].invoke if @build_gem
        Rake::Task["pl:ship_rpms"].invoke
        Rake::Task["pl:ship_debs"].invoke
        Rake::Task["pl:ship_dmg"].execute if @build_dmg
        Rake::Task["pl:ship_tar"].execute
      end
    end
  end
end


