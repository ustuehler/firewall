class Chef
  class Resource::Firewall < Chef::Resource::LWRPBase
    if Chef::Provider.respond_to?(:provides)
      resource_name(:firewall)
      provides(:firewall)
    else
      # Chef 11 compatibility
      self.resource_name = :firewall
    end

    actions(:install, :restart, :disable, :flush, :save)
    default_action(:install)

    attribute(:disabled, kind_of: [TrueClass, FalseClass], default: false)
    attribute(:log_level, kind_of: Symbol, equal_to: [:low, :medium, :high, :full], default: :low)
    attribute(:rules, kind_of: Hash)

    # for firewalld, specify the zone when firewall is disable and enabled
    attribute(:disabled_zone, kind_of: Symbol, default: :public)
    attribute(:enabled_zone, kind_of: Symbol, default: :drop)

    # for firewall implementations where ipv6 can be skipped (currently iptables-specific)
    attribute(:ipv6_enabled, kind_of: [TrueClass, FalseClass], default: true)
  end
end
