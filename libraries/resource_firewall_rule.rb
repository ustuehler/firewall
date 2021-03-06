require 'ipaddr'

class Chef
  class Resource::FirewallRule < Chef::Resource::LWRPBase
    include FirewallCookbook::Helpers

    if Chef::Provider.respond_to?(:provides)
      resource_name(:firewall_rule)
      provides(:firewall_rule)
    else
      # Chef 11 compatibility
      resource_name = :firewall_rule
    end

    actions(:create)
    default_action(:create)

    attribute(:firewall_name, kind_of: String, default: 'default')

    attribute(:command, kind_of: Symbol, equal_to: [:reject, :allow, :deny, :masquerade, :redirect, :log], default: :allow)

    attribute(:protocol, kind_of: [Integer, Symbol], default: :tcp,
                         callbacks: { 'must be either :tcp, :udp, :icmp, :\'ipv6-icmp\', :icmpv6, :none, or a valid IP protocol number' => lambda do |p|
                           !!(p.to_s =~ /(udp|tcp|icmp|icmpv6|ipv6-icmp|none)/ || (p.to_s =~ /^\d+$/ && p.between?(0, 142)))
                         end
      }
             )
    attribute(:direction, kind_of: Symbol, equal_to: [:in, :out, :pre, :post], default: :in)
    attribute(:logging, kind_of: Symbol, equal_to: [:connections, :packets])

    attribute(:source, callbacks: { 'must be a valid ip address' => ->(ip) { !!IPAddr.new(ip) } })
    attribute(:source_port, kind_of: [Integer, Array, Range]) # source port
    attribute(:interface, kind_of: String)

    attribute(:port, kind_of: [Integer, Array, Range]) # shorthand for dest_port
    attribute(:destination, callbacks: { 'must be a valid ip address' => ->(ip) { !!IPAddr.new(ip) } })
    attribute(:dest_port, kind_of: [Integer, Array, Range])
    attribute(:dest_interface, kind_of: String)

    attribute(:position, kind_of: Integer, default: 50)
    attribute(:stateful, kind_of: [Symbol, Array])
    attribute(:redirect_port, kind_of: Integer)
    attribute(:description, kind_of: String, name_attribute: true)

    # only used for Windows Firewalls
    attribute(:program, kind_of: String)
    attribute(:service, kind_of: String)

    # for when you just want to pass a raw rule
    attribute(:raw, kind_of: String)
  end
end
