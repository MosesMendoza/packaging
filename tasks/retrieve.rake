##
# This task is intended to retrieve packages from the distribution server that
# have been built by jenkins and placed in a specific location,
# /opt/jenkins-builds/$PROJECT/$SHA where $PROJECT is the build project as
# established in project_data.yaml and $SHA is the git sha/tag of the project that
# was built into packages. The current day is assumed, but an environment
# variable override exists to retrieve packages from another day. The sha/tag is
# assumed to be the current project's HEAD, e.g.  to retrieve packages for a
# release of 3.1.0, checkout 3.1.0 locally before retrieving.
#

namespace :pl do
  namespace :jenkins do
    desc "Retrieve packages from the distribution server\. Check out commit to retrieve"
    task :retrieve, :remote_target, :local_target do |t, args|
      remote_target = args.remote_target || "artifacts"
      local_target = args.local_target || "pkg"
      invoke_task("pl:fetch")
      mkdir_p local_target
      package_url = "http://#{Pkg::Config.builds_server}/#{Pkg::Config.project}/#{Pkg::Config.ref}/#{remote_target}"
      if wget = Pkg::Util::Tool.find_tool("wget")
        sh "#{wget} -r -np -nH --cut-dirs 3 -P #{local_target} --reject 'index*' #{package_url}/"
      else
        warn "Could not find `wget` tool. Falling back to rsyncing from #{Pkg::Config.distribution_server}"
        begin
          Pkg::Util::Net.rsync_from("#{Pkg::Config.jenkins_repo_path}/#{Pkg::Config.project}/#{Pkg::Config.ref}/#{remote_target}/", Pkg::Config.distribution_server, "#{local_target}/")
        rescue
          fail "Couldn't download packages from distribution server. Try installing wget!"
        end
      end
      puts "Packages staged in pkg"
    end
  end
end

if Pkg::Config.build_pe
  namespace :pe do
    namespace :jenkins do
      desc "Retrieve packages from the distribution server\. Check out commit to retrieve"
      task :retrieve, :target do |t, args|
        target = args.target || "artifacts"
        invoke_task("pl:jenkins:retrieve", target)
      end
    end
  end
end
