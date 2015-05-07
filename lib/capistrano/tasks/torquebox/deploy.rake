def create_deployment_descriptor(root_path)
  dd = {
    'application' => {
      'root' => "#{root_path.respond_to?(:force_encoding) ? root_path.force_encoding('UTF-8') : root_path}",
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
    dd['environment']['RACK_ENV'] = fetch(:rails_env).to_s
  end

  if fetch(:stomp_host)
    dd['stomp'] ||= {}
    dd['stomp']['host'] = fetch(:stomp_host)
  end


  filename = fetch(:knob_yml_extensions)
  if filename
    dd_ext = YAML.load_file(filename)
    dd.merge! dd_ext
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
        info "Starting TorqueBox AS"

        case fetch(:jboss_control_style)
        when 'initd'
          execute "#{fetch(:jboss_init_script)} start"
        when 'binscripts'
          execute "nohup #{fetch(:jboss_home)}/bin/standalone.sh -b #{fetch(:jboss_bind_address)} < /dev/null > /dev/null 2>&1 &"
        when 'runit'
          execute "sv start torquebox"
        when 'upstart'
          execute "service torquebox start"
        end
      end
    end

    desc "Stop TorqueBox Server"
    task :stop do
      on roles(:app), in: :sequence, wait: 5 do
        info "Stopping TorqueBox AS"

        case fetch(:jboss_control_style)
          when 'initd'
            execute "JBOSS_HOME=#{fetch(:jboss_home)} #{fetch(:jboss_init_script)} stop"
          when 'binscripts'
            execute "#{fetch(:jboss_home)}/bin/jboss-cli.sh --connect :shutdown"
          when 'runit'
            execute "sv stop torquebox"
          when 'upstart'
            execute "service torquebox stop"
        end
      end
    end

    desc "Restart TorqueBox Server"
    task :restart do
      on roles(:app), in: :sequence, wait: 5 do
        case ( fetch(:jboss_control_style) )
          when 'initd'
            info    "Restarting TorqueBox AS"
            execute "JBOSS_HOME=#{fetch(:jboss_home)} #{fetch(:jboss_init_script)} restart"
          when 'binscripts'
            execute "#{fetch(:jboss_home)}/bin/jboss-cli.sh --connect :shutdown"
            execute "nohup #{fetch(:jboss_home)}/bin/standalone.sh -bpublic=#{fetch(:jboss_bind_address)} < /dev/null > /dev/null 2>&1 &"
          when 'runit'
            info    "Restarting TorqueBox AS"
            execute "sv restart torquebox"
          when 'upstart'
            info    "Restarting TorqueBox AS"
            execute "service torquebox restart"
        end
      end
    end

    task :info do
      on roles(:app), in: :sequence, wait: 5 do
        info "torquebox_home........#{fetch(:torquebox_home)}"
        info "jboss_home............#{fetch(:jboss_home)}"
        info "jboss_init_script.....#{fetch(:jboss_init_script)}"
        info "jruby_home............#{fetch(:jruby_home)}"
        info "bundle command........#{fetch(:bundle_cmd)}"
        info "knob.yml.............."
        puts YAML.dump(create_deployment_descriptor(current_path))
      end
    end

    task :check do
      puts "style #{fetch(:jboss_control_style)}"

      on roles(:app), in: :sequence, wait: 5 do
        case fetch(:jboss_control_style)
        when 'initd'
          execute "test -x #{fetch(:jboss_init_script)}"
        when 'runit'
          execute "test -x #{fetch(:jboss_runit_script)}"
        when 'upstart'
          test "[[ -f #{fetch(:jboss_upstart_script)} ]]"
        end

        execute "test -d #{fetch(:jboss_home)}"

        unless %w[initd binscripts runit upstart].include?(fetch(:jboss_control_style))
          error "invalid fetch(:jboss_control_style): #{fetch(:jboss_control_style)}"
        end
      end
    end

    task :deployment_descriptor do
      puts "creating deployment descriptor"

      dd_str  = YAML.dump_stream(create_deployment_descriptor(release_path))
      dd_file = "#{fetch(:jboss_home)}/standalone/deployments/#{fetch(:torquebox_app_name, fetch(:application))}-knob.yml"

      on roles(:app), in: :sequence, wait: 5 do
        dd_io   = StringIO.new(dd_str)
        upload!(dd_io, dd_file)
      end
    end

    task :rollback_deployment_descriptor do
      puts "rolling back deployment descriptor"

      dd_str  = YAML.dump_stream(create_deployment_descriptor(previous_release))
      dd_file = "#{fetch(:jboss_home)}/standalone/deployments/#{fetch(:application)}-knob.yml"

      on roles(:app), in: :sequence, wait: 5 do
        dd_io   = StringIO.new(dd_str)
        upload!(dd_io, dd_file)
      end
    end

    desc "Dump the deployment descriptor"
    task :dump do
      on roles(:app), in: :sequence, wait: 5 do
        dd = create_deployment_descriptor(current_path)
        puts dd
        exit
        puts YAML.dump(create_deployment_descriptor(current_path))
      end
    end
  end
end

before 'deploy:check',             'deploy:torquebox:check'
after  'deploy:symlink:shared',    'deploy:torquebox:deployment_descriptor'
after  'deploy:rollback',          'deploy:torquebox:rollback_deployment_descriptor'
