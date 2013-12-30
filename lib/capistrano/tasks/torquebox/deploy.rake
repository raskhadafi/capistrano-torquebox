def create_deployment_descriptor( root )
  dd = {
    'application' => {
      # Force the encoding to UTF-8 on 1.9 since the value may be ASCII-8BIT, which marshals as an encoded bytestream, not a String.
      'root' => "#{root.respond_to?(:force_encoding) ? root.force_encoding('UTF-8') : root}",
    },
  }

  if fetch(:app_host)
    dd['web'] ||= {}
    dd['web']['host'] = fetch(:app_host)
  end

  if  fetch(:app_context)
    dd['web'] ||= {}
    dd['web']['context'] = fetch(:app_context)
  end

  if  fetch(:app_ruby_version)
    dd['ruby'] ||= {}
    dd['ruby']['version'] = fetch(:app_ruby_version)
  end

  if  fetch(:app_environment)
    dd['environment'] = fetch(:app_environment)
  end

  if  fetch(:rails_env)
    dd['environment'] ||= {}
    dd['environment']['RAILS_ENV'] = fetch(:rails_env)
  end

  if fetch(:stomp_host)
    dd['stomp'] ||= {}
    dd['stomp']['host'] = fetch(:stomp_host)
  end

  dd
end

namespace :deploy do
  desc "Restart Application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "touch #{fetch(:jboss_home)}/standalone/deployments/#{fetch(:torquebox_app_name, fetch(:application))}-knob.yml.dodeploy"
    end
  end

  namespace :torquebox do
    desc "Start TorqueBox Server"
    task :start do
      on roles(:app), in: :sequence, wait: 5 do
        puts "Starting TorqueBox AS"

        case fetch(:jboss_control_style)
          when :initd
            execute "#{sudo} #{fetch(:jboss_init_script)} start"
          when :binscripts
            execute "nohup #{fetch(:jboss_home)}/bin/standalone.sh -b #{fetch(:jboss_bind_address)} < /dev/null > /dev/null 2>&1 &"
          when :runit
            execute "#{sudo} sv start torquebox"
          when :upstart
            execute "#{sudo} service torquebox start"
        end
      end
    end

    desc "Stop TorqueBox Server"
    task :stop do
      on roles(:app), in: :sequence, wait: 5 do
        puts "Stopping TorqueBox AS"

        case fetch(:jboss_control_style)
          when :initd
            execute "#{sudo} JBOSS_HOME=#{fetch(:jboss_home)} #{jboss_init_script} stop"
          when :binscripts
            execute "#{fetch(:jboss_home)}/bin/jboss-cli.sh --connect :shutdown"
          when :runit
            execute "#{sudo} sv stop torquebox"
          when :upstart
            execute "#{sudo} service torquebox stop"
        end
      end
    end

    desc "Restart TorqueBox Server"
    task :restart do
      on roles(:app), in: :sequence, wait: 5 do
        case ( fetch(:jboss_control_style) )
          when :initd
            puts    "Restarting TorqueBox AS"
            execute "#{sudo} JBOSS_HOME=#{fetch(:jboss_home)} #{fetch(:jboss_init_script)} restart"
          when :binscripts
            execute "#{fetch(:jboss_home)}/bin/jboss-cli.sh --connect :shutdown"
            execute "nohup #{fetch(:jboss_home)}/bin/standalone.sh -bpublic=#{fetch(:jboss_bind_address)} < /dev/null > /dev/null 2>&1 &"
          when :runit
            puts    "Restarting TorqueBox AS"
            execute "#{sudo} sv restart torquebox"
          when :upstart
            puts    "Restarting TorqueBox AS"
            execute "#{sudo} service torquebox restart"
        end
      end
    end

    task :info do
      on roles(:app), in: :sequence, wait: 5 do
        puts "torquebox_home.....#{fetch(:torquebox_home)}"
        puts "jboss_home.........#{fetch(:jboss_home)}"
        puts "jruby_home.........#{fetch(:jruby_home)}"
        puts "bundle command.....#{fetch(:bundle_cmd)}"
      end
    end

    task :check do
      puts "style #{fetch(:jboss_control_style)}"

      on roles(:app), in: :sequence, wait: 5 do
        case fetch(:jboss_control_style)
        when :initd
          execute "test -x #{fetch(:jboss_init_script)}"
        when :runit
          execute "test -x #{fetch(:jboss_runit_script)}"
        when :upstart
          execute "test -x #{fetch(:jboss_upstart_script)}"
        end

        execute "test -d #{fetch(:jboss_home)}"

        unless %w[initd binscripts runit upstart].include?(fetch(:jboss_control_style))
          error "invalid fetch(:jboss_control_style): #{fetch(:jboss_control_style)}"
        end
      end
    end

    task :deployment_descriptor do
      puts "creating deployment descriptor"

      dd_str  = YAML.dump_stream( create_deployment_descriptor(current_path) )
      dd_file = "#{fetch(:jboss_home)}/standalone/deployments/#{fetch(:torquebox_app_name, fetch(:application))}-knob.yml"
      cmd     =  "cat /dev/null > #{dd_file}"

      dd_str.each_line do |line|
        cmd += " && echo \"#{line}\" >> #{dd_file}"
      end

      cmd += " && echo '' >> #{dd_file}"

      on roles(:app), in: :sequence, wait: 5 do
        execute cmd
      end
    end

    task :rollback_deployment_descriptor do
      puts "rolling back deployment descriptor"

      dd_str  = YAML.dump_stream(create_deployment_descriptor(previous_release))
      dd_file = "#{fetch(:jboss_home)}/standalone/deployments/#{fetch(:application)}-knob.yml"
      cmd     =  "cat /dev/null > #{dd_file}"

      dd_str.each_line do |line|
        cmd += " && echo \"#{line}\" >> #{dd_file}"
      end

      cmd += " && echo '' >> #{dd_file}"

      on roles(:app), in: :sequence, wait: 5 do
        execute cmd
      end
    end

    desc "Dump the deployment descriptor"
    task :dump do
      on roles(:app), in: :sequence, wait: 5 do
        dd = create_deployment_descriptor(current_path)
        puts dd
        exit
        puts YAML.dump(create_deployment_descriptor(current_path ))
      end
    end
  end
end

before 'deploy:check',             'deploy:torquebox:check'
after  'deploy:symlink:shared',    'deploy:torquebox:deployment_descriptor'
after  'deploy:rollback',          'deploy:torquebox:rollback_deployment_descriptor'

__END__

module Capistrano
  class Configuration

  end

  module TorqueBox

    def self.load_into( configuration )

      configuration.load do
        # --


        namespace :deploy do

          namespace :torquebox do


        end


      end
    end
  end
end