namespace :load do
  task :defaults do
    set :torquebox_home, '/opt/torquebox'
    set :jruby_home, -> { "#{fetch(:torquebox_home)}/jruby" }
    set :jruby_opts, -> { "--#{fetch(:app_ruby_version)}" if fetch(:app_ruby_version) }
    set :jruby_bin, -> { "#{fetch(:jruby_home)}/bin/jruby #{fetch(:jruby_opts)}" }
    set :jboss_home, -> { "#{fetch(:torquebox_home)}/jboss" }
    set :jboss_control_style, 'initd'
    set :jboss_init_script, '/etc/init.d/jboss-as-standalone'
    set :jboss_runit_script, '/etc/service/torquebox/run'
    set :jboss_upstart_script, '/etc/init/torquebox.conf'
    set :jboss_bind_address, '0.0.0.0'
    set :bundle_cmd, -> { "#{fetch(:jruby_bin)} -S bundle" }
    set :bundle_flags, ''
  end
end
