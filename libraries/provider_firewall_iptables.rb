#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: firewall
# Resource:: default
#
# Copyright:: 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class Chef
  class Provider::FirewallIptables < Chef::Provider::LWRPBase
    include FirewallCookbook::Helpers
    include FirewallCookbook::Helpers::Iptables

    if Chef::Provider.respond_to?(:provides)
      provides :firewall, os: 'linux', platform_family: %w(rhel fedora) do |node|
        node['platform_version'].to_f < 7.0 || node['firewall']['redhat7_iptables']
      end
    end

    def whyrun_supported?
      false
    end

    action :install do
      next if disabled?(new_resource)

      converge_by('install iptables and enable/start services') do
        # can't pass an array without breaking chef 11 support
        iptables_packages(new_resource).each do |p|
          package p do
            action :install
          end
        end

        iptables_commands(new_resource).each do |svc|
          # must create empty file for service to start
          file "create empty /etc/sysconfig/#{svc}" do
            path "/etc/sysconfig/#{svc}"
            content '# created by chef to allow service to start'
            not_if { ::File.exist?("/etc/sysconfig/#{svc}") }
          end

          service svc do
            action [:enable, :start]
          end
        end
      end
    end

    action :restart do
      next if disabled?(new_resource)

      # prints all the firewall rules
      log_iptables(new_resource)

      # ensure it's initialized
      new_resource.rules({}) unless new_resource.rules
      ensure_default_rules_exist(node, new_resource)

      iptables_commands(new_resource).each do |iptables_type|
        iptables_filename = "/etc/sysconfig/#{iptables_type}"
        # ensure a file resource exists with the current iptables rules
        begin
          iptables_file = run_context.resource_collection.find(file: iptables_filename)
        rescue
          iptables_file = file iptables_filename do
            action :nothing
          end
        end
        iptables_file.content build_rule_file(new_resource.rules[iptables_type])
        iptables_file.run_action(:create)

        # if the file was unchanged, skip loop iteration, otherwise restart iptables
        next unless iptables_file.updated_by_last_action?

        service_affected = service iptables_type do
          action :nothing
        end

        new_resource.notifies(:restart, service_affected, :delayed)
        new_resource.updated_by_last_action(true)
      end
    end

    action :disable do
      next if disabled?(new_resource)

      iptables_flush!(new_resource)
      iptables_default_allow!(new_resource)
      new_resource.updated_by_last_action(true)

      iptables_commands(new_resource).each do |svc|
        service svc do
          action [:disable, :stop]
        end

        # must create empty file for service to start
        file "create empty /etc/sysconfig/#{svc}" do
          path "/etc/sysconfig/#{svc}"
          content '# created by chef to allow service to start'
        end
      end
    end

    action :flush do
      next if disabled?(new_resource)

      iptables_flush!(new_resource)
      new_resource.updated_by_last_action(true)

      iptables_commands(new_resource).each do |svc|
        # must create empty file for service to start
        file "create empty /etc/sysconfig/#{svc}" do
          path "/etc/sysconfig/#{svc}"
          content '# created by chef to allow service to start'
        end
      end
    end
  end
end
